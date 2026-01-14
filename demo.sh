#!/bin/bash
echo "🚀 Chaos Edge DevOps - COMPLETE 90-SECOND DEMO"
echo "=================================================="

echo "🔧 1/5: Setup development tools..."
make dev-setup

echo "🚀 2/5: Update kubeconfig..."
make quick-start

echo "🧪 3/5: Run chaos experiments..."
make chaos-demo

echo "📊 4/5: Install Prometheus + Grafana monitoring..."
make monitoring-install

echo "🎯 5/5: Access live dashboards..."
echo ""
echo "✅ COMPLETE! Open these URLs:"
echo ""
echo "   Grafana Dashboards: http://localhost:3000"
echo "       admin / chaosedge2026"
echo ""
echo "   Prometheus UI:     http://localhost:9090"
echo ""
echo "💡 In another terminal, run:"
echo "   make observability-demo  # Grafana"
echo "   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090  # Prometheus"
echo ""
echo "🎉 Chaos Edge DevOps demo ready for interviews!"
