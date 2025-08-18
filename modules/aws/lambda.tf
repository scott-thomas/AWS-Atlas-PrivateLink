# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-role-private-vpc-movie-search"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_mongodb_policy" {
  name = "lambda-mongodb-iam-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the AWSLambdaVPCAccessExecutionRole policy to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Create a security group for the Lambda function
resource "aws_security_group" "lambda_sg" {
  name        = "lambda-sg"
  description = "Security group for Lambda function"
  vpc_id      = aws_vpc.main.id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "lambda_deployment_bucket" {
  bucket_prefix = "lambda-code-movie-search-" # AWS recommends using a prefix for unique names

  # Enable versioning to easily revert to previous Lambda versions if needed

  tags = {
    Name = "Lambda Deployment Bucket for Movie Search"
  }
}

resource "aws_s3_object" "lambda_code_upload" {
  bucket = aws_s3_bucket.lambda_deployment_bucket.id
  # Use the MD5 hash of the zip file content as part of the key
  # This ensures a new S3 object is created if the code changes,
  # which properly triggers Lambda updates.
  key    = "lambda_function_package/${data.archive_file.lambda_zip.output_md5}.zip"
  source = data.archive_file.lambda_zip.output_path # Path to the generated zip file
  etag   = data.archive_file.lambda_zip.output_md5  # ETag for S3 object content verification
}

resource "aws_lambda_function" "my_lambda" {
  function_name = "get-movies" # Name for your Lambda function
  handler       = "lambda_function.lambda_handler" # File and function name
  runtime       = "python3.9"                      # Or python3.10, python3.11 etc.
  role          = aws_iam_role.lambda_exec.arn
  timeout       = 90                               # Lambda timeout in seconds (adjust as needed)
  memory_size   = 256                              # Lambda memory in MB (adjust as needed)

  s3_bucket = aws_s3_bucket.lambda_deployment_bucket.id
  # Updated: Reference the new aws_s3_object resource
  s3_key = aws_s3_object.lambda_code_upload.key

  # --- VPC Configuration ---
  # These must be IDs of existing resources in your AWS account.
  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  # --- Environment Variables ---
  environment {
    variables = {
      MONGODB_URI = var.atlas_endpoint_service_name
      MONGODB_DATABASE = "sample_mflix"
      # Replace <user>, <password>, and the VPC endpoint DNS name with your actual values.
      # It's highly recommended to use AWS Secrets Manager for sensitive data like passwords.
    }
  }

  tags = {
    Name = "vector-search-lambda"
  }
}