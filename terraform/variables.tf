variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "chaos-edge"
}

variable "app_image_uri" {
  description = "ECR URI for the chaos-edge Go application"
  type        = string
  default     = "chaos-edge-go:latest"  # Use generic name in repo
}

