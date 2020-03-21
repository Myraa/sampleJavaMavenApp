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
  default = "162.227.87.147/32"
}

variable "vpc_id" {
  default = "vpc-2178b34a"
}

variable "public_subnets_elb" {
  default = "subnet-9eb547f5"
}

variable "public_subnets_inst" {
  default = "subnet-9eb547f5"
}

variable "app_port" {
  default = "8083"
}

variable "ntt_elb_sg_name" {
  default = "ntt-myapp-elb-sg"
}

variable "ntt_elb_name" {
  default = "myapp-elb"
}

variable "ntt_instance_sg_name" {
  default = "ntt-instance-sg"
}

variable "key_name" {
  default = "jenkins"
}

variable "instance_name" {
  default = "ntt-myapp"
}

variable "ntt_elb_color" {
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
