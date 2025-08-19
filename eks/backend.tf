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

  backend "s3" {
    # INTERVIEW POINT: Remote state management with S3
    bucket         = "eks-terraform-state-426578051122-1755640986"
    region         = "us-east-1"
    key            = "eks/terraform.tfstate"
    dynamodb_table = "EKS-Terraform-Lock-Files"
    encrypt        = true

    # SECURITY: Additional backend security features
    skip_region_validation      = false
    skip_credentials_validation = false
    skip_metadata_api_check     = false
  }
}

provider "aws" {
  region = var.aws-region

  # INTERVIEW POINT: Consistent tagging strategy across all resources
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
