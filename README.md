# Demo-Website-Setup-with-ALB-and-Auto-Scaling-Group

The aim is to setup a demo website which should use the basic AWS Auto Scaling Group feature along with Application Load Balancer for load balancing the website to outside world.

This project reusing a VPC Module for VPC setup. You can view the VPC module in my below repository;
- https://github.com/AneeshkbAwait/VPC-Module---Terraform.git

Application latest image is built using Packer Image builder and which is pulled to the ASG Launch Configuration using approrpiate filters.

ALB make use of SSL certificate imported from ACM to secure the website and http to https redirection is enabled from ALB. 
