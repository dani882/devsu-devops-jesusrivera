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

variable "app_port" {
  description = "Port for the devsu app"
  type        = number
  default     = 8000

}

variable "service_port" {
  description = "Port for the Kubernetes service"
  type        = number
  default     = 80

}
variable "replicas" {
  description = "Number of replicas for the devsu app"
  type        = number
  default     = 2
}
variable "min_replicas" {
  description = "Minimum number of replicas for the devsu app"
  type        = number
  default     = 2
}

variable "max_replicas" {
  description = "Maximum number of replicas for the devsu app"
  type        = number
  default     = 5
}

variable "database_name" {
  description = "Name of the database for the devsu app"
  type        = string
  default     = "db.sqlite3"
}

variable "django_secret_key" {
  description = "Django secret key for the devsu app"
  type        = string
  default     = "django-insecure-wc2i2*6^17$9!u+(u66@q_rg)++n1x-^(0-$3yz2f(n=_-o*7="
  sensitive   = true
}