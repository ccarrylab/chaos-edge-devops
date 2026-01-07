.PHONY: help init plan apply destroy demo clean

help:
	@echo "Chaos Edge DevOps Platform"
	@echo ""
	@echo "Available targets:"
	@echo "  init     - Initialize Terraform"
	@echo "  plan     - Plan infrastructure changes"
	@echo "  apply    - Deploy infrastructure"
	@echo "  config   - Configure kubectl"
	@echo "  demo     - Deploy demo application"
	@echo "  test     - Test the platform"
	@echo "  destroy  - Destroy all infrastructure"
	@echo "  clean    - Clean local files"

init:
	cd terraform && terraform init

plan:
	cd terraform && terraform plan

apply:
	cd terraform && terraform apply

config:
	@cd terraform && aws eks update-kubeconfig --name $$(terraform output -raw cluster_name) --region $$(terraform output -raw region)
	@echo "✅ kubectl configured"
	@kubectl get nodes

demo:
	kubectl apply -f demo/demo-app.yaml
	@echo "✅ Demo app deployed"
	@echo "Wait 2-3 minutes, then run: make test"

test:
	@echo "Testing platform..."
	@curl -s https://$$(cd terraform && terraform output -raw cloudfront_domain) || echo "⏳ CloudFront still propagating..."

destroy:
	cd terraform && terraform destroy

clean:
	cd terraform && rm -rf .terraform *.tfstate*
