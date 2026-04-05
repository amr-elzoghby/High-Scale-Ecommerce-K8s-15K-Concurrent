resource "aws_security_group" "alb_sg" {
  name        = "amr-alb-sg"
  description = "Security Group for Load Balancer"
  vpc_id      = aws_vpc.web-vpc.id 

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_sg" {
  name        = "amr-app-sg"
  description = "Security Group for Application Servers"
  vpc_id      = aws_vpc.web-vpc.id 

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    
    security_groups = [aws_security_group.alb_sg.id] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}