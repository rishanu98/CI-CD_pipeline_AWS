variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "kubernetes_version" {
  default     = "1.27"
  description = "kubernetes version"
}