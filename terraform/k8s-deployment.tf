########################
# Namespace
########################
resource "kubernetes_namespace" "chaos" {
  metadata {
    name = "chaos-edge"
  }
}

########################
# Go chaos Deployment
########################
resource "kubernetes_deployment_v1" "chaos_app" {
  metadata {
    name      = "chaos-app"
    namespace = kubernetes_namespace.chaos.metadata[0].name
    labels = {
      app = "chaos-app"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "chaos-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "chaos-app"
        }
      }
      spec {
        container {
          name  = "chaos-app"
          image = "public.ecr.aws/nginx/nginx:stable"
          
          port {
            container_port = 80  # Changed from 8080 to 80
          }
          
          readiness_probe {
            http_get {
              path = "/"  # Changed from /healthz to /
              port = 80   # Changed from 8080 to 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
          
          liveness_probe {
            http_get {
              path = "/"  # Changed from /healthz to /
              port = 80   # Changed from 8080 to 80
            }
            initial_delay_seconds = 15
            period_seconds        = 20
          }
          
          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_namespace.chaos]
}

########################
# Service
########################
resource "kubernetes_service" "chaos_service" {
  metadata {
    name      = "chaos-service"
    namespace = kubernetes_namespace.chaos.metadata[0].name
    labels = {
      app = "chaos-app"
    }
  }
  spec {
    selector = {
      app = "chaos-app"
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80  # Changed from 8080 to 80
    }
    type = "ClusterIP"
  }
  depends_on = [kubernetes_deployment_v1.chaos_app]
}

########################
# Ingress (using NGINX ingress controller)
########################
resource "kubernetes_ingress_v1" "chaos_ingress" {
  metadata {
    name      = "chaos-ingress"
    namespace = kubernetes_namespace.chaos.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
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
  depends_on = [
    kubernetes_service.chaos_service,
    helm_release.nginx_ingress
  ]
}