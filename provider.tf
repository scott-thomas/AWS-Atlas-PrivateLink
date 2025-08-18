terraform {
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
      version = "1.37.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "6.2.0"
    }
  }
}

provider "mongodbatlas" {
  public_key  = var.atlas_public_key
  private_key = var.atlas_private_key
}

provider "aws" {
  region     = var.aws_cloud_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  token      = var.aws_session_token # Required if using temporary credentials (e.g., from STS or assume-role)
}