# Create a Kubernetes namespace for the application
resource "kubernetes_namespace" "devsu_namespace" {
  metadata {
    name = var.app_name
  }
}

resource "kubernetes_config_map_v1" "devsu_config_map" {
  metadata {
    name      = "${var.app_name}-config"
    namespace = kubernetes_namespace.devsu_namespace.metadata[0].name
  }

  data = {
    "DATABASE_NAME" = var.database_name
  }
}

# Create a Kubernetes secret for the application
resource "kubernetes_secret_v1" "devsu_secret" {
  metadata {
    name      = "${var.app_name}-secret"
    namespace = kubernetes_namespace.devsu_namespace.metadata[0].name
  }

  data = {
    "DJANGO_SECRET_KEY" = var.django_secret_key
  }
}

resource "kubernetes_persistent_volume_claim_v1" "devsu_sqlite_pvc" {
  metadata {
    name      = "${var.app_name}-pvc"
    namespace = kubernetes_namespace.devsu_namespace.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "1Gi"
      }
    }

    storage_class_name = "local-path"
  }
  wait_until_bound = false
}

# Create a Kubernetes deployment for the application
resource "kubernetes_deployment" "devsu_app" {
  metadata {
    name      = "${var.app_name}-deployment"
    namespace = kubernetes_namespace.devsu_namespace.metadata[0].name
    labels = {
      app = var.app_name
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }

      spec {
        container {
          name  = var.app_name
          image = var.image

          port {
            container_port = var.port
          }

          volume_mount {
            mount_path = "/app/data"
            name       = "db-data"
          }

          # Environment variables
          env {
            name = "DATABASE_NAME"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.devsu_config_map.metadata[0].name
                key  = "DATABASE_NAME"
              }
            }
          }

          env {
            name = "DJANGO_SECRET_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.devsu_secret.metadata[0].name
                key  = "DJANGO_SECRET_KEY"
              }
            }
          }
        }

        volume {
          name = "db-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.devsu_sqlite_pvc.metadata[0].name
          }
        }
      }
    }
  }

  timeouts {
    create = "5m"
    update = "5m"
  }
}

# Create a Kubernetes service for the application
resource "kubernetes_service" "devsu_service" {
  metadata {
    name      = "${var.app_name}-service"
    namespace = kubernetes_namespace.devsu_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      port        = var.port
      target_port = var.port
    }
  }
}

# Create a Kubernetes ingress for the application
resource "kubernetes_ingress_v1" "devsu_ingress" {
  metadata {
    name      = "${var.app_name}-ingress"
    namespace = kubernetes_namespace.devsu_namespace.metadata[0].name
  }

  spec {
    rule {
      host = "jesus.devsu.localhost"
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.devsu_service.metadata[0].name
              port {
                number = var.port
              }
            }
          }
        }
      }
    }
  }
}
