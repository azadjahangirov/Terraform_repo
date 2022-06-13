#------------------------------------------
# Provision Highly Avaliable Web in a region Deafult VPC
# Create:
#       - Launch configuration with Auto AMI Lookup
#       - Auto Scaling Group using 2 Availabality Zones
#       - Application Load Balancer in 2 AZ
#
# Made by Azad Jaha
#------------------------------------------------

# 1st Section: Defining Cloud providers, regions and AMI
# Mentioned AWS cloud provider and region in order to create our blue/green deployment

provider "aws" {
  region = "eu-central-1"
}


# Include all availability zones
data "aws_availability_zones" "available" {}


# Choosing latest amazon linux AMI
data "aws_ami" "latest_amazon_linux" {
  owners      = ["137112412989"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }
}

#-------------------------------------------------------------


# 2nd Section: Defining default VPC and Subnets
# Default VPC and two Default subnets in each availability zone

resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = data.aws_availability_zones.available.names[1]
}

#---------------------------------------------------


# 3rd Section: Creating ALB, Target Group and Listeners

# Before creating Apllication Load Balancer we should creat target groups for load balancer to route requests to its targets using the protocol and port number and define health check settings

resource "aws_alb_target_group" "bg_target_gr" {
  name = "Blue-Green-ALB-Target"
  target_type = "instance"
  vpc_id = aws_default_vpc.default.id
  port = "80"
  protocol = "HTTP"
  protocol_version = "HTTP1"
  #vpc_id = aws_..
  health_check {
    protocol = "HTTP"
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 4
    interval = 5
  } 
}



# Creating Application load balancer

resource "aws_alb" "bg_alb" {
  name  = "Blue-Green-HA-ALB"
  load_balancer_type = "application"
  subnets = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  security_groups = [aws_security_group.bg_scgr.id]
  internal = false
  enable_deletion_protection = false  //If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer.
}



# We should create listener in order to determine how the load balancer routes requests to the targets

resource "aws_alb_listener" "bg_alb_listener" {
  load_balancer_arn = aws_alb.bg_alb.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.bg_target_gr.arn
  }
}



#----------------------------------------------------------

# 4th Section: Creating Launch configuration

# In this section we will create Launch Configuration using latest AMI that mentioned in 1st section, inlcuding "create_before_destroy" lifecycle rule and it will be used when we create Auto Scaling Group
# Note1: As you can see instead of "name", we used "name_prefix", because if you are creating more than one resource, you may face error as Terraform won't be able to create two resources with same name.
# Note:Later we can update it to launch template

resource "aws_launch_configuration" "bg_lc" {
  name_prefix     = "Blue/Green-Highly-Available-LC-"
  image_id        = data.aws_ami.latest_amazon_linux.id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.bg_scgr.id]
  user_data       = file("user_data.sh.tpl")

  lifecycle {
    create_before_destroy = true   //Note: Zero down-time option will help new resource to be created before old one is destroyed.
  }
}

#-------------------------------------------------


# 5th STEP: Creating ASG and ASG attachment 

# Creating Auto Scaling Group using Launch Configuration in previous step and defining health check

resource "aws_autoscaling_group" "bg_asg" {
  name                 = "ASG-${aws_launch_configuration.bg_lc.name}"
  launch_configuration = aws_launch_configuration.bg_lc.name
  desired_capacity = 2
  min_size             = 2
  max_size             = 2
  min_elb_capacity     = 2
  health_check_type    = "ELB"
  vpc_zone_identifier  = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]

  dynamic "tag" {
    for_each = {
      Name   = "Blue/Green in ASG"
      Owner  = "Azad Jaha"
      TAGKEY = "TAGVALUE"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true  //Note: Zero down-time option will help new resource to be created before old one is destroyed.
  }
}



# Finally we are attaching Application Load Balancing load balancer to our Auto Scaling group
resource "aws_autoscaling_attachment" "bg_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.bg_asg.id
  lb_target_group_arn    = aws_alb_target_group.bg_target_gr.arn
}


