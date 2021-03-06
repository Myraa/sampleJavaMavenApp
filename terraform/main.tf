#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#88888888888                                    .d888                                
#    888                                       d88P"                                 
#    888                                       888                                   
#    888      .d88b.  888d888 888d888  8888b.  888888  .d88b.  888d888 88888b.d88b.  
#    888     d8P  Y8b 888P"   888P"       "88b 888    d88""88b 888P"   888 "888 "88b 
#    888     88888888 888     888     .d888888 888    888  888 888     888  888  888 
#    888     Y8b.     888     888     888  888 888    Y88..88P 888     888  888  888 
#    888      "Y8888  888     888     "Y888888 888     "Y88P"  888     888  888  888 
#                                                                                    
#                                                                                   
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                                                         
#===============================================================================
# main.tf template creates the resources to deploy application.
#===============================================================================
# ------------------------------------------------------------------------------
# CUSTOM VARIABLES DEFINITION
# ------------------------------------------------------------------------------

variable "ami_id" {}

#-------------------------------------------------------------------------------
# Specify the provider and region
#-------------------------------------------------------------------------------

provider "aws" {

    region = "${var.region}"
}

#-------------------------------------------------------------------------------
# Create a launch configuration that act as a template to launch EC2 instances with
# autoscalling group.
# you must specify information about the EC2 instances to launch, such as the 
# Amazon Machine Image (AMI), instance type, key pair, security groups.
#-------------------------------------------------------------------------------
 
resource "aws_launch_configuration" "ntt-launch-config-blue" {
  image_id = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  security_groups = ["${aws_security_group.ntt-sg.id}"]
  key_name = "${var.key_name}"
  lifecycle {
    create_before_destroy = true
  }
}

#--------------------------------------------------------------------------------
# create a Autoscaling group, specify launch configuration details
#--------------------------------------------------------------------------------
resource "aws_autoscaling_group" "ntt-autoscale-grp-blue" {
  name = "ntt-autoscale-grp-blue-${aws_launch_configuration.ntt-launch-config-blue.name}"
  health_check_type = "EC2"
  load_balancers = ["${aws_elb.ntt-elb.name}"]
  launch_configuration = "${aws_launch_configuration.ntt-launch-config-blue.name}"
  max_size = 1
  min_size = 1
  vpc_zone_identifier = ["${var.public_subnets_inst}"]
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key = "Name"
    value = "${var.instance_name}"
	propagate_at_launch = true
	}
  tag {
	key = "Environment"
    value = "${var.Environment}"
	propagate_at_launch = true
	}
  tag {
	key = "Owner"
    value = "${var.Owner}"
	propagate_at_launch = true
	}
  tag {
	key = "Project"
    value = "${var.Project}"
    propagate_at_launch = true
    }
}


# ------------------------------------------------------------------------------
# Create a security group that applies to all instances in the ASG
# ------------------------------------------------------------------------------

resource "aws_security_group" "ntt-sg" {
    name = "${var.ntt_instance_sg_name}"
    description = "Mule instance sg"
    vpc_id = "${var.vpc_id}"
    ingress {
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = ["${var.cidr_blocks_inst_sg_in}"]
    }
    ingress {
        from_port = "${var.app_port}"
        to_port = "${var.app_port}"
        protocol = "TCP"
        cidr_blocks = ["${var.cidr_blocks_inst_sg_in}"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# ------------------------------------------------------------------------------
# Create Elastic Load Balancer that is capable of handling rapid changes in network
# traffic patterns. Additionally, deep integration with Auto Scaling ensures
# sufficient application capacity to meet varying levels of application load 
# without requiring manual intervention.
# ------------------------------------------------------------------------------

resource "aws_elb" "ntt-elb" {
  name = "${var.ntt_elb_name}"
  subnets = ["${var.public_subnets_elb}"]
  security_groups = ["${aws_security_group.ntt-elb-sg.id}"]
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = 80
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }
}

# ------------------------------------------------------------------------------
# Create a security group that controls the traffic to the ELB
# ------------------------------------------------------------------------------

resource "aws_security_group" "ntt-elb-sg" {
  name = "${var.ntt_elb_sg_name}"
  vpc_id = "${var.vpc_id}"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 0
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
