variable "instance_type" {
  description = "The type of EC2 instance to use"
  type        = string
  default     = "t3.micro"
}

variable "db_password" {
  type      = string
  sensitive = true
}

