output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.chaos_edge.domain_name
}

output "cloudfront_url" {
  description = "Full CloudFront HTTPS URL"
  value       = "https://${aws_cloudfront_distribution.chaos_edge.domain_name}"
}

output "nginx_nlb_dns" {
  description = "NGINX NLB DNS name"
  value       = data.aws_lb.nginx_nlb.dns_name
}

output "kubectl_config" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}