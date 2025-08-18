# =============================================================================
# MONGODB ATLAS CLUSTER MODULE
# =============================================================================
module "my_atlas_cluster" {
  source = "./modules/mongodb"

  # Atlas Authentication
  private_key = var.atlas_private_key
  public_key  = var.atlas_public_key

  # Atlas Configuration
  project      = var.atlas_project
  cluster_name = var.atlas_cluster_name
  org_id       = var.atlas_organisation_id

  # AWS Integration
  aws_cloud_region = var.aws_cloud_region
  iam_role         = module.aws_resources.iam_role
}

# =============================================================================
# AWS RESOURCES MODULE
# =============================================================================
module "aws_resources" {
  source = "./modules/aws"

  # AWS Authentication
  access_key_id     = var.aws_access_key_id
  secret_access_key = var.aws_secret_access_key
  session_token     = var.aws_session_token

  # AWS Configuration
  region = var.aws_cloud_region

  # Atlas Integration
  atlas_endpoint_service_name = try(data.mongodbatlas_cluster.your_cluster.connection_strings[0].private_endpoint[0].connection_string, "")
}

# =============================================================================
# PRIVATE LINK CONFIGURATION
# =============================================================================

# Create MongoDB Atlas Private Link Endpoint
resource "mongodbatlas_privatelink_endpoint" "aws" {
  project_id    = module.my_atlas_cluster.projectId
  provider_name = "AWS"
  region        = var.aws_cloud_region
}

# Create AWS VPC Endpoint
resource "aws_vpc_endpoint" "aws_endpoint" {
  vpc_id             = module.aws_resources.vpcId
  service_name       = mongodbatlas_privatelink_endpoint.aws.endpoint_service_name
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.aws_resources.subnet_ids
  security_group_ids = module.aws_resources.security_group_ids

  tags = {
    Name        = "thomas-scott-mongodb-atlas-endpoint"
    Environment = "production"
    Project     = "movies-search"
  }
}

# Configure MongoDB Atlas Private Link Endpoint Service
resource "mongodbatlas_privatelink_endpoint_service" "aws" {
  project_id          = mongodbatlas_privatelink_endpoint.aws.project_id
  private_link_id     = mongodbatlas_privatelink_endpoint.aws.private_link_id
  endpoint_service_id = aws_vpc_endpoint.aws_endpoint.id
  provider_name       = "AWS"
}

# =============================================================================
# WAIT FOR ATLAS PRIVATE ENDPOINT CONNECTION STRING
# =============================================================================

resource "null_resource" "wait_for_atlas_connection_string" {
  provisioner "local-exec" {
    command = <<EOT
      for i in {1..30}; do
        CONNECTION_STRING=$(curl -s -u "${var.atlas_public_key}:${var.atlas_private_key}" \
          --digest "https://cloud.mongodb.com/api/atlas/v1.0/groups/${mongodbatlas_privatelink_endpoint.aws.project_id}/clusters/${module.my_atlas_cluster.clusterName}" \
          | jq -r '.connectionStrings.privateEndpoint[0].connectionString // empty')
        if [ ! -z "$CONNECTION_STRING" ]; then
          echo "Private endpoint connection string is available."
          exit 0
        fi
        echo "Waiting for Atlas private endpoint connection string..."
        sleep 20
      done
      echo "Timed out waiting for Atlas private endpoint connection string."
      exit 1
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
  triggers = {
    always_run = timestamp()
  }
  depends_on = [mongodbatlas_privatelink_endpoint_service.aws]
}

# =============================================================================
# DATA SOURCES
# =============================================================================

# Retrieve cluster information with private connection string
data "mongodbatlas_cluster" "your_cluster" {
  project_id = mongodbatlas_privatelink_endpoint.aws.project_id
  name       = module.my_atlas_cluster.clusterName
  depends_on = [null_resource.wait_for_atlas_connection_string]
}