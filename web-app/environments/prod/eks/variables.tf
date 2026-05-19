variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "slack_webhook_url" {
  description = "Slack Webhook URL for Falco alerts"
  type        = string
  sensitive   = true
}
