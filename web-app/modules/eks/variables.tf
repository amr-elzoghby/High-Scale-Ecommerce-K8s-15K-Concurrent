# ─── Common ───────────────────────────────────────────────────────────────────
variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "ecommerce-microservices"
}

variable "owner" {
  description = "Project owner"
  type        = string
  default     = "3mr-devops"
}

# ─── EKS Cluster ──────────────────────────────────────────────────────────────
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

# ─── Node Group ───────────────────────────────────────────────────────────────
variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

# ─── Networking (from network remote state) ───────────────────────────────────
variable "network_remote_state_key" {
  description = "S3 key for the network remote state"
  type        = string
  default     = "network/terraform.tfstate"
}

variable "remote_state_bucket" {
  description = "S3 bucket name for remote state"
  type        = string
}
variable "node_capacity_type" {
  description = "Capacity type of the stable node group"
  type        = string
  default     = "ON_DEMAND"
}

# ─── Spot Node Group ──────────────────────────────────────────────────────────────
variable "spot_instance_types" {
  description = "List of EC2 instance types for the Spot node group (multiple for fallback)"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium", "t2.medium"]
}

variable "spot_desired_size" {
  description = "Desired number of Spot worker nodes"
  type        = number
  default     = 2
}

variable "spot_min_size" {
  description = "Minimum number of Spot worker nodes"
  type        = number
  default     = 2
}

variable "spot_max_size" {
  description = "Maximum number of Spot worker nodes for autoscaling"
  type        = number
  default     = 10
}
