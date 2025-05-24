variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "image" {
  description = "The Docker image to deploy for the devsu app"
  type        = string
}

variable "replicas" {
  description = "Number of replicas for the devsu app"
  type        = number
  default     = 2
}