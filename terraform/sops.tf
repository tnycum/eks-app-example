resource "aws_kms_key" "sops" {
  description             = "Used for encrypting secrets with SOPS"
  enable_key_rotation     = true
  deletion_window_in_days = 20
}

resource "aws_kms_alias" "sops" {
  name          = "alias/${var.kms_name}"
  target_key_id = aws_kms_key.sops.id
}

resource "aws_kms_key_policy" "sops" {
  key_id = aws_kms_key.sops.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

# Manage the local sops config file so we don't need to specify the KMS key to
# use for encryption/decryption using the CLI
resource "local_file" "sops_config" {
  filename = "${path.module}/../.sops.yaml"
  content = templatefile("${path.module}/templates/sops.yaml.tmpl", {
    arn = aws_kms_key.sops.arn
  })
}

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
      resources = ["${aws_kms_key.sops.arn}"]
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