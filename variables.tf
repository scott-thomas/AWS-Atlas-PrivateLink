variable "atlas_public_key" {
  type        = string
  description = "Public Programmatic API key to authenticate to Atlas"
  sensitive   = true
}

variable "atlas_private_key" {
  type        = string
  description = "Private Programmatic API key to authenticate to Atlas"
  sensitive   = true
}

variable "aws_access_key_id" {
    description = "AWS Access Key ID"
    type        = string
    sensitive   = true 
}

variable "aws_secret_access_key" {
    description = "AWS Access Key ID"
    type        = string
    sensitive   = true 
}

variable "aws_session_token" {
  description = "AWS Session Token (optional, for temporary credentials)"
  type        = string
  sensitive   = true
}

variable "aws_cloud_region" {
    description = "Cloud Region to Use"
    type = string
}

variable "atlas_organisation_id" {
    type = string
    description = "The name of the cluster"
}

variable "atlas_project" {
    type = string
    description = "The project where the cluster will live"
}

variable "atlas_cluster_name" {
    type = string
    description = "The name of the cluster"
    default = "Main"
}

