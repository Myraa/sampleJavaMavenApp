# =========================================================================
# Define Variables for terraform resourses
# =========================================================================

variable "region" {
  default = "us-east-2"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "cidr_blocks_inst_sg_in" {
  default = "172.31.0.0/16"
}

variable "vpc_id" {
  default = "vpc-2178b34a"
}

variable "public_subnets_elb" {
  default = "subnet-9eb547f5"
}

variable "private_subnets_inst" {
  default = "subnet-9eb547f5"
}

variable "app_port" {
  default = "8083"
}

variable "ntt_elb_sg_name" {
  default = "ntt-myapp-elb-sg"
}

variable "mcd_elb_name" {
  default = "myapp-elb"
}

variable "mcd_instance_sg_name" {
  default = "ntt-instance-sg"
}

variable "key_name" {
  default = "HopHop"
}

variable "instance_name" {
  default = "ntt-myapp"
}

variable "mcd_elb_color" {
  default = "blue"
}

variable "Environment" {
  default = "dev"
}

variable "Owner" {
  default = "Prasad"
}

variable "Project" {
  default = "NTT"
}
