# outputs.tf

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "nginx_ingress_service_hostname" {
  description = "Hostname of the NGINX ingress Network Load Balancer"
  value       = data.kubernetes_service.nginx_lb.status[0].load_balancer[0].ingress[0].hostname
}
