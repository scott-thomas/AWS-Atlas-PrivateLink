variable "project" {
    type = string
    description = "The project where the cluster will live"
}

variable "cluster_name" {
    type = string
    description = "The name of the cluster"
}

variable "public_key" {
  type        = string
  description = "Public Programmatic API key to authenticate to Atlas"
}
variable "private_key" {
  type        = string
  description = "Private Programmatic API key to authenticate to Atlas"
}

variable "org_id" {
    type = string
    description = "The organisation ID"
}

variable "aws_cloud_region" {
    description = "Cloud Region to Use"
    type = string
}

variable "iam_role" {
    description = "Lambda Execution role"
    type = string
}