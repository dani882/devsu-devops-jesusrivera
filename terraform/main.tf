# Create a Kubernetes namespace for the application
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = "devsu"
  }
}

# Create a Kubernetes deployment for the application
resource "kubernetes_deployment" "devsu_app" {
  metadata {
    name      = "devsu-app"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app = "devsu"
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "devsu"
      }
    }

    template {
      metadata {
        labels = {
          app = "devsu"
        }
      }

      spec {
        container {
          name  = "devsu"
          image = var.image

          port {
            container_port = 8000
          }

          volume_mount {
            mount_path = "/code/db"
            name       = "sqlite-storage"
          }

          env {
            name  = "DJANGO_SETTINGS_MODULE"
            value = "app.settings"
          }
        }

        volume {
          name = "sqlite-storage"

          empty_dir {}
        }
      }
    }
  }
}
