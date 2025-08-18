resource "null_resource" "load_sample_dataset" {
  provisioner "local-exec" {
    command = <<EOT
      set -e
      http_response=$(mktemp)
      http_code=$(curl -u "${var.public_key}:${var.private_key}" \
        --digest -X POST \
        --header "Accept: application/vnd.atlas.2025-03-12+json" \
        --header "Content-Type: application/json" \
        -o "$http_response" -w "%%{http_code}" \
        "https://cloud.mongodb.com/api/atlas/v2/groups/${data.mongodbatlas_project.existing_project.id}/sampleDatasetLoad/${var.cluster_name}")
      if [ "$http_code" -lt 200 ] || [ "$http_code" -ge 300 ]; then
        echo "Failed to load sample dataset. Response code: $http_code"
        cat "$http_response"
        exit 1
      fi
      rm -f "$http_response"
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
  triggers = {
    always_run = timestamp()
  }
  depends_on = [mongodbatlas_cluster.this]
}

resource "mongodbatlas_cluster" "this" {
  project_id   = data.mongodbatlas_project.existing_project.id
  name         = var.cluster_name
  cluster_type = "REPLICASET"
  replication_specs {
    num_shards = 1
    regions_config {
      region_name     = "EU_WEST_1"
      electable_nodes = 3
      priority        = 7
      read_only_nodes = 0
    }
  }
  cloud_backup = true
  auto_scaling_disk_gb_enabled = true

  # Provider Settings "block"
  provider_name               = "AWS"
  provider_instance_size_name = "M10"
}

resource "mongodbatlas_database_user" "iam_user" {
  username           = var.iam_role  # The Lambda execution role ARN
  project_id         = data.mongodbatlas_project.existing_project.id
  auth_database_name = "$external"  # Important: must be \$external for IAM auth
  
  roles {
    role_name     = "readWrite"
    database_name = var.database_name
  }
  
  aws_iam_type = "ROLE"  # This tells Atlas it's an IAM role
}