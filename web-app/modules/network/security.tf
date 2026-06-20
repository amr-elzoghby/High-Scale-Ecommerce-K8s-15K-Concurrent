# ─── ALB Security Group (public-facing) ───────────────────────────────────────
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Allow HTTP traffic from the internet to the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = var.http_port
    to_port     = var.http_port
    protocol    = "tcp"
    cidr_blocks = var.all_traffic_cidr
  }

  egress {
    description = "Allow all outbound"
    from_port   = var.any_port
    to_port     = var.any_port
    protocol    = var.any_protocol
    cidr_blocks = var.all_traffic_cidr
  }

  tags = {
    Name = "${var.name_prefix}-alb-sg"
  }
}

# ─── App Security Group (private — only from ALB) ─────────────────────────────
resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "Allow HTTP traffic only from the ALB security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = var.http_port
    to_port         = var.http_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound (for Docker pulls, package installs)"
    from_port   = var.any_port
    to_port     = var.any_port
    protocol    = var.any_protocol
    cidr_blocks = var.all_traffic_cidr
  }

  tags = {
    Name                            = "${var.name_prefix}-app-sg"
    "karpenter.sh/discovery"        = var.cluster_name
  }
}

# ─── VPC Endpoints Security Group ─────────────────────────────────────────────
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.name_prefix}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints - allows HTTPS from App/EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # Outbound not strictly required for Interface Endpoints, but good practice
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-vpc-endpoints-sg"
  }
}