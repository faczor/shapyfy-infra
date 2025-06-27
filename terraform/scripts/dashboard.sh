#!/bin/bash

set -e

# Get the environment name from terraform variable or use default
ENV_NAME=${ENV_NAME:-dev}

# Update kubeconfig for k3d cluster and set context
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