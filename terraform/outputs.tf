output "api_url" {
  description = "URL publique de l'API (via NGINX)"
  value       = "http://localhost"
}

output "network_name" {
  description = "Nom du réseau Docker interne"
  value       = docker_network.axoo_track_network.name
}
