data "aws_ami" "myami" {

  owners      = ["self"]
  most_recent = true
  filter {
    name   = "name"
    values = ["zomato-prod-*"]
  }
}


data "aws_route53_zone" "myzone" {

  name         = "testpjt.tech."
  private_zone = false
}
