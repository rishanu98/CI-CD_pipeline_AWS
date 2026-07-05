provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
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

# IAM role
resource "aws_iam_role" "ebs_csi" {
  name = "AmazonEKS_EBS_CSI_DriverRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Action    = "sts:AssumeRoleWithWebIdentity" # this is different than the standard "sts:AssumeRole" action, which is used for IAM users and roles. it is specifically for exchanging a web identity token for temporary AWS credentials.
                                                  # this is the action that allows the EBS CSI driver to assume this IAM role.
      Condition = {
        StringEquals = {
          "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

# Associate the AWS-managed EBS CSI policy to the IAM role
resource "aws_iam_role_policy_attachment" "ebs_csi_iam_role_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi.name
}

