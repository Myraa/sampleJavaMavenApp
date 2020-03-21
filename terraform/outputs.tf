output "elb_dns_name" {
  value = "${aws_elb.ntt-elb.dns_name}"
}

