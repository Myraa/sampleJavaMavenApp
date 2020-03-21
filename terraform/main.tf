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
resource "aws_autoscaling_group" "ntt-autoscale-identity-grp-blue" {
  name = "ntt-autoscale-identity-grp-blue-${aws_launch_configuration.ntt-launch-config-blue.name}"
  health_check_type = "EC2"
  load_balancers = ["${aws_elb.ntt-elb.name}"]
  launch_configuration = "${aws_launch_configuration.ntt-launch-config-blue.name}"
  max_size = 1
  min_size = 1
  vpc_zone_identifier = ["${var.private_subnets_inst}"]
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

#--------------------------------------------------------------------------------------
# create a Autoscaling policy
#--------------------------------------------------------------------------------------

resource "aws_autoscaling_policy" "agents-identity-blue-scale-cpu-up" {
    name = "agents-identity-blue-scale-cpu-up"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.ntt-autoscale-identity-grp-blue.name}"
}

resource "aws_autoscaling_policy" "agents-identity-blue-scale-cpu-down" {
    name = "agents-identity-blue-scale-cpu-down"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.ntt-autoscale-identity-grp-blue.name}"
}

resource "aws_autoscaling_policy" "agents-identity-blue-scale-mem-up" {
    name = "agents-identity-blue-scale-mem-up"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.ntt-autoscale-identity-grp-blue.name}"
}

resource "aws_autoscaling_policy" "agents-identity-blue-scale-mem-down" {
    name = "agents-identity-blue-scale-mem-down"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.ntt-autoscale-identity-grp-blue.name}"
}




resource "aws_cloudwatch_metric_alarm" "cpu-utilization-high" {
  alarm_name          = "cpu-utilization-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.ntt-autoscale-identity-grp-blue.name}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.agents-identity-blue-scale-cpu-up.arn}"]
}


resource "aws_cloudwatch_metric_alarm" "cpu-utilization-low" {
  alarm_name          = "cpu-utilization-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "40"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.ntt-autoscale-identity-grp-blue.name}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.agents-identity-blue-scale-cpu-down.arn}"]
}


resource "aws_cloudwatch_metric_alarm" "memory-high" {
    alarm_name = "mem-util-high-agents"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "System/Linux"
    period = "300"
    statistic = "Average"
    threshold = "80"
    alarm_description = "This metric monitors ec2 memory for high utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.agents-identity-blue-scale-mem-up.arn}"
    ]
    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.ntt-autoscale-identity-grp-blue.name}"
    }
}
resource "aws_cloudwatch_metric_alarm" "memory-low" {
    alarm_name = "mem-util-low-agents"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "System/Linux"
    period = "300"
    statistic = "Average"
    threshold = "40"
    alarm_description = "This metric monitors ec2 memory for low utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.agents-identity-blue-scale-mem-down.arn}"
    ]
    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.ntt-autoscale-identity-grp-blue.name}"
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
	tags {
    Name = "${var.ntt_instance_sg_name}"
	Environment = "${var.Environment}"
	Owner = "${var.Owner}"
	Project = "${var.Project}"
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
    instance_port = "${var.app_port}"
    instance_protocol = "http"
  }
  listener {
    instance_port      = "${var.app_port}"
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "arn:aws:acm:us-east-2:350460106422:certificate/b6ae256c-9729-4934-af03-6f925c821f0c"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:${var.app_port}/sys/v1/heartbeat"
    interval            = 30
  }
  tags {
    Name = "${var.ntt_elb_name}"
	color = "${var.ntt_elb_color}"
	Environment = "${var.Environment}"
	Owner = "${var.Owner}"
	Project = "${var.Project}"
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
  tags {
    Name = "${var.ntt_elb_sg_name}"
	Environment = "${var.Environment}"
	Owner = "${var.Owner}"
	Project = "${var.Project}"
  }
}
