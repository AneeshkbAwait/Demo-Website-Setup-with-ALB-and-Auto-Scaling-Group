#---------------------------------------------
# Calling the VPC Module
#---------------------------------------------

module "vpc" {

  source   = "/var/terraform/modules/vpc/"
  vpc_cidr = var.project_vpc_cidr
  project  = var.project_name
  env      = var.project_env
}


#---------------------------------------------
# Key Pair
#---------------------------------------------

resource "aws_key_pair" "key" {

  key_name   = "${var.project_name}-${var.project_env}"
  public_key = file("mykey.pub")
  tags = {

    Name    = "${var.project_name}-${var.project_env}"
    project = var.project_name
    env     = var.project_env
  }
}


#---------------------------------------------
# Creating Security Group
#---------------------------------------------

resource "aws_security_group" "sg" {

  name        = "webserver-${var.project_name}-${var.project_env}"
  description = "Allow 80,443,22 traffic"
  vpc_id      = module.vpc.vpc_id
  ingress {

    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {

    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {

    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {

    Name    = "webserver-${var.project_name}-${var.project_env}"
    project = var.project_name
    env     = var.project_env
  }

}

#---------------------------------------------
# Creating the Launch Configuration for AsG
#---------------------------------------------

resource "aws_launch_configuration" "myapp" {

  name_prefix     = "myapp-"
  image_id        = data.aws_ami.myami.id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.key.id
  security_groups = [aws_security_group.sg.id]
  lifecycle {

    create_before_destroy = true
  }

}

#-------------------------------------------------------------------------------
# Creating the ASG with the Launch Configuration Created in the previous step
#--------------------------------------------------------------------------------


resource "aws_autoscaling_group" "myapp" {

  name_prefix          = "myapp-"
  launch_configuration = aws_launch_configuration.myapp.id
  vpc_zone_identifier  = [module.vpc.public1_subnet_id, module.vpc.public2_subnet_id]
  health_check_type    = "EC2"
  min_size             = "2"
  max_size             = "2"
  desired_capacity     = "2"
  target_group_arns = ["${aws_lb_target_group.myapp_tg.arn}"]

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "myapp"
  }

  lifecycle {
    create_before_destroy = true
  }

}


#---------------------------------------------
# Target Group Creation
#---------------------------------------------

resource "aws_lb_target_group" "myapp_tg" {

  name_prefix = "mytg-"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    port                = 80
    path                = "/index.php"
    interval            = 20
  }

  tags = {

    Name = "project-${var.project_name}-${var.project_env}"
  }
}


#---------------------------------------------
# Application LB Creation
#---------------------------------------------

resource "aws_lb" "myclb" {

  name_prefix        = "myapp-"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = [module.vpc.public1_subnet_id, module.vpc.public2_subnet_id]

  tags = {

    Name = "zomato-${var.project_name}-${var.project_env}"
  }
}


#---------------------------------------------
# ALB Listener Config for port 80
#---------------------------------------------

resource "aws_lb_listener" "http" {

  load_balancer_arn = aws_lb.myclb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myapp_tg.arn
  }

  tags = {

    Name = "project-${var.project_name}-${var.project_env}"
  }
}


#---------------------------------------------
# ALB Listener Config for port 443
#---------------------------------------------

resource "aws_lb_listener" "https" {

  load_balancer_arn = aws_lb.myclb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ap-south-1:254356662512:certificate/8edc3245-a7d9-48ee-805d-4f5ceb796d18"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myapp_tg.arn
  }
}


#--------------------------------------------------
# ALB Listener Rule for port 443 (https traffic)
#--------------------------------------------------

resource "aws_lb_listener_rule" "lb_rule" {

  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myapp_tg.arn
  }

  condition {
    host_header {
      values = ["myapp.testpjt.tech"]
    }
  }
}


#--------------------------------------------------
# Listener Port 80, http to https redirection rule
#--------------------------------------------------

resource "aws_lb_listener_rule" "redirect_http_to_https" {

  listener_arn = aws_lb_listener.http.arn

  action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = ["myapp.testpjt.tech"]
    }
  }
}


#---------------------------------------------
# Setting R53 Alias for ALB
#---------------------------------------------

resource "aws_route53_record" "alias" {

  zone_id = data.aws_route53_zone.myzone.zone_id
  name    = "myapp.testpjt.tech"
  type    = "A"

  alias {
    name                   = aws_lb.myclb.dns_name
    zone_id                = aws_lb.myclb.zone_id
    evaluate_target_health = true
  }
}
