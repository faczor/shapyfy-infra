terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

resource "null_resource" "cleanup_server" {
  provisioner "local-exec" {
    command = <<EOT
      ssh -p ${var.server_port} ${var.server_user}@${var.server_host} "
        echo 'Cleaning up existing k3d clusters...'
        k3d cluster delete --all 2>/dev/null || true
        echo 'Cleaning up Docker resources...'
        docker system prune -af
        echo 'Removing kubectl config...'
        rm -rf /root/.kube
        echo 'Removing temporary k3d files...'
        rm -rf /tmp/k3d-*
        echo 'Server cleanup completed!'
      "
    EOT
  }
}

resource "null_resource" "create_k3d_cluster" {
  depends_on = [null_resource.cleanup_server]

  provisioner "local-exec" {
    command = <<EOT
      ssh -p ${var.server_port} ${var.server_user}@${var.server_host} "
        k3d cluster create k3d-${var.env_name} \
          --api-port ${var.api_port} \
          --port '${var.loadbalancer_port}:443@loadbalancer' \
          --port '30247:30247@server:0' \
          --wait \
          --k3s-arg '--kubelet-arg=feature-gates=KubeletInUserNamespace=true@server:0'
      "
    EOT
  }
}

output "cluster_name" {
  description = "Name of the created K3D cluster"
  value       = "k3d-${var.env_name}"
}

output "api_server_url" {
  description = "Kubernetes API server URL"
  value       = "https://localhost:${var.api_port}"
}

output "loadbalancer_port" {
  description = "LoadBalancer port for applications"
  value       = var.loadbalancer_port
}
