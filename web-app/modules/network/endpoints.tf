# ─── 1. S3 Gateway Endpoint ───────────────────────────────────────────────────
# Essential for ECR pulls and general file access from private instances.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "${var.name_prefix}-s3-endpoint"
  }
}

# ─── 2. SSM Interface Endpoints ───────────────────────────────────────────────
# Allows AWS Systems Manager (Session Manager) to work without NAT Gateway.
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  subnet_ids          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  private_dns_enabled = true

  tags = { Name = "${var.name_prefix}-ssm-endpoint" }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  subnet_ids          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  private_dns_enabled = true

  tags = { Name = "${var.name_prefix}-ssmmessages-endpoint" }
}

# ─── 3. ECR Interface Endpoints ───────────────────────────────────────────────
# Allows pulling Docker images from private repo without NAT Gateway.
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  subnet_ids          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  private_dns_enabled = true

  tags = { Name = "${var.name_prefix}-ecr-api-endpoint" }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  subnet_ids          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  private_dns_enabled = true

  tags = { Name = "${var.name_prefix}-ecr-dkr-endpoint" }
}

# ─── 4. EKS Interface Endpoint ────────────────────────────────────────────────
resource "aws_vpc_endpoint" "eks" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.eks"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  subnet_ids          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  private_dns_enabled = true

  tags = { Name = "${var.name_prefix}-eks-endpoint" }
}

# ─── 5. EC2 Interface Endpoint ────────────────────────────────────────────────
# Required for node bootstrapping and instance metadata operations.
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  subnet_ids          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  private_dns_enabled = true

  tags = { Name = "${var.name_prefix}-ec2-endpoint" }
}

# ─── 6. STS Interface Endpoint ────────────────────────────────────────────────
# Required for IRSA (IAM Roles for Service Accounts) token exchange.
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  subnet_ids          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  private_dns_enabled = true

  tags = { Name = "${var.name_prefix}-sts-endpoint" }
}
