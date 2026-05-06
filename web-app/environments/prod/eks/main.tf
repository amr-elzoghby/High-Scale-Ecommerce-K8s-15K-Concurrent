provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ecommerce-microservices"
      Owner       = "3mr-devops"
      Environment = "prod"
      ManagedBy   = "Terraform"
    }
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}

module "eks" {
  source = "../../../modules/eks"

  # ─── Common ───────────────────────────────────────────────────────────────
  environment = "prod"
  name_prefix = "shop-prod"
  aws_region  = var.aws_region

  # ─── Cluster ──────────────────────────────────────────────────────────────
  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  # ─── Worker Nodes  ──────────────
  node_instance_type = "m7i-flex.large"
  node_desired_size  = 2
  node_min_size      = 2
  node_max_size      = 4

  # ─── Network (reads VPC & subnets from network remote state) ──────────────
  remote_state_bucket      = "tf-state-ecommerce-microservices-3mr"
  network_remote_state_key = "prod/network/terraform.tfstate"

  # ─── Spot Node Group ─────────
  spot_instance_types = ["c7i-flex.large", "m7i-flex.large", "t3.small"]
  spot_min_size     = 2
  spot_desired_size = 2
  spot_max_size     = 10
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
