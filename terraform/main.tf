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

# resource "aws_iam_role" "sops_decrypt" {
#   name = "sops_decrypt"

#   assume_role_policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Effect" : "Allow",
#         "Principal" : {
#           "Federated" : "arn:aws:iam::${local.account_id}:oidc-provider/${var.oidc_provider}"
#         },
#         "Action" : "sts:AssumeRoleWithWebIdentity",
#         "Condition" : {
#           "StringEquals" : {
#             "${var.oidc_provider}:sub" : "system:serviceaccount:flux-system:kustomize-controller",
#             "${var.oidc_provider}:aud" : "sts.amazonaws.com"
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy" "sops_decrypt" {
#   name = "sops_decrypt_policy"
#   role = aws_iam_role.sops_decrypt.id

#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Action" : [
#           "kms:Decrypt",
#           "kms:DescribeKey"
#         ],
#         "Effect" : "Allow",
#         "Resource" : "${aws_kms_key.sops.arn}"
#       }
#     ]
#   })
# }

resource "local_file" "sops_config" {
  filename = "${path.module}/../.sops.yaml"
  content = templatefile("${path.module}/templates/sops.yaml.tmpl", {
    arn = aws_kms_key.sops.arn
  })
}

resource "aws_kms_key" "eks_encrypt" {
  description             = "Used for encrypting EKS secrets at rest"
  enable_key_rotation     = true
  deletion_window_in_days = 20
}

resource "aws_kms_alias" "eks_encrypt" {
  name          = "alias/${var.eks_secrets_encryption_kms_name}"
  target_key_id = aws_kms_key.eks_encrypt.id
}

resource "aws_kms_key_policy" "eks_encrypt" {
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

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.9.0"

  name = "eks-auto-mode"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name                   = var.eks_cluster_name
  cluster_version                = "1.30"
  cluster_endpoint_public_access = true


  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Enables EKS Auto Mode
  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  # TODO secrets encryption
}

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

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks --region ${data.aws_region.current.name} update-kubeconfig --name ${module.eks.cluster_name}"
  }
}