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

resource "aws_iam_role" "sops_decrypt" {
  name = "sops_decrypt"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${local.account_id}:oidc-provider/${var.oidc_provider}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${var.oidc_provider}:sub" : "system:serviceaccount:flux-system:kustomize-controller",
            "${var.oidc_provider}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "sops_decrypt" {
  name = "sops_decrypt_policy"
  role = aws_iam_role.sops_decrypt.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "kms:Decrypt",
          "kms:DescribeKey"
        ],
        "Effect" : "Allow",
        "Resource" : "${aws_kms_key.sops.arn}"
      }
    ]
  })
}

resource "local_file" "sops_config" {
  filename = "${path.module}/../.sops.yaml"
  content = templatefile("${path.module}/templates/sops.yaml.tmpl", {
    arn = aws_kms_key.sops.arn
  })
}
