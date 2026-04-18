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

module "compute" {
  source = "../../../modules/compute"

  environment      = "prod"
  name_prefix      = "shop-prod"
  aws_region       = var.aws_region
  ami_id           = var.ami_id
  instance_type    = var.instance_type
  key_name         = var.key_name
  db_password      = var.db_password
  
  asg_desired_capacity = 2 
  asg_min_size         = 2
  asg_max_size         = 4

  network_remote_state_key = "prod/network/terraform.tfstate"
  storage_remote_state_key = "prod/storage/terraform.tfstate"
}

output "alb_dns_name" {
  value = module.compute.alb_dns_name
}
