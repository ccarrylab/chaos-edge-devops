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
- shellcheck (for script validation)

## 🚀 Quick Start

### Using Make Targets (Recommended)

```bash
# Initialize Terraform
make init

# Plan changes
make plan

# Deploy infrastructure
make apply

# Configure kubectl
make config

# Deploy demo app
make demo

# Test the platform
make test

# Validate everything
make validate

# Get help
make help
