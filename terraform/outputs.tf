output "sops_decrypt_role_arn" {
  #value = aws_iam_role.sops_decrypt.arn
  value = module.custom_pod_identity.iam_role_arn
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}
