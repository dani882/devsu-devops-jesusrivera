# Create a Kubernetes namespace for the application
resource "kubernetes_namespace" "devsu_namespace" {
  metadata {
    name = var.app_name
  }
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
            mount_path = "/code/db"
            name       = "sqlite-storage"
          }

          env {
            name  = "devsu_SETTINGS_MODULE"
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

# Create a Kubernetes service for the application
resource "kubernetes_service" "devsu_service" {
  metadata {
    name      = "devsu-service"
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
    name      = "devsu-ingress"
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
