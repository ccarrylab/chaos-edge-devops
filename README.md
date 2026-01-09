# 🚀 Chaos Edge DevOps - Production-Ready EKS Infrastructure

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.30-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/eks/)
[![CI](https://github.com/ccarrylab/chaos-edge-devops/workflows/CI/badge.svg)](https://github.com/ccarrylab/chaos-edge-devops/actions)
[![Security](https://img.shields.io/badge/Security-95%2F100-brightgreen)](docs/security/scan-results.md)
[![Cost](https://img.shields.io/badge/Cost-$216%2Fmo-blue)](docs/cost-comparison.md)

> **Enterprise-grade AWS EKS infrastructure demonstrating production DevOps practices**

[📖 Docs](docs/) | [🏗️ Architecture](docs/architecture/) | [💰 Cost Analysis](docs/cost-comparison.md) | [🔒 Security](docs/security/scan-results.md)

---

## ✨ What Makes This Special

- ⚡ **15-minute deployment** from zero to production
- 🎯 **95/100 security score** with automated scanning
- 💰 **37% cost savings** vs AWS baseline ($216/month)
- 🌀 **Chaos tested** - survived 15+ failure scenarios
- 📊 **Full observability** with Prometheus + Grafana
- 🤖 **100% automated** with 40+ make commands

## �� Real-World Impact

| Metric | Value |
|--------|-------|
| **Deployment Time** | 15 minutes (vs 3 days manual) |
| **Cost Optimization** | 37% below AWS baseline |
| **Monthly Time Saved** | 49 hours in operations |
| **Uptime During Tests** | 99.7% (under combined stress) |
| **Security Score** | 95/100 (production-ready) |
| **Test Coverage** | 15+ chaos experiments |

## 🚀 Quick Start
```bash
# 1. Clone and setup
git clone https://github.com/ccarrylab/chaos-edge-devops.git
cd chaos-edge-devops
make setup

# 2. Deploy (15 minutes)
make quick-start

# 3. Done! 🎉
```

## 💰 Cost Breakdown

**Total: $216/month**

| Component | Cost | Optimization |
|-----------|------|--------------|
| EKS Control Plane | $73 | Fixed |
| EC2 (2x t3.medium) | $61 | Can reduce 50% |
| NAT Gateway | $33 | Already optimized |
| Load Balancer | $23 | Required |
| Storage | $16 | Can reduce 50% |

**Development**: Reduce to $98/month (55% savings)  
**Production**: Optimize to $137/month (37% savings)

[Complete cost analysis →](docs/cost-comparison.md)

## 🏆 Chaos Engineering Results

| Test | Duration | Result | Impact |
|------|----------|--------|--------|
| Pod Failure | 5 min | ✅ | 0% downtime |
| Network Latency | 2 min | ✅ | +107ms response |
| CPU Stress | 3 min | ✅ | Auto-scaled |
| Combined Stress | 5 min | ✅ | 99.7% uptime |

**Resilience Score: 96/100** 🛡️

[View detailed results →](docs/chaos-results/README.md)

## 🎯 Skills Demonstrated

**Infrastructure & Cloud**  
☁️ AWS (EKS, VPC, IAM, ALB, CloudWatch)  
🏗️ Terraform (IaC, modules, state management)  
🔧 Multi-AZ high availability architecture

**Kubernetes & Containers**  
⎈ Kubernetes 1.30 (deployments, services, RBAC)  
🐳 Docker (multi-stage builds, security)  
📦 Helm (package management)

**Observability & Testing**  
📊 Prometheus + Grafana monitoring  
🌀 Chaos Engineering (Chaos Mesh)  
🧪 Automated testing in CI/CD

**DevOps & Automation**  
🤖 GitHub Actions CI/CD  
⚙️ Make-based automation (40+ commands)  
📖 Technical documentation

**Security**  
🔒 Security scanning (Checkov, Trivy)  
🛡️ RBAC, Network Policies  
🔐 Secrets management (KMS)

## 📖 Documentation

- [Getting Started Guide](docs/guides/getting-started.md)
- [Lessons Learned](docs/lessons-learned.md) - Real implementation insights
- [Cost Comparison](docs/cost-comparison.md) - Detailed analysis
- [Chaos Results](docs/chaos-results/README.md) - Test outcomes
- [Security Audit](docs/security/scan-results.md) - 95/100 score
- [Troubleshooting](docs/guides/troubleshooting.md)

## 🛠️ Commands
```bash
make help              # Show all commands
make quick-start       # Complete deployment
make chaos-demo        # Run chaos experiments
make monitoring-install # Install Grafana
make cost-estimate     # Show monthly costs
```

## 🔒 Security

✅ **95/100 Security Score**  
✅ Zero critical vulnerabilities  
✅ RBAC + Network Policies  
✅ Automated scanning in CI/CD  
✅ KMS-encrypted secrets  
✅ Non-root containers

[View security audit →](docs/security/scan-results.md)

## 📬 Contact

**Cohen H. Carryl** - Senior DevOps Engineer

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?logo=linkedin)](https://www.linkedin.com/in/cohen-h-carryl-3538b614/)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-black?logo=github)](https://github.com/ccarrylab)

---

**⭐ Star if you find this helpful!**

*Built with ❤️ for the DevOps community*
