```markdown
# Chaos Edge DevOps Platform 🚀

**Production Chaos Engineering Demo**  
**EKS + NGINX NLB + Go Microservice + Terraform IaC (85+ resources)**

[![EKS](https://img.shields.io/badge/AWS-EKS-blue?logo=amazonaws)](https://aws.amazon.com/eks/)
[![Terraform](https://img.shields.io/badge/Terraform-85%2B_resources-orange?logo=terraform)](https://www.terraform.io/)
[![Chaos Engineering](https://img.shields.io/badge/Chaos-Engineering-red)](https://principlesofchaos.org/)

## ✨ Live Demo Results (2026-01-07)
```
✅ **EKS Cluster**: chaos-edge (v1.30, 2x t3.medium nodes) - ACTIVE  
✅ **NGINX NLB**: Live endpoint responding (Network Load Balancer)  
✅ **Go App**: 3 replicas, /healthz endpoint healthy  
✅ **Terraform**: 85+ resources (VPC/NAT/EKS/NGINX/K8s)  
✅ **Chaos Tests**: Pod-kill, scale-to-zero, network-loss ✓
```

## 🚀 Quick Start (15 minutes → LIVE demo)

```bash
# Prerequisites: AWS CLI + kubectl + Docker Desktop + Terraform 1.5+
make deploy              # 12min: EKS + VPC + NGINX NLB
make chaos-demo          # Production chaos experiments  
curl <NLB_ENDPOINT>/healthz  # "Chaos Edge LIVE"
make destroy             # Clean teardown (2min)
```

## 🏗️ Production Architecture
```
Internet
   ↓
NGINX NLB (AWS ALB/NLB)
   ↓ Ingress Controller
Kubernetes Service (chaos-service)
   ↓
Go Chaos App (3 replicas, port 8080/healthz)
   ↓ Healthchecks + Circuit Breakers
Amazon ECR (chaos-edge-go:latest)
```

## 🎪 Chaos Engineering Experiments

```bash
make chaos-pod-kill      # 🐒 Chaos Monkey: Random pod termination + auto-recovery
make chaos-scale-zero    # 📉 Scale to 0 → auto-recovery (HPA ready)
make chaos-network-loss  # 🌐 Simulate network partition
make chaos-resource-starve # 🧠 CPU/Memory pressure tests
```

## 📁 Repository Structure

```
chaos-edge-devops/
├── terraform/               # IaC (85+ resources)
│   ├── main.tf             # EKS + VPC + NGINX
│   ├── provider.tf         # AWS/K8s/Helm providers
│   └── outputs.tf          # eks_endpoint, cluster_status
├── app/go-service/         # Production Go microservice
│   ├── Dockerfile         # Multi-stage, healthchecks
│   └── main.go            # /healthz + chaos endpoints
├── k8s/                    # Kubernetes manifests
│   ├── deployment.yaml    # 3 replicas, readiness probes
│   ├── service.yaml       # ClusterIP → chaos-service
│   ├── network-policy.yaml # Zero-trust networking
│   └── rbac.yaml          # Least-privilege roles
├── Makefile                # 🔥 One-command automation
├── chaos-demo.sh           # Production chaos patterns
└── fix-chaos-edge.sh       # Troubleshooting automation
```

## 💼 Technical Skills Demonstrated

| **Category** | **Technologies** | **Experience Level** |
|--------------|------------------|---------------------