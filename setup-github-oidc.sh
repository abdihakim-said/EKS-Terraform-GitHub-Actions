#!/bin/bash

# =============================================================================
# GitHub OIDC Setup Script for AWS
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Get user inputs
get_user_inputs() {
    echo "=========================================="
    echo "🔐 GitHub OIDC Setup for AWS"
    echo "=========================================="
    echo ""
    
    # Get GitHub repository information
    read -p "Enter your GitHub username: " GITHUB_USERNAME
    read -p "Enter your repository name (default: EKS-Terraform-GitHub-Actions): " REPO_NAME
    REPO_NAME=${REPO_NAME:-EKS-Terraform-GitHub-Actions}
    
    # Get AWS account ID
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
    if [ -z "$ACCOUNT_ID" ]; then
        print_error "Could not get AWS account ID. Please ensure AWS CLI is configured."
        exit 1
    fi
    
    print_status "Configuration:"
    echo "  • GitHub Repository: $GITHUB_USERNAME/$REPO_NAME"
    echo "  • AWS Account ID: $ACCOUNT_ID"
    echo ""
    
    read -p "Continue with this configuration? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
}

# Create OIDC Identity Provider
create_oidc_provider() {
    print_status "Creating OIDC Identity Provider..."
    
    # Check if provider already exists
    if aws iam get-open-id-connect-provider \
        --open-id-connect-provider-arn "arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com" \
        &>/dev/null; then
        print_warning "OIDC provider already exists"
    else
        aws iam create-open-id-connect-provider \
            --url https://token.actions.githubusercontent.com \
            --client-id-list sts.amazonaws.com \
            --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
            --thumbprint-list 1c58a3a8518e8759bf075b76b750d4f2df264fcd
        
        print_success "OIDC Identity Provider created"
    fi
}

# Create trust policy
create_trust_policy() {
    print_status "Creating trust policy..."
    
    cat > github-oidc-trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:$GITHUB_USERNAME/$REPO_NAME:*"
                }
            }
        }
    ]
}
EOF
    
    print_success "Trust policy created: github-oidc-trust-policy.json"
}

# Create IAM role
create_iam_role() {
    print_status "Creating IAM role for GitHub Actions..."
    
    ROLE_NAME="GitHubActions-EKS-Role"
    
    # Check if role already exists
    if aws iam get-role --role-name "$ROLE_NAME" &>/dev/null; then
        print_warning "IAM role $ROLE_NAME already exists"
    else
        aws iam create-role \
            --role-name "$ROLE_NAME" \
            --assume-role-policy-document file://github-oidc-trust-policy.json \
            --description "Role for GitHub Actions to manage EKS infrastructure"
        
        print_success "IAM role created: $ROLE_NAME"
    fi
    
    # Attach policies
    print_status "Attaching IAM policies..."
    
    policies=(
        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    )
    
    for policy in "${policies[@]}"; do
        aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$policy" || true
    done
    
    # Create custom policy for additional permissions
    print_status "Creating custom policy for additional permissions..."
    
    cat > github-actions-custom-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:CreateOpenIDConnectProvider",
                "iam:DeleteOpenIDConnectProvider",
                "iam:GetOpenIDConnectProvider",
                "iam:CreatePolicy",
                "iam:DeletePolicy",
                "iam:GetPolicy",
                "iam:GetPolicyVersion",
                "iam:ListPolicyVersions",
                "iam:CreatePolicyVersion",
                "iam:DeletePolicyVersion",
                "iam:PassRole",
                "iam:GetRole",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:TagRole",
                "iam:UntagRole"
            ],
            "Resource": "*"
        }
    ]
}
EOF
    
    # Create and attach custom policy
    CUSTOM_POLICY_NAME="GitHubActions-EKS-CustomPolicy"
    
    if ! aws iam get-policy --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/$CUSTOM_POLICY_NAME" &>/dev/null; then
        aws iam create-policy \
            --policy-name "$CUSTOM_POLICY_NAME" \
            --policy-document file://github-actions-custom-policy.json \
            --description "Custom policy for GitHub Actions EKS deployment"
        
        print_success "Custom policy created: $CUSTOM_POLICY_NAME"
    fi
    
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/$CUSTOM_POLICY_NAME" || true
    
    print_success "All policies attached to role"
}

# Generate GitHub secrets information
generate_github_info() {
    print_status "Generating GitHub repository configuration..."
    
    ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/GitHubActions-EKS-Role"
    
    echo ""
    echo "=========================================="
    print_success "Setup Complete!"
    echo "=========================================="
    echo ""
    echo "📋 Next Steps:"
    echo ""
    echo "1. Add the following secret to your GitHub repository:"
    echo "   Go to: https://github.com/$GITHUB_USERNAME/$REPO_NAME/settings/secrets/actions"
    echo ""
    echo "   Secret Name: AWS_ROLE_TO_ASSUME"
    echo "   Secret Value: $ROLE_ARN"
    echo ""
    echo "2. (Optional) Set up GitHub Environments:"
    echo "   Go to: https://github.com/$GITHUB_USERNAME/$REPO_NAME/settings/environments"
    echo "   Create environments: dev, staging, prod"
    echo ""
    echo "3. Test the setup:"
    echo "   • Go to Actions tab in your repository"
    echo "   • Run 'EKS Infrastructure Deployment' workflow"
    echo "   • Select environment: dev, action: plan"
    echo ""
    echo "🔗 Useful Links:"
    echo "   • Repository: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
    echo "   • Actions: https://github.com/$GITHUB_USERNAME/$REPO_NAME/actions"
    echo "   • Settings: https://github.com/$GITHUB_USERNAME/$REPO_NAME/settings"
    echo ""
}

# Cleanup temporary files
cleanup() {
    print_status "Cleaning up temporary files..."
    rm -f github-oidc-trust-policy.json github-actions-custom-policy.json
    print_success "Cleanup complete"
}

# Main execution
main() {
    get_user_inputs
    create_oidc_provider
    create_trust_policy
    create_iam_role
    generate_github_info
    cleanup
}

# Run main function
main "$@"
