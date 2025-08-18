# Create a new Virtual Private Cloud (VPC)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "mongodb-vpc"
  }
}

# Create three subnets in different Availability Zones
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"

  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1b"

  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-b"
  }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-1c"

  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-c"
  }
}

resource "aws_security_group" "endpoint_sg" {
  name        = "mongodb-atlas-endpoint-sg"
  description = "Allow traffic to MongoDB Atlas endpoint"
  vpc_id      = aws_vpc.main.id

  # Allow inbound traffic from your application servers on the MongoDB ports.
  # IMPORTANT: Replace "0.0.0.0/0" with the security group of your Lambda function
  # (e.g., security_groups = [aws_security_group.lambda_sg.id]) for production.

  ingress {
    from_port   = 1024
    to_port     = 1024
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change to your Lambda's security group ID for production
  }

  ingress {
    from_port   = 1026
    to_port     = 1026
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change to your Lambda's security group ID for production
  }

  ingress {
    from_port   = 1028
    to_port     = 1028
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change to your Lambda's security group ID for production
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change to your Lambda's security group ID for production
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mongodb-atlas-endpoint-sg"
  }
}

# resource "aws_vpc_endpoint" "aws_endpoint" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = var.atlas_endpoint_service_name
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
#   security_group_ids  = [aws_security_group.endpoint_sg.id]

#   tags = {
#     Name = "mongodb-atlas-endpoint"
#   }
# }