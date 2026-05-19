# Falco Module Variables
variable "environment" {
  description = "The environment name (e.g. dev, prod)"
  type        = string
}
variable "slack_webhook_url" {
  description = "The Slack Webhook URL to send Falco alerts to"
  type        = string
  sensitive   = true
}