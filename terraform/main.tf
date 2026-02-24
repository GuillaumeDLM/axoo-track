terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }
}

# ================================================================
# PROVIDER KUBERNETES (le cluster doit etre demarre AVANT terraform)
# ================================================================

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

# ================================================================
# COUCHE 3 : NAMESPACES (separation des environnements)
# ================================================================

resource "kubernetes_namespace" "axoo_track" {
  metadata {
    name = var.namespace
    labels = {
      project     = "axoo-track"
      environment = var.environment
      managed-by  = "terraform"
    }
  }

}

# ================================================================
# COUCHE 3 : SECRETS ET CONFIGURATION
# ================================================================

resource "kubernetes_config_map" "axoo_track_config" {
  metadata {
    name      = "axoo-track-config"
    namespace = kubernetes_namespace.axoo_track.metadata[0].name
  }

  data = {
    DB_NAME  = var.db_name
    DB_USER  = var.db_user
    DB_HOST  = "axoo-track-db"
    DB_PORT  = "5432"
    APP_PORT = tostring(var.app_port)
  }
}

resource "kubernetes_secret" "axoo_track_secrets" {
  metadata {
    name      = "axoo-track-secrets"
    namespace = kubernetes_namespace.axoo_track.metadata[0].name
  }

  data = {
    DB_PASSWORD = var.db_password
    JWT_SECRET  = var.jwt_secret
  }

  type = "Opaque"
}

resource "kubernetes_secret" "axoo_track_dynatrace" {
  metadata {
    name      = "axoo-track-dynatrace-secrets"
    namespace = kubernetes_namespace.axoo_track.metadata[0].name
  }

  data = {
    TENANT_URL = "${var.dynatrace_tenant_url}/api/v1/deployment/installer/agent/unix/default/latest?arch=x86"
    API_TOKEN  = var.dynatrace_token
  }

  type = "Opaque"
}

# ================================================================
# COUCHE 4 : BASE DE DONNEES (axoo-track-db)
# ================================================================

resource "kubernetes_persistent_volume_claim" "axoo_track_db" {
  metadata {
    name      = "axoo-track-db-pvc"
    namespace = kubernetes_namespace.axoo_track.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

resource "kubernetes_service" "axoo_track_db" {
  metadata {
    name      = "axoo-track-db"
    namespace = kubernetes_namespace.axoo_track.metadata[0].name
    labels = {
      app = "axoo-track-db"
    }
  }

  spec {
    cluster_ip = "None"
    selector = {
      app = "axoo-track-db"
    }
    port {
      port        = 5432
      target_port = 5432
    }
  }
}

resource "kubernetes_stateful_set" "axoo_track_db" {
  metadata {
    name      = "axoo-track-db"
    namespace = kubernetes_namespace.axoo_track.metadata[0].name
  }

  spec {
    service_name = "axoo-track-db"
    replicas     = 1

    selector {
      match_labels = {
        app = "axoo-track-db"
      }
    }

    template {
      metadata {
        labels = {
          app = "axoo-track-db"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:16-alpine"

          port {
            container_port = 5432
          }

          env {
            name = "POSTGRES_DB"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.axoo_track_config.metadata[0].name
                key  = "DB_NAME"
              }
            }
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.axoo_track_config.metadata[0].name
                key  = "DB_USER"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.axoo_track_secrets.metadata[0].name
                key  = "DB_PASSWORD"
              }
            }
          }

          volume_mount {
            name       = "pg-data"
            mount_path = "/var/lib/postgresql/data"
          }

          readiness_probe {
            exec {
              command = ["pg_isready", "-U", var.db_user]
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }

        volume {
          name = "pg-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.axoo_track_db.metadata[0].name
          }
        }
      }
    }
  }
}

# ================================================================
# COUCHE 7 : API (axoo-track-api)
# ================================================================

resource "kubernetes_service" "axoo_track_api" {
  metadata {
    name      = "axoo-track-api"
    namespace = kubernetes_namespace.axoo_track.metadata[0].name
    labels = {
      app = "axoo-track-api"
    }
  }

  spec {
    type = "ClusterIP"
    selector = {
      app = "axoo-track-api"
    }
    port {
      port        = 3000
      target_port = 3000
    }
  }
}

resource "kubernetes_deployment" "axoo_track_api" {
  metadata {
    name      = "axoo-track-api"
    namespace = kubernetes_namespace.axoo_track.metadata[0].name
  }

  spec {
    replicas = var.api_replicas

    selector {
      match_labels = {
        app = "axoo-track-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "axoo-track-api"
        }
      }

      spec {
        init_container {
          name    = "wait-for-db"
          image   = "busybox:1.36"
          command = ["sh", "-c", "until nc -z axoo-track-db 5432; do echo 'Waiting for axoo-track-db...'; sleep 2; done"]
        }

        container {
          name              = "api"
          image             = "axoo-track-api:latest"
          image_pull_policy = "Never"

          port {
            container_port = 3000
          }

          env {
            name = "PORT"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.axoo_track_config.metadata[0].name
                key  = "APP_PORT"
              }
            }
          }

          env {
            name = "DB_USER"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.axoo_track_config.metadata[0].name
                key  = "DB_USER"
              }
            }
          }

          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.axoo_track_secrets.metadata[0].name
                key  = "DB_PASSWORD"
              }
            }
          }

          env {
            name = "DB_HOST"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.axoo_track_config.metadata[0].name
                key  = "DB_HOST"
              }
            }
          }

          env {
            name = "DB_PORT"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.axoo_track_config.metadata[0].name
                key  = "DB_PORT"
              }
            }
          }

          env {
            name = "DB_NAME"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.axoo_track_config.metadata[0].name
                key  = "DB_NAME"
              }
            }
          }

          env {
            name  = "DATABASE_URL"
            value = "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?schema=public"
          }

          env {
            name = "JWT_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.axoo_track_secrets.metadata[0].name
                key  = "JWT_SECRET"
              }
            }
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 15
            period_seconds        = 10
          }
        }
      }
    }
  }

  depends_on = [kubernetes_stateful_set.axoo_track_db]
}

# ================================================================
# COUCHE 8 : FRONTEND (axoo-track-web)
# ================================================================

resource "kubernetes_service" "axoo_track_web" {
  metadata {
    name      = "axoo-track-web"
    namespace = kubernetes_namespace.axoo_track.metadata[0].name
    labels = {
      app = "axoo-track-web"
    }
  }

  spec {
    type = "ClusterIP"
    selector = {
      app = "axoo-track-web"
    }
    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_deployment" "axoo_track_web" {
  metadata {
    name      = "axoo-track-web"
    namespace = kubernetes_namespace.axoo_track.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "axoo-track-web"
      }
    }

    template {
      metadata {
        labels = {
          app = "axoo-track-web"
        }
      }

      spec {
        container {
          name              = "web"
          image             = "axoo-track-web:latest"
          image_pull_policy = "Never"

          port {
            container_port = 80
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }

}

# ================================================================
# COUCHE 9 : INGRESS (axoo-track-proxy)
# ================================================================

resource "kubernetes_ingress_v1" "axoo_track_proxy" {
  metadata {
    name      = "axoo-track-proxy"
    namespace = kubernetes_namespace.axoo_track.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$1"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      http {
        path {
          path      = "/api(/|$)(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = kubernetes_service.axoo_track_api.metadata[0].name
              port {
                number = 3000
              }
            }
          }
        }

        path {
          path      = "/(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = kubernetes_service.axoo_track_web.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

}

# ================================================================
# COUCHE 9 : OBSERVABILITE (axoo-track-dynatrace)
# ================================================================

resource "kubernetes_daemon_set_v1" "axoo_track_dynatrace" {
  metadata {
    name      = "axoo-track-dynatrace"
    namespace = kubernetes_namespace.axoo_track.metadata[0].name
    labels = {
      app = "axoo-track-dynatrace"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "axoo-track-dynatrace"
      }
    }

    template {
      metadata {
        labels = {
          app = "axoo-track-dynatrace"
        }
      }

      spec {
        host_pid     = true
        host_network = true

        container {
          name  = "oneagent"
          image = "dynatrace/oneagent:latest"

          security_context {
            privileged = true
          }

          env {
            name = "ONEAGENT_INSTALLER_SCRIPT_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.axoo_track_dynatrace.metadata[0].name
                key  = "TENANT_URL"
              }
            }
          }

          env {
            name = "ONEAGENT_INSTALLER_DOWNLOAD_TOKEN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.axoo_track_dynatrace.metadata[0].name
                key  = "API_TOKEN"
              }
            }
          }

          volume_mount {
            name       = "docker-sock"
            mount_path = "/var/run/docker.sock"
            read_only  = true
          }

          volume_mount {
            name       = "host-root"
            mount_path = "/mnt/root"
            read_only  = true
          }
        }

        volume {
          name = "docker-sock"
          host_path {
            path = "/var/run/docker.sock"
          }
        }

        volume {
          name = "host-root"
          host_path {
            path = "/"
          }
        }
      }
    }
  }
}
