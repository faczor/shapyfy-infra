variable "env_name" {
  description = "Nazwa środowiska (np. dev, stage, prod)"
  type        = string
}

variable "api_port" {
  type    = number
  default = 6443
}

variable "loadbalancer_port" {
  type    = number
  default = 20247
}

variable "server_host" {
  description = "Server hostname or IP address"
  type        = string
}

variable "server_port" {
  description = "SSH port for server connection"
  type        = number
  default     = 22
}

variable "server_user" {
  description = "SSH username for server connection"
  type        = string
  default     = "root"
}