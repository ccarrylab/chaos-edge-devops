# Create RBAC configuration
cat > k8s/rbac.yaml << 'EOF'
# ServiceAccount for chaos-go application
apiVersion: v1
kind: ServiceAccount
metadata:
  name: chaos-go-sa
  namespace: default
  labels:
    app: chaos-go

---
# Role with minimal required permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: chaos-go-role
  namespace: default
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]

---
# RoleBinding to connect ServiceAccount to Role
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: chaos-go-rolebinding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: chaos-go-role
subjects:
- kind: ServiceAccount
  name: chaos-go-sa
  namespace: default
EOF

# Create NetworkPolicy configuration
cat > k8s/network-policy.yaml << 'EOF'
# Default deny all ingress traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress

---
# Allow ingress from NGINX ingress controller
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-nginx-ingress
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: chaos-go
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: nginx-ingress
    ports:
    - protocol: TCP
      port: 8080

---
# Allow DNS resolution
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
EOF

# Now apply all Kubernetes resources
kubectl apply -f k8s/rbac.yaml
kubectl apply -f k8s/network-policy.yaml

# Verify deployment
kubectl get pods
kubectl get svc
kubectl get sa

echo "✅ Kubernetes resources deployed!"

