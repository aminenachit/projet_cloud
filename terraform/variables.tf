# =============================================================================
# Variables Terraform
# =============================================================================

variable "project_id" {
  description = "ID du projet Google Cloud"
  type        = string
}

variable "region" {
  description = "Région GCP"
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "Zone GCP"
  type        = string
  default     = "europe-west1-b"
}

variable "cluster_name" {
  description = "Nom du cluster GKE"
  type        = string
  default     = "ecommerce-cluster"
}

variable "node_count" {
  description = "Nombre de nœuds dans le node pool"
  type        = number
  default     = 2
}

variable "max_node_count" {
  description = "Nombre maximum de nœuds (autoscaling)"
  type        = number
  default     = 4
}

variable "machine_type" {
  description = "Type de machine GCE pour les nœuds"
  type        = string
  default     = "e2-medium"
}

variable "environment" {
  description = "Environnement de déploiement"
  type        = string
  default     = "production"
}
