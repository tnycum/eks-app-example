terraform {
  backend "s3" {
    bucket = "tnycum-eks-app-example-terraform-state"
    key    = "eks"
    region = "us-east-1"
  }
}
