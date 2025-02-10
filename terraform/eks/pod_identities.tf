

# Allow the Flux kustomize controller to decrypt SOPS secrets
module "custom_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "eks_sops_decrypt"

  attach_custom_policy      = true

  policy_statements = [
    {
      sid       = "EKSSOPSDecrypt"
      actions   = [
        "kms:Decrypt",
        "kms:DescribeKey"
      ]
      resources = ["${data.terraform_remote_state.sops_kms.outputs.sops_key_arn}"]
    }
  ]

  associations = {
    flux-kustomize-controller = {
      cluster_name = module.eks.cluster_name
      namespace = "flux-system"
      service_account = "kustomize-controller"
    }
  }
}