variable "access_key_id" {
    description = "AWS Access Key ID"
    type        = string
    sensitive   = true 
}

variable "secret_access_key" {
    description = "AWS Access Key ID"
    type        = string
    sensitive   = true 
}

variable "session_token" {
  description = "AWS Session Token (optional, for temporary credentials)"
  type        = string
  sensitive   = true
}

variable "region" {
    description = "Cloud Region to Use"
    type = string
} 

variable "atlas_endpoint_service_name" {
    description = "Atlas Endpoint Service Name"
    type = string
} 