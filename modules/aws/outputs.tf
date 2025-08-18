output "vpcId" {
  value = aws_vpc.main.id
  description = "The ID of VPC"
}

output "subnet_ids" {
    value = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
    description = "The subnets"
}

output "security_group_ids" {
    value = [aws_security_group.endpoint_sg.id]
    description = "Security Group IDs"
}

output "iam_role" {
    value = aws_iam_role.lambda_exec.arn
}