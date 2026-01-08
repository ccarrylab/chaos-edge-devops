# 🚀 Chaos Edge DevOps - Production-Ready EKS Infrastructure

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.30-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/eks/)
[![CI](https://github.com/ccarrylab/chaos-edge-devops/workflows/CI/badge.svg)](https://github.com/ccarrylab/chaos-edge-devops/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Enterprise-grade AWS EKS infrastructure with chaos engineering, observability, and GitOps best practices**

[📖 Documentation](docs/) | [🏗️ Architecture](docs/architecture/) | [🚀 Quick Start](#-quick-start)

---

## ✨ Highlights

This repository showcases **production-ready DevOps practices** through a complete AWS EKS deployment with advanced features.

### 🎯 Key Features

- **Infrastructure as Code**: Complete EKS cluster provisioning with Terraform
- **Chaos Engineering**: Pre-configured Chaos Mesh experiments for resilience testing
- **Observability Stack**: Prometheus + Grafana monitoring
- **Security Best Practices**: RBAC, Network Policies, Pod Security Standards
- **GitOps Ready**: GitHub Actions CI/CD pipelines
- **Cost Optimized**: ~$200/month with optimization guide
- **Production Ingress**: NGINX Ingress Controller with AWS Load Balancer

## 🚀 Quick Start
```bash
# 1. Clone and setup
git clone https://github.com/ccarrylab/chaos-edge-devops.git
cd chaos-edge-devops
make setup

# 2. Deploy infrastructure
make init
make apply  # Takes ~15 minutes

# 3. Configure kubectl
make kubeconfig

# 4. Verify
make k8s-status
```

## 💰 Cost Breakdown (~$216/month)

| Component | Monthly Cost |
|-----------|--------------|
| EKS Control Plane | $73 |
| EC2 (2x t3.medium) | $61 |
| NAT Gateway | $33 |
| Load Balancer | $23 |
| EBS Volumes | $16 |

[See cost optimization guide](docs/guides/cost-optimization.md) to reduce by 60%

## 📖 Documentation

- [Getting Started](docs/guides/getting-started.md)
- [Architecture](docs/architecture/README.md)
- [Troubleshooting](docs/guides/troubleshooting.md)
- [Chaos Engineering](docs/tutorials/chaos-experiments.md)
- [Monitoring Setup](docs/tutorials/monitoring-setup.md)

## 🛠️ Commands
```bash
make help              # Show all commands
make quick-start       # Complete deployment
make chaos-demo        # Run chaos experiments
make monitoring-install # Install Prometheus & Grafana
```

## 📬 Contact

**Cohen H. Carryl** - Senior DevOps Engineer

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?style=flat&logo=linkedin)](https://www.linkedin.com/in/cohen-h-carryl-3538b614/)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-black?style=flat&logo=github)](https://github.com/ccarrylab)

---

**⭐ Star this repo if you find it helpful!**

**Built with ❤️ by DevOps Engineers, for DevOps Engineers**
