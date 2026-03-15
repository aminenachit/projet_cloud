# =============================================================================
# Outputs Terraform
# =============================================================================

output "cluster_name" {
  description = "Nom du cluster GKE"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "Endpoint du cluster GKE"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_location" {
  description = "Localisation du cluster"
  value       = google_container_cluster.primary.location
}

output "ingress_ip" {
  description = "Adresse IP statique pour l'Ingress"
  value       = google_compute_global_address.ingress_ip.address
}

output "kubectl_config_command" {
  description = "Commande pour configurer kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${google_container_cluster.primary.location} --project ${var.project_id}"
}
