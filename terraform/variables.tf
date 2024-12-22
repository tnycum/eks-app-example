variable "kms_name" {
  default = "eks_sops_key"
}

# variable "oidc_provider" {
#   description = "Value of OIDC provider ID for EKS cluster"
# }

variable "eks_secrets_encryption_kms_name" {
  default = "eks_secrets_encryption_key"
}

variable "eks_cluster_name" {
  default = "tnycum-basic-cluster"
}