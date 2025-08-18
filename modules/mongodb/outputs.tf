output "projectId" {
  value = data.mongodbatlas_project.existing_project.id
  description = "The Project ID"
}

output "clusterName" {
  value = mongodbatlas_cluster.this.name
  description = "The Project Name"
}
