#--------------------------------------------------------------
#
# Creating dev and prod VPCs using aws_network module from github repo
#
# Github repo: https://github.com/azadjahangirov/terraform_modules 
#
# Made by Azad Jaha
# ------------------------------------------------------------------------------


provider "aws" {
  region = "eu-north-1"
}

/*
module "vpc-default" {
  //source = "../Modules/aws_network"
  source = "git@github.com:azadjahangirov/terraform_modules.git//aws_network"
}
*/


module "vpc-dev" {
 // source = "../Modules/aws_network"
  source = "git@github.com:azadjahangirov/terraform_modules.git//aws_network"
  env = "development"
  vpc_cidr = "10.100.0.0/16"
  public_subnet_cidrs = ["10.100.1.0/24", "10.100.2.0/24"]
  private_subnet_cidrs = ["10.100.11.0/24", "10.100.22.0/24"]
}

module "vpc-prod" {
  //source = "../Modules/aws_network"
  source = "git@github.com:azadjahangirov/terraform_modules.git//aws_network"
  env = "production"
  vpc_cidr = "10.10.0.0/16"
  public_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  private_subnet_cidrs = ["10.10.11.0/24", "10.10.22.0/24", "10.10.33.0/24"]
}

#================================================

output "prod_public_subnet_ids" {
  value = module.vpc-prod.public_subnet_ids
}

output "prod_private_subnet_ids" {
  value = module.vpc-prod.private_subnet_ids
}

output "dev_public_subnet_ids" {
  value = module.vpc-dev.public_subnet_ids
}

output "dev_private_subnet_ids" {
  value = module.vpc-dev.private_subnet_ids
}


