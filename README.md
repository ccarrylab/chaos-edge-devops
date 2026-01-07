# 🌐 Chaos Edge DevOps Platform

**Terraform‑driven AWS EKS platform with NGINX Ingress and a chaos‑ready Go service.**  
Built to answer the question every senior DevOps / Cloud interview eventually asks:

> “Show me something real you’ve built that you can break, debug, and improve.”

This repo is your answer.

---

## ⚡ What makes this different

Most “EKS examples” stop at “cluster is up.”  
This project goes further:

- **Realistic architecture, not just a hello world**
  - VPC with public & private subnets
  - EKS 1.30 with managed node groups and IRSA
  - NGINX Ingress Controller exposed via AWS NLB
  - Go service behind Kubernetes `Service` and `Ingress`
- **Chaos‑aware endpoints**
  - `/healthz` – basic health
  - `/chaos/latency` – injects artificial latency
  - `/chaos/fail` – injects failures
- **Everything as code**
  - VPC, EKS, ingress, workloads all managed by Terraform
  - No “click it in the console and forget what you did”
- **Demo‑optimized**
  - You can clone this live on a call, `terraform apply`, and walk someone through:
    - How requests flow
    - How failures manifest
    - How you’d observe and fix them

This is a **mini production story**, not just infrastructure.

---

## 🧱 Architecture: from the internet to a pod

**Traffic flow (after deployment):**

```text
Client (curl / browser)
  │
  ▼
AWS Network Load Balancer
  (created by NGINX Service type=LoadBalancer)
  │
  ▼
NGINX Ingress Controller (ingress-nginx Helm chart)
  │
  ▼
Kubernetes Service (ClusterIP, chaos-service)
  │
  ▼
Go Chaos App Pods (chaos-app Deployment)
## LIVE DEMO  
NLB: http://ade3956ce43bb495ba2f778bbac01145-214289985.us-east-1.elb.amazonaws.com  
EKS: chaos-edge (ACTIVE)
