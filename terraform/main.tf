terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

resource "null_resource" "create_k3d_cluster" {
  provisioner "local-exec" {
    command = <<EOT
      k3d cluster create k3d-${var.env_name} \
        --api-port ${var.api_port} \
        --port "${var.loadbalancer_port}:443@loadbalancer" \
        --wait \
        --k3s-arg "--kubelet-arg=feature-gates=KubeletInUserNamespace=true@server:0"
    EOT
  }
}

resource "null_resource" "setup_dashboard" {
  depends_on = [null_resource.create_k3d_cluster]
  provisioner "local-exec" {
    command = "ENV_NAME=${var.env_name} bash ./scripts/dashboard.sh"
    working_dir = path.module
  }
}

# Output important information
output "cluster_name" {
  description = "Name of the created K3D cluster"
  value       = "k3d-${var.env_name}"
}

output "dashboard_url" {
  description = "Kubernetes Dashboard URL"
  value       = "https://localhost:30443"
}

output "api_server_url" {
  description = "Kubernetes API server URL"
  value       = "https://localhost:${var.api_port}"
}

output "loadbalancer_port" {
  description = "LoadBalancer port for applications"
  value       = var.loadbalancer_port
}

# Create a local script to get dashboard token
resource "local_file" "get_token_script" {
  depends_on = [null_resource.setup_dashboard]
  content = <<-EOT
#!/bin/bash
echo "Getting Kubernetes Dashboard token..."
kubectl config use-context k3d-${var.env_name}
kubectl -n kubernetes-dashboard create token admin-user
EOT
  filename = "${path.module}/scripts/get-dashboard-token.sh"
  file_permission = "0755"
}

# Create a monitoring script
resource "local_file" "monitor_script" {
  depends_on = [null_resource.setup_dashboard]
  content = <<-EOT
#!/bin/bash
echo "=== K3D Cluster Status ==="
echo "Cluster: k3d-${var.env_name}"
kubectl config use-context k3d-${var.env_name}
echo ""
echo "Nodes:"
kubectl get nodes
echo ""
echo "Pods by namespace:"
kubectl get pods --all-namespaces
echo ""
echo "Services:"
kubectl get services --all-namespaces
echo ""
echo "Resource usage (if metrics-server is ready):"
kubectl top nodes 2>/dev/null || echo "Metrics not available yet"
kubectl top pods --all-namespaces 2>/dev/null || echo "Pod metrics not available yet"
EOT
  filename = "${path.module}/scripts/cluster-status.sh"
  file_permission = "0755"
}
