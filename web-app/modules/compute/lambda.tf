# ─── Archive Lambda Code ──────────────────────────────────────────────────────
data "archive_file" "payment_lambda" {
  type        = "zip"
  source_file = "${path.module}/../../ecommerce-microservices/services/payment-service/lambda_handler.py"
  output_path = "${path.module}/payment_lambda.zip"
}


# ─── Lambda IAM Role ─────────────────────────────────────────────────────────
resource "aws_iam_role" "payment_lambda_role" {
  name = "${var.name_prefix}-payment-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.payment_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ─── Lambda Security Group ──────────────────────────────────────────────────
resource "aws_security_group" "lambda" {
  name        = "${var.name_prefix}-lambda-sg"
  description = "Security group for payment lambda"
  vpc_id      = local.vpc_id

  egress {
    from_port   = var.any_port
    to_port     = var.any_port
    protocol    = var.any_protocol
    cidr_blocks = var.all_traffic_cidr
  }

  tags = {
    Name = "${var.name_prefix}-lambda-sg"
  }
}

# Allow Lambda to talk to App (where DB is)
resource "aws_security_group_rule" "lambda_to_db" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = local.app_security_group_id
  source_security_group_id = aws_security_group.lambda.id
  description              = "Allow PostgreSQL traffic from Lambda"
}

# ─── Lambda Function ─────────────────────────────────────────────────────────
resource "aws_lambda_function" "payment_processor" {
  filename         = data.archive_file.payment_lambda.output_path
  source_code_hash = data.archive_file.payment_lambda.output_base64sha256
  function_name    = "${var.name_prefix}-payment-processor"
  role             = aws_iam_role.payment_lambda_role.arn
  handler          = "lambda_handler.handler"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }



  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc_access
  ]
}

# Add VPC Access policy to Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.payment_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ─── API Gateway (to expose Lambda) ──────────────────────────────────────────
resource "aws_apigatewayv2_api" "payment_api" {
  name          = "${var.name_prefix}-payment-api"
  protocol_type = "HTTP"
}


resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.payment_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.payment_processor.invoke_arn
}

resource "aws_apigatewayv2_route" "payment_route" {
  api_id    = aws_apigatewayv2_api.payment_api.id
  route_key = "POST /process"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.payment_api.id
  name        = "$default"
  auto_deploy = true
}

# Permission for API Gateway to call Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.payment_processor.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.payment_api.execution_arn}/*/*"
}

# ─── Output the API URL ──────────────────────────────────────────────────────
output "payment_lambda_url" {
  value       = aws_apigatewayv2_api.payment_api.api_endpoint
  description = "The HTTP API endpoint for the serverless payment processor"
}
