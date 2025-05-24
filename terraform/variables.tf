variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "app_name" {
  description = "Name of the devsu app"
  type        = string
  default     = "devsu"
}
variable "image" {
  description = "The Docker image to deploy for the devsu app"
  type        = string
}

variable "port" {
  description = "Port for the devsu app"
  type        = number
  default     = 8000

}

variable "replicas" {
  description = "Number of replicas for the devsu app"
  type        = number
  default     = 2
}
