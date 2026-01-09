# Infrastructure Cost Analysis

## Monthly Cost: $216 (Optimized)

### Detailed Breakdown

| Component | Specs | Hours/Mo | Rate | Monthly Cost |
|-----------|-------|----------|------|--------------|
| **EKS Control Plane** | Managed K8s | 730 | $0.10/hr | $73.00 |
| **EC2 t3.medium** (2x) | 2 vCPU, 4GB RAM | 1460 | $0.0416/hr | $60.74 |
| **NAT Gateway** | Single AZ | 730 | $0.045/hr | $32.85 |
| **ALB** | Application LB | 730 | $0.0225/hr | $16.43 |
| **EBS gp3** (200GB) | 100GB x 2 | - | $0.08/GB | $16.00 |
| **Data Transfer** | ~50GB egress | - | Variable | $10.00 |
| **TOTAL** | | | | **$216.02** |

### Cost Optimization Scenarios

**Development (55% savings)**
- Single t3.small node: $98/month
- Off-hours shutdown: Additional 40% savings
- Spot instances: Additional 70% discount

**Production (37% savings)**
- Reserved Instances (1-year): $137/month
- VPC Endpoints: -$10/month
- Optimized EBS: -$8/month

[Full analysis →](docs/cost-comparison.md)
