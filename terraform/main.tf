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
  }
}
