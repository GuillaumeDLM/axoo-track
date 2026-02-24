terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# ========== Réseau ==========

resource "docker_network" "axoo_network" {
  name = "axoo-network"
}

# ========== PostgreSQL ==========

resource "docker_image" "postgres" {
  name         = "postgres:16-alpine"
  keep_locally = true
}

resource "docker_volume" "pg_data" {
  name = "axoo-pg-data"
}

resource "docker_container" "postgres" {
  name  = "axoo-postgres"
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
    "POSTGRES_DB=${var.db_name}",
  ]

  networks_advanced {
    name = docker_network.axoo_network.name
  }

  volumes {
    volume_name    = docker_volume.pg_data.name
    container_path = "/var/lib/postgresql/data"
  }

  restart = "unless-stopped"
}

# ========== API Axoo-Track ==========

resource "docker_image" "axoo_track" {
  name = "axoo-track:latest"

  build {
    context    = "${path.module}/../apps/axoo-track-api"
    dockerfile = "Dockerfile"
    tag        = ["axoo-track:latest"]
  }
}

resource "docker_container" "axoo_api" {
  name  = "axoo-api"
  image = docker_image.axoo_track.image_id

  env = [
    "PORT=${var.app_port}",
    "DATABASE_URL=postgresql://${var.db_user}:${var.db_password}@axoo-postgres:5432/${var.db_name}?schema=public",
    "JWT_SECRET=${var.jwt_secret}",
  ]

  networks_advanced {
    name = docker_network.axoo_network.name
  }

  restart    = "unless-stopped"
  depends_on = [docker_container.postgres]
}

# ========== NGINX Reverse Proxy ==========

resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = true
}

resource "docker_container" "nginx" {
  name  = "axoo-nginx"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = 80
  }

  networks_advanced {
    name = docker_network.axoo_network.name
  }

  upload {
    file    = "/etc/nginx/nginx.conf"
    content = file("${path.module}/nginx.conf")
  }

  restart    = "unless-stopped"
  depends_on = [docker_container.axoo_api]
}

# ========== Dynatrace OneAgent ==========

resource "docker_image" "dynatrace" {
  name         = "dynatrace/oneagent:latest"
  keep_locally = true
}

resource "docker_container" "dynatrace" {
  name       = "axoo-dynatrace"
  image      = docker_image.dynatrace.image_id
  privileged = true

  env = [
    "ONEAGENT_INSTALLER_TENANT_URL=${var.dynatrace_tenant_url}",
    "ONEAGENT_INSTALLER_SCRIPT_TOKEN=${var.dynatrace_token}",
  ]

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.axoo_network.name
  }

  restart    = "unless-stopped"
  depends_on = [docker_container.axoo_api]
}
