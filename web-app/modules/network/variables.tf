variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the main VPC"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
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

variable "vpc_instance_tenancy" {

  description = "VPC instance tenancy"
  type        = string
  default     = "default"
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "all_traffic_cidr" {
  description = "CIDR block for all traffic"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "http_port" {
  description = "Port for HTTP traffic"
  type        = number
  default     = 80
}

variable "any_protocol" {
  description = "Protocol for any traffic"
  type        = string
  default     = "-1"
}

variable "any_port" {
  description = "Port for any traffic"
  type        = number
  default     = 0
}

variable "cluster_name" {
  description = "EKS cluster name (used for Karpenter subnet discovery tags)"
  type        = string
  default     = ""
}

variable "subnets" {
  description = "Subnets CIDR map"
  type = object({
    public_1  = string
    public_2  = string
    private_1 = string
    private_2 = string
  })
}

