#!/usr/bin/env bash
set -euo pipefail

# Run this from the repo root: chaos-edge-devops/

cd terraform

echo "🔧 Replacing main.tf, provider.tf, variables.tf, outputs.tf with fixed versions..."

cat > main.tf <<'EOF'
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.72"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

#####################
# Providers
#####################

provider "aws" {
  region = var.region
}

#####################
# Variables & Locals
#####################

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

locals {
  vpc_cidr = "10.0.0.0/16"
}

#####################
# Networking (VPC)
#####################

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "chaos-edge-vpc"
  cidr = local.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

#####################
# EKS Cluster
#####################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }

  enable_irsa = true
}

#####################
# Kubernetes & Helm providers
# (use module.eks outputs; NO data aws_eks_cluster)
#####################

provider "kubernetes" {
  host = module.eks.cluster_endpoint

  cluster_ca_certificate = base64decode(
    module.eks.cluster_certificate_authority_data
  )

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name
    ]
  }
}

provider "helm" {
  kubernetes {
    host = module.eks.cluster_endpoint

    cluster_ca_certificate = base64decode(
      module.eks.cluster_certificate_authority_data
    )

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name
      ]
    }
  }
}

#####################
# NGINX Ingress via Helm
#####################

resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  namespace  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.2"

  create_namespace = true

  values = [
    yamlencode({
      controller = {
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
          }
        }
      }
    })
  ]

  depends_on = [module.eks]
}

#####################
# NGINX Service data (for output)
#####################

data "kubernetes_service" "nginx_lb" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [helm_release.nginx_ingress]
}
EOF

cat > provider.tf <<'EOF'
# provider.tf
# Core providers and required_providers are defined in main.tf.
terraform {
  required_version = ">= 1.5.0"
}
EOF

cat > variables.tf <<'EOF'
# variables.tf
# Extra variables can go here.
# region and cluster_name are defined in main.tf.

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {
    Project = "chaos-edge-devops"
    Owner   = "ccarrylab"
  }
}
EOF

cat > outputs.tf <<'EOF'
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
EOF

echo "✅ Files written. Running terraform fmt/validate/plan..."

terraform fmt
terraform validate
terraform plan

echo "✅ Done. You can now run: terraform apply"

