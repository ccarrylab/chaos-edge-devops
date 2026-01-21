# EKS Cluster Data Sources (REQUIRED)
data "aws_eks_cluster" "chaos_edge" {
  name = "chaos-edge"
}

data "aws_eks_cluster_auth" "chaos_edge" {
  name = "chaos-edge"
}

########################
# Production Namespace Automation
########################
resource "null_resource" "namespace_chaos_edge" {
  triggers = {
    cluster_endpoint = data.aws_eks_cluster.chaos_edge.endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "🚀 Auto-provisioning chaos-edge namespace..."
      
      # Create or update namespace idempotently
      kubectl create namespace chaos-edge \
        --dry-run=client -o yaml | kubectl apply -f - || true
      
      # Wait for namespace readiness with retries
      for i in {1..10}; do
        if kubectl get ns chaos-edge -o jsonpath='{.status.phase}' 2>/dev/null | grep -q Active; then
          echo "✅ Namespace chaos-edge ACTIVE (attempt $i)"
          kubectl label namespace chaos-edge \
            chaos-engineering="enabled" \
            app.kubernetes.io/managed-by="terraform" \
            break-glass="chaos-experiments"
          exit 0
        fi
        echo "⏳ Waiting for namespace... (attempt $i/10)"
        sleep 3
      done
      
      echo "❌ Namespace creation failed after 10 attempts"
      kubectl get ns chaos-edge || kubectl get ns | head -5
      exit 1
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [data.aws_eks_cluster.chaos_edge]
}

########################
# Chaos Engineering Application
########################
resource "kubernetes_deployment_v1" "chaos_app" {
  metadata {
    name      = "chaos-app"
    namespace = "chaos-edge"
    labels = {
      app                    = "chaos-app"
      "chaos-engineering"    = "target"
      "app.kubernetes.io/name" = "chaos-edge"
    }
  }

  spec {
    replicas                = 3
    revision_history_limit  = 5
    min_ready_seconds       = 30

    selector {
      match_labels = {
        app = "chaos-app"
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge     = "25%"
        max_unavailable = "25%"
      }
    }

    template {
      metadata {
        labels = {
          app = "chaos-app"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "80"
        }
      }
      
      spec {
        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                label_selector {
                  match_labels = {
                    app = "chaos-app"
                  }
                }
                topology_key = "kubernetes.io/hostname"
              }
            }
          }
        }

        container {
          name  = "chaos-app"
          image = "public.ecr.aws/nginx/nginx:stable-alpine"

          port {
            container_port = 80
            name           = "http"
            protocol       = "TCP"
          }

          readiness_probe {
            http_get {
              path = "/"
              port = "http"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            success_threshold     = 1
            failure_threshold     = 3
          }

          liveness_probe {
            http_get {
              path = "/"
              port = "http"
            }
            initial_delay_seconds = 30
            period_seconds        = 20
            timeout_seconds       = 10
            success_threshold     = 1
            failure_threshold     = 3
          }

          resources {
            requests = {
              cpu    = "150m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "750m"
              memory = "768Mi"
            }
          }

          security_context {
            run_as_non_root = true
            run_as_user     = 101
          }
        }

        termination_grace_period_seconds = 30
      }
    }
  }

  depends_on = [null_resource.namespace_chaos_edge]
}

########################
# Internal Service
########################
resource "kubernetes_service_v1" "chaos_service" {
  metadata {
    name      = "chaos-service"
    namespace = "chaos-edge"
    labels = {
      app = "chaos-app"
    }
    annotations = {
      "prometheus.io/scrape" = "true"
    }
  }

  spec {
    selector = {
      app = "chaos-app"
    }
    
    port {
      name        = "http"
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    
    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment_v1.chaos_app]
}

########################
# Production Ingress
########################
resource "kubernetes_ingress_v1" "chaos_ingress" {
  metadata {
    name      = "chaos-ingress"
    namespace = "chaos-edge"
    labels = {
      app = "chaos-ingress"
    }
    annotations = {
      "kubernetes.io/ingress.class"              = "nginx"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "nginx.ingress.kubernetes.io/ssl-redirect"   = "false"
    }
  }

  spec {
    ingress_class_name = "nginx"
    
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.chaos_service.metadata[0].name
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
    kubernetes_service_v1.chaos_service,
    null_resource.namespace_chaos_edge,
    helm_release.nginx_ingress
  ]
}
