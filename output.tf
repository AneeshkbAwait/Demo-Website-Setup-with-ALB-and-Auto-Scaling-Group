output "zone" {

  value = data.aws_route53_zone.myzone.name
}

output "url" {

 value = "http://${aws_lb.myclb.dns_name}"
}
