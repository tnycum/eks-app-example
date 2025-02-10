terraform {
  backend "s3" {
    bucket = "tnycum-eks-app-example-terraform-state"
    key    = "sops-kms"
    region = "us-east-1"
  }
}
