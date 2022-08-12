data "aws_ami" "myami" {

  owners      = ["self"]
  most_recent = true
  filter {
    name   = "name"
    values = ["testpjt-prod-*"]
  }
}


data "aws_route53_zone" "myzone" {

  name         = "testpjt.tech."
  private_zone = false
}
