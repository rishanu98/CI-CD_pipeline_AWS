provider "kubernetes" {
  host = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data) # letting Terraform (specifically the Kubernetes/Helm providers) trust and authenticate to your EKS cluster's API server
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

locals {
  cluster_name = "vprofile-eks-${random_string.suffix.result}"
}