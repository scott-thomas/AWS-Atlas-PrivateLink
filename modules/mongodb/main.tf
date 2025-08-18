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
    database_name = "admin"
  }
  
  aws_iam_type = "ROLE"  # This tells Atlas it's an IAM role
}