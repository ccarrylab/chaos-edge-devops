# 🌐 Chaos Edge DevOps Platform

Production-grade edge computing platform with chaos engineering capabilities.

**Architecture:** CloudFront → NLB → NGINX Ingress → EKS → Go Microservices

## 🎯 What This Does

- **Edge Distribution:** CloudFront for global CDN with gzip compression
- **Kubernetes Platform:** EKS 1.30 cluster with auto-scaling
- **Ingress Control:** NGINX with NLB backend
- **Chaos Engineering:** Built-in latency/failure injection endpoints
- **Monitoring:** Dashboard for observability

## 📋 Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.5
- kubectl >= 1.28
- Helm >= 3.12

## 🚀 Quick Start

### 1. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**What this creates:**
- VPC with public/private subnets across 2 AZs
- EKS cluster named `chaos-edge`
- NGINX Ingress Controller with NLB
- CloudFront distribution

### 2. Configure kubectl
```bash
aws eks update-kubeconfig --name chaos-edge --region us-east-1
kubectl get nodes
```

### 3. Deploy Demo Application
```bash
cd ../demo
kubectl apply -f demo-app.yaml
```

### 4. Test the Platform
```bash
# Get CloudFront URL
cd ../terraform
terraform output cloudfront_domain

# Wait 2-3 minutes for CloudFront propagation
curl https://$(terraform output -raw cloudfront_domain)
```

## 📁 Project Structure
```
chaos-edge-devops/
├── terraform/           # Infrastructure as Code
│   ├── main.tf         # VPC, EKS, NGINX, CloudFront
│   ├── variables.tf    # Input variables
│   └── outputs.tf      # Export values
├── demo/               # Demo applications
│   └── demo-app.yaml   # Sample web app
├── app/                # Application code
│   └── go-service/     # Go chaos engineering service
├── k8s/                # Kubernetes manifests
├── dashboard/          # Monitoring dashboards
└── README.md
```

## 🔧 Configuration

### Update AWS Region

Edit `terraform/variables.tf`:
```hcl
variable "region" {
  default = "us-east-1"  # Change as needed
}
```

### Scale Node Groups

Edit `terraform/main.tf`:
```hcl
eks_managed_node_groups = {
  chaos = {
    min_size     = 2    # Adjust capacity
    max_size     = 10
    desired_size = 4
  }
}
```

## 🎭 Chaos Engineering Endpoints

The Go service provides chaos injection endpoints:
```bash
# Inject 500ms latency
curl https://your-cloudfront-url/chaos/latency?ms=500

# Simulate failures
curl https://your-cloudfront-url/chaos/error?rate=0.1
```

## 📊 Monitoring

Access the dashboard:
```bash
kubectl port-forward -n monitoring svc/dashboard 3000:3000
```

## 🧹 Cleanup
```bash
cd terraform
terraform destroy
```

**Warning:** This deletes ALL resources including the VPC, EKS cluster, and data.

## 💰 Cost Estimates

- **EKS Control Plane:** $0.10/hour (~$73/month)
- **t3.medium nodes (2):** ~$60/month
- **NAT Gateway:** ~$32/month
- **CloudFront:** Pay-as-you-go (minimal for testing)
- **NLB:** ~$16/month

**Monthly Total:** ~$181 for demo workload

## 🔐 Security Notes

- EKS cluster uses IAM access entries (no aws-auth ConfigMap)
- NGINX Ingress uses NLB for production-grade traffic handling
- CloudFront enforces HTTPS
- Cluster endpoint is publicly accessible (restrict in production)

## 🐛 Troubleshooting

### kubectl Can't Connect
```bash
aws eks update-kubeconfig --name chaos-edge --region us-east-1
kubectl get nodes
```

### Terraform Apply Fails
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify region
aws configure get region
```

### Pods Not Starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

## 📚 Learn More

- [Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

## 📝 License

MIT

## 👤 Author

**Cohen H. Carryl**
- DevOps Engineer
- [GitHub](https://github.com/ccarrylab)