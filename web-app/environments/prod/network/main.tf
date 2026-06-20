provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Owner       = var.owner
      Environment = "prod"
      ManagedBy   = "Terraform"
    }
  }
}

module "network" {
  source = "../../../modules/network"

  environment  = "prod"
  name_prefix  = "shop-prod"
  vpc_cidr     = var.vpc_cidr
  aws_region   = var.aws_region
  cluster_name = "ecommerce-prod"
  
  subnets = {
    public_1  = "10.1.1.0/24"
    public_2  = "10.1.2.0/24"
    private_1 = "10.1.3.0/24"
    private_2 = "10.1.4.0/24"
  }
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "app_security_group_id" {
  value = module.network.app_security_group_id
}

output "alb_security_group_id" {
  value = module.network.alb_security_group_id
}
