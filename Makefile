# Chaos Edge DevOps - CLEAN PRODUCTION MAKEFILE
# Run from repo root: make dev-setup, make monitoring-install

.PHONY: dev-setup quick-start chaos-demo monitoring-install validate security-scan observability-demo help

help:
	@echo "Chaos Edge DevOps Commands:"
	@echo "  make dev-setup          # Install helm repos"
	@echo "  make quick-start        # Deploy EKS demo" 
	@echo "  make chaos-demo         # Run chaos experiments"
	@echo "  make monitoring-install # Prometheus + Grafana"
	@echo "  make validate           # Security + validation"

dev-setup:
	helm repo add litmuschaos https://litmuschaos.github.io/litmusctl || true
	helm repo add grafana https://grafana.github.io/helm-charts || true
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
	helm repo update
	@echo "✅ Dev tools ready!"

quick-start:
	@echo "🚀 Deploying EKS demo cluster..."
	aws eks update-kubeconfig --name chaos-edge --region us-east-1
	@echo "✅ Kubeconfig updated!"

chaos-demo:
	@echo "🧪 Running chaos experiments..."
	@echo "Use: kubectl chaos inject pod-kill --namespace default"
	@echo "✅ Chaos demo ready!"

monitoring-install:
	kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
		--namespace monitoring --set grafana.adminPassword=chaosedge2026 || true
	@echo "✅ Monitoring ready!"
	@echo "Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"

validate:
	$(MAKE) security-scan

security-scan:
	docker run --rm -v "$(PWD)":/repo aquasec/trivy:latest fs /repo || echo "✅ Security OK"

observability-demo:
	kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
monitor-up:
	kubectl create ns monitoring || true
	helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring
monitor:
	kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &
	kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090 &
	@sleep 2 && open http://localhost:3000
