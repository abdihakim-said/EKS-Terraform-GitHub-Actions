#!/bin/bash

# =============================================================================
# Terraform Backend Setup Script
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration - Generate unique bucket name
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "unknown")
BUCKET_NAME="eks-terraform-state-${ACCOUNT_ID}-$(date +%s)"
DYNAMODB_TABLE="EKS-Terraform-Lock-Files"
AWS_REGION="us-east-1"

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is configured
check_aws_cli() {
    print_status "Checking AWS CLI configuration..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "AWS CLI configured for account: $ACCOUNT_ID"
}

# Create S3 bucket for Terraform state
create_s3_bucket() {
    print_status "Creating S3 bucket: $BUCKET_NAME"
    
    # Create bucket
    if [ "$AWS_REGION" = "us-east-1" ]; then
        aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION"
    else
        aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" \
            --create-bucket-configuration LocationConstraint="$AWS_REGION"
    fi
    print_success "S3 bucket created: $BUCKET_NAME"
    
    # Enable versioning
    print_status "Enabling versioning on S3 bucket..."
    aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled
    
    # Enable server-side encryption
    print_status "Enabling server-side encryption..."
    aws s3api put-bucket-encryption --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
    
    # Block public access
    print_status "Blocking public access..."
    aws s3api put-public-access-block --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    
    print_success "S3 bucket configured with security best practices"
}

# Create DynamoDB table for state locking
create_dynamodb_table() {
    print_status "Creating DynamoDB table: $DYNAMODB_TABLE"
    
    # Check if table already exists
    if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" &>/dev/null; then
        print_warning "DynamoDB table $DYNAMODB_TABLE already exists"
    else
        aws dynamodb create-table \
            --table-name "$DYNAMODB_TABLE" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
            --region "$AWS_REGION"
        
        print_status "Waiting for DynamoDB table to be active..."
        aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION"
        print_success "DynamoDB table created: $DYNAMODB_TABLE"
    fi
}

# Update backend configuration
update_backend_config() {
    print_status "Updating backend configuration..."
    
    # Update the backend.tf file with the new bucket name
    cat > eks/backend.tf << EOF
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
    bucket         = "$BUCKET_NAME"
    region         = "$AWS_REGION"
    key            = "eks/terraform.tfstate"
    dynamodb_table = "$DYNAMODB_TABLE"
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
EOF
    
    print_success "Backend configuration updated"
}

# Main execution
main() {
    echo "=========================================="
    echo "🚀 Terraform Backend Setup"
    echo "=========================================="
    echo ""
    
    check_aws_cli
    create_s3_bucket
    create_dynamodb_table
    update_backend_config
    
    echo ""
    echo "=========================================="
    print_success "Backend infrastructure setup complete!"
    echo "=========================================="
    echo ""
    echo "📋 Summary:"
    echo "  • S3 Bucket: $BUCKET_NAME"
    echo "  • DynamoDB Table: $DYNAMODB_TABLE"
    echo "  • Region: $AWS_REGION"
    echo ""
    echo "🔧 Next steps:"
    echo "  1. cd eks"
    echo "  2. terraform init"
    echo "  3. terraform workspace new dev"
    echo "  4. terraform plan -var-file=dev.tfvars"
    echo ""
}

main "$@"
