#!/bin/bash
set -e

echo "🚀 Chaos Edge Platform Deployment"
echo "=================================="

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "❌ terraform not found"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl not found"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ aws cli not found"; exit 1; }

# Deploy infrastructure
echo "📦 Deploying infrastructure..."
cd terraform
terraform init
terraform apply -auto-approve

# Configure kubectl
echo "⚙️  Configuring kubectl..."
CLUSTER_NAME=$(terraform output -raw cluster_name)
REGION=$(terraform output -raw region)
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

# Wait for nodes
echo "⏳ Waiting for nodes..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Deploy demo
echo "🎯 Deploying demo application..."
cd ../demo
kubectl apply -f demo-app.yaml

# Wait for pods
echo "⏳ Waiting for pods..."
kubectl wait --for=condition=Ready pod -l app=chaos-demo --timeout=300s

# Get CloudFront URL
echo "✅ Deployment complete!"
cd ../terraform
echo ""
echo "CloudFront URL: https://$(terraform output -raw cloudfront_domain)"
echo ""
echo "⏳ CloudFront propagation takes 2-3 minutes..."
echo "Test with: curl https://$(terraform output -raw cloudfront_domain)"