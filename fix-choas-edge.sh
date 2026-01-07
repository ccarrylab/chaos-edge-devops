#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "🚀 Chaos Edge Repo Fix – cleaning Terraform & K8s wiring"

###############################################################################
# 1) Basic safety and backup
###############################################################################
if [ ! -d "terraform" ]; then
  echo "❌ terraform/ directory not found in $ROOT_DIR"
  exit 1
fi

cd terraform

echo "📦 Backing up main.tf once (if not already)"
if [ ! -f "main.tf.orig" ]; then
  cp main.tf main.tf.orig
fi

###############################################################################
# 2) Remove backup and duplicate clutter
###############################################################################
echo "🧹 Removing backup files and duplicate configs"

# Remove old backup files
rm -f main.tf.backup.* || true

# Remove outputs.tf if it only duplicates outputs from main.tf
if grep -q 'output "cluster_name"' outputs.tf 2>/dev/null || \
   grep -q 'output "kubeconfig_command"' outputs.tf 2>/dev/null || \
   grep -q 'output "eks_endpoint"' outputs.tf 2>/dev/null; then
  echo "   → Removing duplicate outputs.tf"
  rm -f outputs.tf
fi

# Remove extra terraform blocks from non‑root files (like k8s‑deployment.tf)
for f in *.tf; do
  if [ "$f" != "main.tf" ] && [ "$f" != "provider.tf" ]; then
    if grep -q '^terraform *{' "$f"; then
      echo "   → Stripping terraform {} block from $f"
      # Strip any terraform { ... } block
      tmp="${f}.tmp.$$"
      awk '
        BEGIN { skip=0 }
        /^terraform[[:space:]]*\{/ { skip=1 }
        skip==1 && /\}/ { skip=0; next }
        skip==0 { print }
      ' "$f" > "$tmp"
      mv "$tmp" "$f"
    fi
  fi
done

###############################################################################
# 3) Normalize providers into provider.tf only
###############################################################################
echo "🧩 Normalizing provider blocks"

# Create or overwrite provider.tf with one canonical definition
cat > provider.tf << 'EOF'
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

provider "aws" {
  region = var.region
}

# Kubernetes provider wired to the EKS cluster created in main.tf
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
  }
}

# Helm provider using the same EKS auth
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
    }
  }
}
EOF

# Remove any provider "aws"/"kubernetes"/"helm" blocks from main.tf
tmp_main="main.tf.tmp.$$"
awk '
  BEGIN { skip=0 }
  /^provider "aws"/      { skip=1 }
  /^provider "kubernetes"/ { skip=1 }
  /^provider "helm"/     { skip=1 }
  skip==1 && /\}/        { skip=0; next }
  skip==0 { print }
' main.tf > "$tmp_main"
mv "$tmp_main" main.tf

###############################################################################
# 4) Clean up duplicate outputs in main.tf
###############################################################################
echo "🔁 Cleaning duplicate outputs from main.tf"

tmp_main="main.tf.tmp.$$"
awk '
  BEGIN { skip=0 }
  /^output "cluster_name"/        { skip=1 }
  /^output "kubeconfig_command"/  { skip=1 }
  /^output "eks_endpoint"/        { skip=1 }
  skip==1 && /\}/                 { skip=0; next }
  skip==0 { print }
' main.tf > "$tmp_main"
mv "$tmp_main" main.tf

# Recreate outputs.tf with a single canonical set
cat > outputs.tf << 'EOF'
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
  description = "Command to update kubeconfig for this cluster"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}
EOF

###############################################################################
# 5) Ensure variables.tf exists and is minimal but valid
###############################################################################
echo "⚙️ Ensuring variables.tf exists"

if [ ! -f "variables.tf" ]; then
  cat > variables.tf << 'EOF'
variable "region" {
  description = "AWS region for the chaos-edge EKS cluster"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "chaos-edge"
}
EOF
fi

###############################################################################
# 6) Re-init Terraform & validate
###############################################################################
echo "🔄 Re-initializing Terraform"

rm -rf .terraform .terraform.lock.hcl || true
terraform init -upgrade

echo "✅ terraform validate"
terraform validate || {
  echo "❌ terraform validate failed – check above errors"
  exit 1
}

echo "🎉 Fix complete. Next suggested commands:"
echo "   aws eks update-kubeconfig --name chaos-edge --region us-east-1"
echo "   kubectl get nodes"
echo "   cd terraform && terraform plan"

