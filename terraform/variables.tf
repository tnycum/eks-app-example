variable "kms_name" {
  default = "eks_sops_key"
}

variable "oidc_provider" {
  description = "Value of OIDC provider ID for EKS cluster"
}
