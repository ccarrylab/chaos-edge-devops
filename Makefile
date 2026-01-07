.PHONY: help init plan apply config demo test destroy clean validate lint state-backup

# Default target
DEFAULT_GOAL := help

# ================================================================
# COLORS & FORMATTING
# ================================================================
GREEN=\033[0;32m
BLUE=\033[0;34m
YELLOW=\033[0;33m
RED=\033[0;31m
NC=\033[0m  # No Color

# ================================================================
# HELP TARGET
# ================================================================
help:
	@echo "$(BLUE)Chaos Edge DevOps Platform$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@echo "  $(BLUE)init$(NC)         - Initialize Terraform"
	@echo "  $(BLUE)plan$(NC)         - Plan infrastructure changes"
	@echo "  $(BLUE)apply$(NC)        - Deploy infrastructure"
	@echo "  $(BLUE)config$(NC)       - Configure kubectl"
	@echo "  $(BLUE)demo$(NC)         - Deploy demo application"
	@echo "  $(BLUE)test$(NC)         - Test the platform"
	@echo "  $(BLUE)destroy$(NC)      - Destroy all infrastructure"
	@echo "  $(BLUE)clean$(NC)        - Clean local files"
	@echo ""
	@echo "$(GREEN)Validation & Linting:$(NC)"
	@echo "  $(BLUE)validate$(NC)     - Validate Terraform & shell scripts"
	@echo "  $(BLUE)lint$(NC)         - Lint shell scripts (alias for validate)"
	@echo "  $(BLUE)fmt$(NC)          - Format Terraform files"
	@echo ""
	@echo "$(GREEN)State Management:$(NC)"
	@echo "  $(BLUE)state-backup$(NC) - Backup Terraform state"
	@echo "  $(BLUE)state-pull$(NC)   - Pull Terraform state"
	@echo ""

# ================================================================
# TERRAFORM TARGETS
# ================================================================
init:
	@echo "$(GREEN)Initializing Terraform...$(NC)"
	cd terraform && terraform init

plan:
	@echo "$(GREEN)Planning infrastructure changes...$(NC)"
	cd terraform && terraform plan

apply:
	@echo "$(GREEN)Deploying infrastructure...$(NC)"
	cd terraform && terraform apply -auto-approve

# ================================================================
# KUBERNETES CONFIGURATION
# ================================================================
config:
	@echo "$(GREEN)Configuring kubectl...$(NC)"
	aws eks update-kubeconfig --name $$(cd terraform && terraform output -raw cluster_name) --region $$(cd terraform && terraform output -raw region)
	@echo "$(YELLOW)kubectl configured$(NC)"
	kubectl get nodes

# ================================================================
# APPLICATION DEPLOYMENT
# ================================================================
demo:
	@echo "$(GREEN)Deploying demo application...$(NC)"
	kubectl apply -f k8s/demo-app.yaml
	@echo "$(YELLOW)Demo app deployed$(NC)"
	@echo "$(GREEN)Wait 2-3 minutes, then run: make test$(NC)"

# ================================================================
# TESTING & VALIDATION
# ================================================================
validate:
	@echo "$(GREEN)Validating Terraform...$(NC)"
	cd terraform && terraform validate || exit 1
	@echo "$(YELLOW)✓ Terraform valid$(NC)"
	@echo ""
	@echo "$(GREEN)Linting shell scripts...$(NC)"
	@command -v shellcheck >/dev/null 2>&1 || { echo "$(RED)shellcheck not installed$(NC)"; exit 1; }
	shellcheck *.sh || exit 1
	@echo "$(YELLOW)✓ Shell scripts valid$(NC)"
	@echo ""
	@echo "$(GREEN)Validating Kubernetes manifests...$(NC)"
	@for f in k8s/*.yaml; do \
		echo "  Checking $$f..."; \
		kubectl apply --dry-run=client -f $$f || exit 1; \
	done
	@echo "$(YELLOW)✓ Kubernetes manifests valid$(NC)"

lint: validate

fmt:
	@echo "$(GREEN)Formatting Terraform files...$(NC)"
	cd terraform && terraform fmt -recursive .

test:
	@echo "$(GREEN)Testing platform...$(NC)"
	@CLOUDFRONT_URL=$$(cd terraform && terraform output -raw cloudfront_domain) && \
	if [ -z "$$CLOUDFRONT_URL" ]; then \
		echo "$(RED)CloudFront URL not found. Run 'make apply' first.$(NC)"; \
		exit 1; \
	fi && \
	echo "$(YELLOW)Testing CloudFront: https://$$CLOUDFRONT_URL$(NC)" && \
	curl -s https://$$CLOUDFRONT_URL | head -20 || echo "$(YELLOW)CloudFront still propagating...$(NC)"

# ================================================================
# STATE MANAGEMENT
# ================================================================
state-backup:
	@echo "$(GREEN)Backing up Terraform state...$(NC)"
	@TIMESTAMP=$$(date +%Y%m%d_%H%M%S) && \
	cd terraform && \
	terraform state pull > ../backup_tfstate_$$TIMESTAMP.json && \
	echo "$(YELLOW)State backed up to: backup_tfstate_$$TIMESTAMP.json$(NC)"

state-pull:
	@echo "$(GREEN)Pulling Terraform state...$(NC)"
	cd terraform && terraform state pull

# ================================================================
# CLEANUP
# ================================================================
destroy:
	@echo "$(RED)WARNING: This will destroy ALL infrastructure!$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to cancel, or wait 5 seconds...$(NC)"
	@sleep 5
	cd terraform && terraform destroy

clean:
	@echo "$(GREEN)Cleaning local files...$(NC)"
	cd terraform && rm -rf .terraform* *.tfstate* .lock.hcl
	rm -f backup_tfstate_*.json
	@echo "$(YELLOW)✓ Local files cleaned$(NC)"
