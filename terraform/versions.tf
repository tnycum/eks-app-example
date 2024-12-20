terraform {
  required_version = "~> 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      Project     = "tnycum EKS Testing"
      Provisioner = "Terraform"
      Environment = "Testing"
    }
  }
}
