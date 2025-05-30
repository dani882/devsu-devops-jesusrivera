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
    "DATABASE_NAME" = "data/${var.database_name}"
  }
}

# Create a Kubernetes secret for the application
resource "kubernetes_secret_v1" "devsu_secret" {
  metadata {
    name      = "${var.app_name}-secret"
    namespace = kubernetes_namespace.devsu_namespace.metadata[0].name
  }

  type = "Opaque"
  data = {
    "DJANGO_SECRET_KEY" = var.django_secret_key
  }
}

resource "kubernetes_persistent_volume_claim_v1" "devsu_sqlite_pvc" {
  metadata {
    name      = "${var.app_name}-pvc"
    namespace = kubernetes_namespace.devsu_namespace.metadata[0].name
    labels = {
      app = var.app_name
    }
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
        init_container {
          name  = "init-migrate"
          image = var.image

          working_dir = "/app"
          command     = ["sh", "-c", "python manage.py migrate --noinput"]

          volume_mount {
            name       = "db-data"
            mount_path = "/app/data"
          }

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

        container {
          name  = var.app_name
          image = var.image

          command = ["python", "manage.py", "runserver", "0.0.0.0:${var.app_port}"]

          port {
            container_port = var.app_port
          }

          readiness_probe {
            http_get {
              path = "/api/"
              port = var.app_port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
            success_threshold     = 1
          }

          liveness_probe {
            http_get {
              path = "/api/"
              port = var.app_port
            }
            initial_delay_seconds = 60
            period_seconds        = 30
            timeout_seconds       = 10
            failure_threshold     = 5
            success_threshold     = 1
          }

          resources {
            limits = {
              cpu = "100m"
            }
            requests = {
              cpu = "50m"
            }
          }

          volume_mount {
            name       = "db-data"
            mount_path = "/app/data"
          }

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
      port        = var.service_port
      target_port = var.app_port
    }
  }
}

# Create a Kubernetes ingress for the application
resource "kubernetes_ingress_v1" "devsu_ingress" {
  metadata {
    name      = "${var.app_name}-ingress"
    namespace = kubernetes_namespace.devsu_namespace.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"
    }
  }

  spec {
    rule {
      host = "localhost"
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.devsu_service.metadata[0].name
              port {
                number = var.service_port
              }
            }
          }
        }
      }
    }
  }
}

# Create a Kubernetes Horizontal Pod Autoscaler (HPA) for the application
resource "kubernetes_horizontal_pod_autoscaler_v2" "devsu_hpa" {
  metadata {
    name      = "${var.app_name}-hpa"
    namespace = kubernetes_namespace.devsu_namespace.metadata[0].name
  }

  spec {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.devsu_app.metadata[0].name
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 5
        }
      }
    }
  }
}
