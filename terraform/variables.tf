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