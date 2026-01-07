# terraform/k8s-deployment.tf
# Complete Kubernetes deployment configuration for chaos-edge Go application
# NOTE: Do NOT include terraform block here - it's already in provider.tf

# Reference the ECR repository created in ecr.tf
data "aws_ecr_repository" "chaos_edge" {
  name = aws_ecr_repository.chaos_edge_go.name
}

# Local variable for the app image URI
locals {
  app_image_uri = "${data.aws_ecr_repository.chaos_edge.repository_url}:latest"
}

# Kubernetes namespace for the application
resource "kubernetes_namespace" "chaos_edge" {
  metadata {
    name = "chaos-edge"
    labels = {
      name = "chaos-edge"
    }
  }

  depends_on = [module.eks]
}

# ConfigMap for application configuration
resource "kubernetes_config_map" "chaos_config" {
  metadata {
    name      = "chaos-config"
    namespace = kubernetes_namespace.chaos_edge.metadata[0].name
  }

  data = {
    "APP_NAME"    = "chaos-edge-go"
    "ENVIRONMENT" = "production"
    "PORT"        = "8080"
  }

  depends_on = [kubernetes_namespace.chaos_edge]
}

# Deployment for the chaos-edge Go application
resource "kubernetes_deployment" "chaos_go" {
  metadata {
    name      = "chaos-go"
    namespace = kubernetes_namespace.chaos_edge.metadata[0].name
    labels = {
      app       = "chaos-go"
      component = "api"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "chaos-go"
      }
    }

    template {
      metadata {
        labels = {
          app       = "chaos-go"
          component = "api"
        }
      }

      spec {
        container {
          name  = "go-chaos"
          image = local.app_image_uri
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
          }

          # Health check endpoint
          liveness_probe {
            http_get {
              path   = "/health"
              port   = "http"
              scheme = "HTTP"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path   = "/health"
              port   = "http"
              scheme = "HTTP"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 2
          }

          # Resource limits
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          # Environment variables
          env {
            name = "POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }

          env {
            name = "POD_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          env {
            name = "POD_IP"
            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }

          # Reference ConfigMap
          env_from {
            config_map_ref {
              name = kubernetes_config_map.chaos_config.metadata[0].name
            }
          }
        }

        restart_policy = "Always"
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "1"
        max_unavailable = "0"
      }
    }
  }

  depends_on = [module.eks, kubernetes_namespace.chaos_edge]
}

# Service to expose the deployment
resource "kubernetes_service" "chaos_service" {
  metadata {
    name      = "chaos-service"
    namespace = kubernetes_namespace.chaos_edge.metadata[0].name
    labels = {
      app = "chaos-go"
    }
  }

  spec {
    selector = {
      app = "chaos-go"
    }

    port {
      name        = "http"
      port        = 80
      target_port = "http"
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.chaos_go]
}

# Ingress to expose the service via NGINX
resource "kubernetes_ingress_v1" "chaos_ingress" {
  metadata {
    name      = "chaos-ingress"
    namespace = kubernetes_namespace.chaos_edge.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.chaos_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.chaos_service, helm_release.nginx]
}

# Outputs
output "kubernetes_namespace" {
  description = "Kubernetes namespace for chaos-edge application"
  value       = kubernetes_namespace.chaos_edge.metadata[0].name
}

output "chaos_service_name" {
  description = "Kubernetes service name"
  value       = kubernetes_service.chaos_service.metadata[0].name
}

output "chaos_deployment_name" {
  description = "Kubernetes deployment name"
  value       = kubernetes_deployment.chaos_go.metadata[0].name
}

output "app_image_uri" {
  description = "Docker image URI for the chaos-edge application"
  value       = local.app_image_uri
}
