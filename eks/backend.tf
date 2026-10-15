terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Partial backend config: the bucket name is passed at init time
  # (backend.hcl locally, the TF_STATE_BUCKET secret in CI), so no account ID is committed.
  backend "s3" {
    region         = "us-east-1"
    key            = "eks/terraform.tfstate"
    dynamodb_table = "EKS-Terraform-Lock-Files"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws-region

  default_tags {
    tags = {
      Environment = var.env
      Project     = "EKS-Infrastructure"
      ManagedBy   = "Terraform"
      Owner       = "DevOps-Team"
      CostCenter  = "Engineering"
      Repository  = "EKS-Terraform-GitHub-Actions"
    }
  }
}
