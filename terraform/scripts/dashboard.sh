#!/bin/bash

set -e

CLUSTER_NAME="k3d-${ENV_NAME}"

echo "Setting up Kubernetes Dashboard for cluster: ${CLUSTER_NAME}"

# Set kubeconfig context
kubectl config use-context ${CLUSTER_NAME}

# Create dashboard namespace
kubectl create namespace kubernetes-dashboard --dry-run=client -o yaml | kubectl apply -f -

# Deploy Kubernetes Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create service account for dashboard access
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Wait for dashboard to be ready
kubectl wait --for=condition=available --timeout=300s deployment/kubernetes-dashboard -n kubernetes-dashboard

# Create a service to expose the dashboard
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: kubernetes-dashboard-nodeport
  namespace: kubernetes-dashboard
spec:
  type: NodePort
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30443
      protocol: TCP
  selector:
    k8s-app: kubernetes-dashboard
EOF

# Get the service account token
TOKEN=$(kubectl -n kubernetes-dashboard create token admin-user)

echo "=================================="
echo "Kubernetes Dashboard Setup Complete!"
echo "=================================="
echo "Dashboard URL: https://localhost:30443"
echo "Token: ${TOKEN}"
echo ""
echo "To access the dashboard:"
echo "1. Navigate to https://localhost:30443"
echo "2. Select 'Token' authentication"
echo "3. Paste the token above"
echo "=================================="

# Deploy metrics-server for resource monitoring
echo "Deploying metrics-server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch metrics-server for k3d compatibility
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }
]'

# Wait for metrics-server to be ready
kubectl wait --for=condition=available --timeout=300s deployment/metrics-server -n kube-system

echo "Metrics server deployed successfully!"

# Deploy a simple monitoring dashboard with Grafana (optional)
echo "Setting up basic monitoring stack..."

# Create monitoring namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Deploy a simple resource monitor pod
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-monitor
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cluster-monitor
  template:
    metadata:
      labels:
        app: cluster-monitor
    spec:
      containers:
      - name: monitor
        image: busybox
        command: ['sh', '-c']
        args:
        - |
          while true; do
            echo "=== Cluster Status at $(date) ==="
            echo "Nodes:"
            kubectl get nodes --no-headers | wc -l
            echo "Pods:"
            kubectl get pods --all-namespaces --no-headers | wc -l
            echo "Services:"
            kubectl get services --all-namespaces --no-headers | wc -l
            echo "Deployments:"
            kubectl get deployments --all-namespaces --no-headers | wc -l
            sleep 60
          done
        volumeMounts:
        - name: kubectl-config
          mountPath: /root/.kube
      volumes:
      - name: kubectl-config
        hostPath:
          path: /root/.kube
      serviceAccountName: cluster-monitor-sa
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cluster-monitor-sa
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-monitor-binding
subjects:
- kind: ServiceAccount
  name: cluster-monitor-sa
  namespace: monitoring
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
EOF

echo "Monitoring setup complete!"
echo ""
echo "To view cluster metrics:"
echo "kubectl top nodes"
echo "kubectl top pods --all-namespaces"
echo ""
echo "To view monitor logs:"
echo "kubectl logs -n monitoring deployment/cluster-monitor -f"