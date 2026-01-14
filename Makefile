SHELL := /usr/bin/env bash

.PHONY: help init plan apply destroy test clean format validate security-scan cost-estimate

# Variables
AWS_REGION ?= us-east-1
CLUSTER_NAME ?= chaos-edge
TF_DIR = terraform

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo '$(BLUE)Chaos Edge DevOps - Available Commands$(NC)'
	@echo ''
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make $(GREEN)<target>$(NC)\n\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

##@ Infrastructure Management

init: ## Initialize Terraform
	@echo '$(BLUE)Initializing Terraform...$(NC)'
	cd $(TF_DIR) && terraform init

plan: ## Plan Terraform changes
	@echo '$(BLUE)Planning infrastructure changes...$(NC)'
	cd $(TF_DIR) && terraform plan

apply: ## Apply Terraform changes
	@echo '$(YELLOW)Applying infrastructure changes...$(NC)'
	cd $(TF_DIR) && terraform apply

destroy: ## Destroy infrastructure
	@echo '$(RED)WARNING: This will destroy all infrastructure!$(NC)'
	@read -p "Are you sure? Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ] || exit 1
	cd $(TF_DIR) && terraform destroy

refresh: ## Refresh Terraform state
	@echo '$(BLUE)Refreshing Terraform state...$(NC)'
	cd $(TF_DIR) && terraform refresh

##@ Kubernetes Operations

kubeconfig: ## Update kubectl configuration
	@echo '$(BLUE)Updating kubeconfig...$(NC)'
	aws eks update-kubeconfig --name $(CLUSTER_NAME) --region $(AWS_REGION)

k8s-deploy: kubeconfig ## Deploy Kubernetes resources
	@echo '$(BLUE)Deploying Kubernetes resources...$(NC)'
	kubectl apply -k k8s/base/

k8s-status: kubeconfig ## Check cluster status
	@echo '$(BLUE)Cluster Status:$(NC)'
	@kubectl get nodes
	@echo '\n$(BLUE)Pods Status:$(NC)'
	@kubectl get pods --all-namespaces

pods: kubeconfig ## Show all pods
	@kubectl get pods --all-namespaces -o wide

services: kubeconfig ## Show all services
	@kubectl get svc --all-namespaces

ingress: kubeconfig ## Show ingress resources
	@kubectl get ingress --all-namespaces

##@ Application Deployment

app-build: ## Build Go application
	@echo '$(BLUE)Building Go application...$(NC)'
	cd app/go-service && docker build -t chaos-edge-app:latest .

app-push: ## Push image to ECR
	@echo '$(BLUE)Pushing image to ECR...$(NC)'
	@./scripts/push-to-ecr.sh

app-deploy: app-push ## Deploy application to cluster
	@echo '$(BLUE)Deploying application...$(NC)'
	kubectl apply -f k8s/base/

##@ Testing & Validation

test: terraform-test k8s-test ## Run all tests
	@echo '$(GREEN)All tests passed!$(NC)'

terraform-test: ## Test Terraform configuration
	@echo '$(BLUE)Testing Terraform...$(NC)'
	cd $(TF_DIR) && terraform fmt -check
	cd $(TF_DIR) && terraform validate

k8s-test: ## Test Kubernetes manifests
	@echo '$(BLUE)Testing Kubernetes manifests...$(NC)'
	@for file in k8s/base/*.yaml; do \
		kubectl apply --dry-run=client -f $$file; \
	done

integration-test: kubeconfig ## Run integration tests
	@echo '$(BLUE)Running integration tests...$(NC)'
	@./scripts/integration-tests.sh

##@ Code Quality

format: ## Format all code
	@echo '$(BLUE)Formatting code...$(NC)'
	cd $(TF_DIR) && terraform fmt -recursive
	cd app/go-service && go fmt ./...

validate: ## Validate all configurations
	@echo '$(BLUE)Validating configurations...$(NC)'
	cd $(TF_DIR) && terraform validate
	@yamllint k8s/

lint: ## Lint Terraform code
	@echo '$(BLUE)Linting Terraform...$(NC)'
	@command -v tflint >/dev/null 2>&1 || { echo "tflint not installed. Install: brew install tflint"; exit 1; }
	cd $(TF_DIR) && tflint

security-scan: ## Run security scans
	@echo '$(BLUE)Running security scans...$(NC)'
	@command -v checkov >/dev/null 2>&1 || { echo "checkov not installed. Install: pip install checkov"; exit 1; }
	checkov -d $(TF_DIR) --quiet

trivy-scan: ## Scan Docker images for vulnerabilities
	@echo '$(BLUE)Scanning Docker images...$(NC)'
	@command -v trivy >/dev/null 2>&1 || { echo "trivy not installed. Install: brew install trivy"; exit 1; }
	trivy image chaos-edge-app:latest

##@ Chaos Engineering

chaos-install: kubeconfig ## Install Chaos Mesh
	@echo '$(BLUE)Installing Chaos Mesh...$(NC)'
	@./scripts/install-chaos-mesh.sh

chaos-pod-failure: kubeconfig ## Simulate pod failures
	@echo '$(YELLOW)Running pod failure experiment...$(NC)'
	kubectl apply -f k8s/chaos-mesh/pod-failure.yaml

chaos-network-latency: kubeconfig ## Inject network latency
	@echo '$(YELLOW)Running network latency experiment...$(NC)'
	kubectl apply -f k8s/chaos-mesh/network-latency.yaml

chaos-cpu-stress: kubeconfig ## CPU stress test
	@echo '$(YELLOW)Running CPU stress experiment...$(NC)'
	kubectl apply -f k8s/chaos-mesh/cpu-stress.yaml

chaos-demo: ## Run all chaos experiments
	@echo '$(YELLOW)Running comprehensive chaos demo...$(NC)'
	@./scripts/chaos-demo.sh

chaos-cleanup: kubeconfig ## Clean up chaos experiments
	@echo '$(BLUE)Cleaning up chaos experiments...$(NC)'
	kubectl delete -f k8s/chaos-mesh/ --ignore-not-found=true

##@ Monitoring

monitoring-install: kubeconfig ## Install monitoring stack
	@echo '$(BLUE)Installing Prometheus & Grafana...$(NC)'
	@./scripts/install-monitoring.sh

grafana-forward: kubeconfig ## Port-forward Grafana
	@echo '$(GREEN)Grafana available at http://localhost:3000$(NC)'
	kubectl port-forward -n monitoring svc/grafana 3000:80

prometheus-forward: kubeconfig ## Port-forward Prometheus
	@echo '$(GREEN)Prometheus available at http://localhost:9090$(NC)'
	kubectl port-forward -n monitoring svc/prometheus 9090:9090

dashboard: ## Open Grafana in browser
	@open http://localhost:3000 || xdg-open http://localhost:3000

##@ Cost Management

cost-estimate: ## Estimate AWS costs
	@echo '$(BLUE)Estimating AWS costs...$(NC)'
	@command -v infracost >/dev/null 2>&1 || { echo "infracost not installed. Install: brew install infracost"; exit 1; }
	cd $(TF_DIR) && infracost breakdown --path .

cost-report: ## Generate cost report
	@echo '$(BLUE)Generating cost report...$(NC)'
	@./scripts/cost-report.sh

##@ Utilities

logs: kubeconfig ## Tail application logs
	@kubectl logs -f -n chaos-edge -l app=chaos-app --tail=100

shell: kubeconfig ## Get shell in a pod
	@kubectl exec -it -n chaos-edge deployment/chaos-app -- /bin/sh

clean: ## Clean up temporary files
	@echo '$(BLUE)Cleaning up...$(NC)'
	find . -name '.terraform' -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name '*.tfstate*' -type f -delete 2>/dev/null || true
	find . -name '.terraform.lock.hcl' -type f -delete 2>/dev/null || true

setup: ## Initial setup and prerequisites check
	@echo '$(BLUE)Checking prerequisites...$(NC)'
	@./scripts/check-prerequisites.sh
	@echo '$(GREEN)Setup complete!$(NC)'

docs: ## Serve documentation locally
	@echo '$(BLUE)Serving documentation at http://localhost:8000$(NC)'
	@command -v mkdocs >/dev/null 2>&1 || { echo "mkdocs not installed. Install: pip install mkdocs"; exit 1; }
	mkdocs serve

##@ CI/CD

ci-validate: ## Run CI validation locally
	@echo '$(BLUE)Running CI validation...$(NC)'
	@act -j validate 2>/dev/null || echo "$(YELLOW)Install 'act' to run GitHub Actions locally: brew install act$(NC)"

##@ Quick Start

quick-start: setup init apply kubeconfig k8s-status ## Complete quick start deployment
	@echo '$(GREEN)========================================$(NC)'
	@echo '$(GREEN)Deployment complete!$(NC)'
	@echo '$(GREEN)========================================$(NC)'
	@echo ''
	@echo 'Next steps:'
	@echo '  1. Check cluster: make k8s-status'
	@echo '  2. View application: make services'
	@echo '  3. Install monitoring: make monitoring-install'
	@echo '  4. Run chaos demo: make chaos-demo'
	@echo ''

.DEFAULT_GOAL := help
# Production Commands
observability-demo:
	@echo "📊 Deploying Chaos Dashboards..."
	@helm upgrade --install monitoring grafana/grafana -n monitoring --create-namespace
	@echo "✅ Grafana: kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80"

validate:
	@make security-scan terraform-validate

security-scan:
	@docker run --rm -v "$(PWD)":/work aquasec/trivy fs /work
