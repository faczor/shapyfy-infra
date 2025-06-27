#!/bin/bash

set -e

# Get the environment name from terraform variable or use default
ENV_NAME=${ENV_NAME:-dev}

# Check if k3d cluster exists
echo "Checking if k3d cluster k3d-${ENV_NAME} exists..."
if ! k3d cluster list | grep -q "k3d-${ENV_NAME}"; then
  echo "ERROR: k3d cluster k3d-${ENV_NAME} not found!"
  echo "Available clusters:"
  k3d cluster list
  exit 1
fi

# Update kubeconfig for k3d cluster and set context
echo "Updating kubeconfig for k3d-${ENV_NAME}..."
k3d kubeconfig merge k3d-${ENV_NAME} --kubeconfig-switch-context

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml --validate=false --insecure-skip-tls-verify

cat <<EOF | kubectl apply -f - --insecure-skip-tls-verify
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
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard \
  -p '{"spec": {"type": "LoadBalancer", "ports": [{"port": 443, "targetPort": 8443}]}}' --insecure-skip-tls-verify

# Verify dashboard deployment
echo "Checking dashboard deployment status..."
kubectl get pods -n kubernetes-dashboard --insecure-skip-tls-verify