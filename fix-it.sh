#!/bin/bash

###############################################################################
# CHAOS EDGE DEVOPS - COMPLETE REPOSITORY FIX SCRIPT (v2.0)
# 
# This script:
# - Fixes all Terraform configuration issues
# - Updates Kubernetes manifests
# - Fixes Docker configuration
# - Updates .gitignore and documentation
# - Validates everything
#
# Safe, idempotent, and production-ready
###############################################################################

set -e

# ============================================================================
# COLORS & FORMATTING
# ============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${CYAN}→ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# ============================================================================
# VALIDATION
# ============================================================================

print_header "CHAOS EDGE DEVOPS - COMPLETE REPOSITORY FIX"

if [ ! -d "terraform" ] || [ ! -d "app" ] || [ ! -d "k8s" ]; then
    print_error "Must run from repository root directory"
    exit 1
fi

REPO_ROOT=$(pwd)
TF_DIR="$REPO_ROOT/terraform"

echo "Repository root: $REPO_ROOT"
echo ""

# ============================================================================
# PART 1: FIX TERRAFORM CONFIGURATION
# ============================================================================

print_header "PART 1: TERRAFORM CONFIGURATION"

cd "$TF_DIR"

print_step "Backing up original files"
if [ -f "main.tf" ]; then
    BACKUP_TIME=$(date +%s)
    cp main.tf "main.tf.backup.$BACKUP_TIME"
    print_success "Backup created: main.tf.backup.$BACKUP_TIME"
fi

print_step "Removing duplicate provider/data/output blocks from main.tf"

# Use awk to remove ALL provider, data, and output blocks
# This preserves all module and resource definitions
awk '
  BEGIN { in_block = 0; block_type = "" }
  
  /^provider "/ || /^data "/ || /^output "/ {
    in_block = 1
    block_type = $1
    next
  }
  
  in_block && /^}$/ {
    in_block = 0
    next
  }
  
  in_block { next }
  
  { print }
' main.tf > main.tf.tmp && mv main.tf.tmp main.tf

print_success "Cleaned main.tf"

print_step "Creating provider.tf"
cat > provider.tf << 'PROVIDER_EOF'
# Terraform configuration with provider definitions
# This file centralizes all provider setup for cleaner organization

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  # Uncomment after first successful apply to enable S3 remote state
  # This requires manual creation of S3 bucket and DynamoDB table first
  # backend "s3" {
  #   bucket         = "chaos-edge-tf-state-<YOUR-ACCOUNT-ID>"
  #   key            = "prod/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

# AWS provider configuration
provider "aws" {
  region = var.region
}

# Data sources for EKS cluster authentication
# These are used by Helm and Kubernetes providers to authenticate dynamically
data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# Helm provider - requires EKS cluster endpoint and authentication token
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# Kubernetes provider - for managing Kubernetes resources
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}
PROVIDER_EOF

print_success "Created provider.tf"

print_step "Creating variables.tf with validation rules"
cat > variables.tf << 'VARIABLES_EOF'
variable "region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.region))
    error_message = "Must be a valid AWS region format (e.g., us-east-1, eu-west-1, ap-southeast-1)"
  }
}

variable "cluster_name" {
  description = "Name of the EKS cluster (alphanumeric and hyphens only, 3-63 characters)"
  type        = string
  default     = "chaos-edge"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,63}$", var.cluster_name))
    error_message = "Cluster name must be 3-63 characters, lowercase alphanumeric and hyphens only"
  }
}
VARIABLES_EOF

print_success "Created variables.tf"

print_step "Creating outputs.tf with comprehensive outputs"
cat > outputs.tf << 'OUTPUTS_EOF'
# Output values for accessing the deployed infrastructure

output "configure_kubectl" {
  description = "Command to configure kubectl with EKS cluster credentials"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "vpc_id" {
  description = "VPC ID created for the EKS cluster"
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_version" {
  description = "Kubernetes version running on the EKS cluster"
  value       = module.eks.cluster_version
}

output "eks_endpoint" {
  description = "EKS cluster API endpoint URL"
  value       = module.eks.cluster_endpoint
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain (primary entry point for application)"
  value       = aws_cloudfront_distribution.chaos_edge.domain_name
}

output "nginx_nlb_dns" {
  description = "NGINX Ingress Controller NLB DNS name (internal access)"
  value       = data.aws_lb.nginx_nlb.dns_name
}
OUTPUTS_EOF

print_success "Created outputs.tf"

print_step "Adding missing aws_lb data source to main.tf"

# Create the missing data source block
cat > /tmp/nlb_datasource.txt << 'NLB_EOF'
# Data source to locate the NGINX NLB created by Helm release
# Uses Kubernetes service tags to discover the load balancer dynamically
data "aws_lb" "nginx_nlb" {
  tags = {
    "kubernetes.io/service-name" = "nginx-ingress/nginx-ingress-ingress-nginx-controller"
  }

  depends_on = [helm_release.nginx]
}

NLB_EOF

# Find the CloudFront resource line and insert data source before it
CLOUDFRONT_LINE=$(grep -n "^resource \"aws_cloudfront_distribution\"" main.tf | head -1 | cut -d: -f1)

if [ -n "$CLOUDFRONT_LINE" ]; then
    # Use sed to insert the data source
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS sed syntax
        sed -i '' "${CLOUDFRONT_LINE}r /tmp/nlb_datasource.txt" main.tf
    else
        # Linux sed syntax
        sed -i "${CLOUDFRONT_LINE}r /tmp/nlb_datasource.txt" main.tf
    fi
    rm /tmp/nlb_datasource.txt
    print_success "Added aws_lb data source to main.tf"
else
    print_error "Could not find CloudFront resource in main.tf"
    exit 1
fi

print_step "Creating .terraform-version file"
cd "$REPO_ROOT"
cat > .terraform-version << 'TFVERSION_EOF'
~> 1.5
TFVERSION_EOF
print_success "Created .terraform-version"

print_step "Creating terraform.tfvars.example"
cd "$TF_DIR"
cat > terraform.tfvars.example << 'TFVARS_EOF'
# AWS region where infrastructure will be deployed
region = "us-east-1"

# Name of the EKS cluster (must be unique within the AWS account)
cluster_name = "chaos-edge"
TFVARS_EOF
print_success "Created terraform.tfvars.example"

print_step "Reinitializing Terraform"
rm -rf .terraform .terraform.lock.hcl 2>/dev/null || true

if terraform init -upgrade; then
    print_success "Terraform initialized"
else
    print_error "Terraform init failed"
    exit 1
fi

print_step "Validating Terraform configuration"
if terraform validate; then
    print_success "Terraform configuration validated"
else
    print_error "Terraform validation failed"
    exit 1
fi

# ============================================================================
# PART 2: FIX KUBERNETES MANIFESTS
# ============================================================================

print_header "PART 2: KUBERNETES MANIFESTS"

print_step "Updating k8s/deployment.yaml with health probes and resource limits"
cat > "$REPO_ROOT/k8s/deployment.yaml" << 'K8S_DEPLOYMENT_EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chaos-go
  labels:
    app: chaos-go
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: chaos-go
  template:
    metadata:
      labels:
        app: chaos-go
    spec:
      serviceAccountName: chaos-go-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
      - name: go-chaos
        image: public.ecr.aws/ecs-chrome/edge-chaos:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
          name: http
          protocol: TCP
        
        # Resource requests and limits for proper Kubernetes scheduling
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        
        # Liveness probe - restart pod if application crashes
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        # Readiness probe - remove from load balancer if not ready
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 5
          periodSeconds: 2
          timeoutSeconds: 2
          failureThreshold: 2
        
        # Security context - minimal permissions
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
        
        # Volume mount for temporary files
        volumeMounts:
        - name: tmp
          mountPath: /tmp
      
      # Volumes
      volumes:
      - name: tmp
        emptyDir: {}

---
apiVersion: v1
kind: Service
metadata:
  name: chaos-service
  labels:
    app: chaos-go
spec:
  type: ClusterIP
  selector:
    app: chaos-go
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
K8S_DEPLOYMENT_EOF

print_success "Updated k8s/deployment.yaml"

print_step "Creating k8s/rbac.yaml with least-privilege RBAC"
cat > "$REPO_ROOT/k8s/rbac.yaml" << 'K8S_RBAC_EOF'
# ServiceAccount for chaos-go application
apiVersion: v1
kind: ServiceAccount
metadata:
  name: chaos-go-sa
  namespace: default
  labels:
    app: chaos-go

---
# Role with minimal required permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: chaos-go-role
  namespace: default
rules:
# Allow reading ConfigMaps (for configuration)
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
# Allow reading Secrets (for credentials)
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]

---
# RoleBinding to connect ServiceAccount to Role
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: chaos-go-rolebinding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: chaos-go-role
subjects:
- kind: ServiceAccount
  name: chaos-go-sa
  namespace: default
K8S_RBAC_EOF

print_success "Created k8s/rbac.yaml"

print_step "Creating k8s/network-policy.yaml for network security"
cat > "$REPO_ROOT/k8s/network-policy.yaml" << 'K8S_NETPOL_EOF'
# Default deny all ingress traffic - explicit allow required
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress

---
# Allow ingress traffic from NGINX ingress controller
apiVersion: networking.k8s.io/v1
kin
