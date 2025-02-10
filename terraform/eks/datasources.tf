data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "terraform_remote_state" "sops_kms" {
    backend = "s3"

    config = {
      bucket = "tnycum-eks-app-example-terraform-state"
      key = "sops-kms"
      region = "us-east-1"
    }
}