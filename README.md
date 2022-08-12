## Demo-Website-Setup-with-ALB-and-Auto-Scaling-Group

The aim is to setup a demo website which should use the basic AWS Auto Scaling Group feature along with Application Load Balancer for load balancing the website to outside world.

This project reusing the below VPC Module for VPC setup;
https://github.com/AneeshkbAwait/VPC-Module---Terraform.git

Application latest image is built using Packer and which is pulled to the ASG Launch Configuration using approrpiate filters.

ALB make use of SSL certificate imported from ACM to secure the website and http to https redirection is enabled from ALB. 

### AWS Features used
- Ec2
- Auto Scaling Group
- Launch Configuration
- Application Load Balancer
- Target Group
- Route53 Aliasing
- ACM
