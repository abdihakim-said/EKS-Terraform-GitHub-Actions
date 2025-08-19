# 🔐 GitHub OIDC Setup Guide

This guide will help you set up GitHub OIDC (OpenID Connect) for secure authentication between GitHub Actions and AWS, eliminating the need for long-lived AWS access keys.

## 📋 Prerequisites

- AWS CLI configured with admin permissions
- GitHub repository created
- Basic understanding of IAM roles

## 🚀 Step 1: Create OIDC Identity Provider in AWS

### Option A: Using AWS CLI (Recommended)

```bash
# Create the OIDC identity provider
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
    --thumbprint-list 1c58a3a8518e8759bf075b76b750d4f2df264fcd
```

### Option B: Using AWS Console

1. Go to IAM → Identity providers → Add provider
2. Select **OpenID Connect**
3. Provider URL: `https://token.actions.githubusercontent.com`
4. Audience: `sts.amazonaws.com`
5. Click **Add provider**

## 🚀 Step 2: Create IAM Role for GitHub Actions

### Create Trust Policy

Create a file `github-oidc-trust-policy.json`:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/EKS-Terraform-GitHub-Actions:*"
                }
            }
        }
    ]
}
```

### Create the IAM Role

```bash
# Replace YOUR_ACCOUNT_ID and YOUR_GITHUB_USERNAME
aws iam create-role \
    --role-name GitHubActions-EKS-Role \
    --assume-role-policy-document file://github-oidc-trust-policy.json \
    --description "Role for GitHub Actions to manage EKS infrastructure"
```

### Attach Necessary Policies

```bash
# Attach required AWS managed policies
aws iam attach-role-policy \
    --role-name GitHubActions-EKS-Role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

aws iam attach-role-policy \
    --role-name GitHubActions-EKS-Role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam attach-role-policy \
    --role-name GitHubActions-EKS-Role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

aws iam attach-role-policy \
    --role-name GitHubActions-EKS-Role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

# For broader permissions (use carefully)
aws iam attach-role-policy \
    --role-name GitHubActions-EKS-Role \
    --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

## 🚀 Step 3: Configure GitHub Repository Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Add the following repository secret:

| Secret Name | Value |
|-------------|-------|
| `AWS_ROLE_TO_ASSUME` | `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActions-EKS-Role` |

## 🚀 Step 4: Set Up GitHub Environments (Optional but Recommended)

### Create Environments

1. Go to **Settings** → **Environments**
2. Create three environments:
   - `dev` (no protection rules)
   - `staging` (optional: require reviewers)
   - `prod` (require reviewers + deployment branches)

### Environment Protection Rules for Production

For the `prod` environment:
- ✅ **Required reviewers**: Add team members
- ✅ **Deployment branches**: Only `main` branch
- ✅ **Wait timer**: 5 minutes (optional)

## 🚀 Step 5: Test the Setup

### Manual Test

1. Go to **Actions** tab in your GitHub repository
2. Select **EKS Infrastructure Deployment** workflow
3. Click **Run workflow**
4. Select:
   - Environment: `dev`
   - Action: `plan`
5. Run the workflow

### Expected Result

The workflow should:
- ✅ Authenticate with AWS using OIDC
- ✅ Initialize Terraform
- ✅ Run security scans
- ✅ Generate a plan for the dev environment

## 🔧 Troubleshooting

### Common Issues

#### 1. "No identity-based policy allows the sts:AssumeRoleWithWebIdentity action"

**Solution**: Check that the trust policy is correctly configured with your GitHub repository path.

#### 2. "Could not assume role with OIDC"

**Solution**: Verify that:
- OIDC provider exists in AWS
- Role ARN is correct in GitHub secrets
- Repository path in trust policy matches exactly

#### 3. "Access denied" during Terraform operations

**Solution**: The IAM role needs additional permissions. Consider attaching `PowerUserAccess` for testing (restrict in production).

## 🛡️ Security Best Practices

### ✅ Do's
- Use specific repository paths in trust policy
- Implement environment protection rules
- Use least privilege principle for IAM policies
- Regularly rotate and review permissions

### ❌ Don'ts
- Don't use `*` wildcards in trust policies
- Don't attach `AdministratorAccess` unless absolutely necessary
- Don't skip environment protection for production
- Don't commit AWS credentials to code

## 📚 Additional Resources

- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [AWS IAM OIDC Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [Terraform AWS Provider OIDC](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#assuming-an-iam-role)

---

🎉 **Once completed, your GitHub Actions will securely authenticate with AWS without storing any long-lived credentials!**
