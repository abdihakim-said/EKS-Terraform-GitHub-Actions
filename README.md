# 🚀 Production-Ready EKS Infrastructure with Terraform & GitHub Actions

[![LinkedIn](https://img.shields.io/badge/Connect%20with%20me%20on-LinkedIn-blue.svg)](https://www.linkedin.com/in/said-devops/)
[![Medium](https://img.shields.io/badge/Medium-12100E?style=for-the-badge&logo=medium&logoColor=white)](https://medium.com/@said-devops)
[![GitHub](https://img.shields.io/github/stars/AmanPathak-DevOps.svg?style=social)](https://github.com/abdihakim-said)
[![AWS](https://img.shields.io/badge/AWS-%F0%9F%9B%A1-orange)](https://aws.amazon.com)
[![Terraform](https://img.shields.io/badge/Terraform-%E2%9C%A8-lightgrey)](https://www.terraform.io)

![EKS- GitHub Actions- Terraform](assets/Presentation1.gif)

## 🌟 Overview

This repository demonstrates **enterprise-grade** EKS infrastructure deployment using modern DevOps practices. Built for **production environments** with comprehensive security scanning, multi-environment support, and automated CI/CD pipelines.

### 🎯 **Key Features**

- **🔒 Security-First**: Comprehensive scanning with tfsec & Checkov
- **🏗️ Multi-Environment**: Isolated workspaces for dev/staging/prod
- **🚀 CI/CD Automation**: GitHub Actions with OIDC authentication
- **📊 Cost Optimization**: Mixed on-demand and spot instances
- **🛡️ Enterprise Security**: Private endpoints, restricted access
- **📋 Rich Outputs**: Comprehensive resource information

## 🏗️ **Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                     AWS EKS Cluster                        │
├─────────────────────────────────────────────────────────────┤
│  VPC (10.x.0.0/16)                                        │
│  ├── Public Subnets (3 AZs)                               │
│  │   ├── Internet Gateway                                 │
│  │   └── NAT Gateway                                      │
│  └── Private Subnets (3 AZs)                              │
│      ├── EKS Control Plane                                │
│      ├── On-Demand Node Group                             │
│      └── Spot Node Group                                  │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 **Quick Start**

### **Prerequisites**
- AWS CLI configured
- Terraform >= 1.9.3
- kubectl
- GitHub repository with OIDC configured

### **1. Clone Repository**
```bash
git clone https://github.com/abdihakim-said/EKS-Terraform-GitHub-Actions.git
cd EKS-Terraform-GitHub-Actions
```

### **2. Configure Backend**
Update `eks/backend.tf` with your S3 bucket:
```hcl
backend "s3" {
  bucket = "your-terraform-state-bucket"
  region = "us-east-1"
  key    = "eks/${terraform.workspace}/terraform.tfstate"
}
```

### **3. Deploy Infrastructure**

#### **Option A: GitHub Actions (Recommended)**
1. Go to Actions tab in GitHub
2. Select "EKS Infrastructure Deployment"
3. Choose environment and action
4. Run workflow

#### **Option B: Local Deployment**
```bash
cd eks
terraform init
terraform workspace new dev
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

### **4. Configure kubectl**
```bash
aws eks --region us-east-1 update-kubeconfig --name dev-medium-eks-cluster
kubectl get nodes
```

## 🔧 **Configuration**

### **Environment Files**
- `eks/dev.tfvars` - Development environment
- `eks/staging.tfvars` - Staging environment  
- `eks/prod.tfvars` - Production environment

### **Key Variables**
```hcl
env                        = "dev"
cluster-version           = "1.31"
vpc-cidr-block           = "10.16.0.0/16"
endpoint-private-access  = true
endpoint-public-access   = false
```

## 🛡️ **Security Features**

### **Infrastructure Security**
- ✅ Private EKS endpoints
- ✅ Security groups with least privilege
- ✅ VPC with proper subnet isolation
- ✅ IAM roles with minimal permissions

### **CI/CD Security**
- ✅ OIDC authentication (no long-lived keys)
- ✅ tfsec security scanning
- ✅ Checkov policy-as-code validation
- ✅ Environment-specific approvals

### **Security Scanning Results**
Security scan results are automatically uploaded to GitHub Security tab:
- **tfsec**: Fast Terraform-specific security checks
- **Checkov**: 500+ built-in security policies

## 🌍 **Multi-Environment Support**

### **Workspace Management**
```bash
# Development
terraform workspace select dev
terraform apply -var-file=dev.tfvars

# Staging  
terraform workspace select staging
terraform apply -var-file=staging.tfvars

# Production
terraform workspace select prod
terraform apply -var-file=prod.tfvars
```

### **Environment Differences**
| Environment | Instance Types | Min Nodes | Max Nodes | Public Access |
|-------------|---------------|-----------|-----------|---------------|
| Dev         | t3a.medium    | 1         | 5         | ✅            |
| Staging     | t3a.large     | 2         | 10        | ❌            |
| Production  | m5a.large     | 3         | 20        | ❌            |

## 📊 **Cost Optimization**

### **Instance Strategy**
- **On-Demand**: Guaranteed capacity for critical workloads
- **Spot Instances**: Up to 90% cost savings for fault-tolerant workloads
- **Auto Scaling**: Dynamic scaling based on demand

### **Cost Breakdown**
```
Development:   ~$150/month
Staging:       ~$300/month  
Production:    ~$600/month
```

## 🔄 **CI/CD Pipeline**

### **GitHub Actions Workflow**
```yaml
Trigger: PR/Push/Manual
├── Validate & Security Scan
│   ├── Terraform Format/Validate
│   ├── tfsec Security Scan
│   └── Checkov Policy Scan
├── Plan (on PR)
│   ├── Workspace Selection
│   └── Plan with PR Comments
└── Apply/Destroy (Manual)
    ├── Environment Protection
    ├── OIDC Authentication
    └── Rich Deployment Summary
```

### **Security Scanning**
- **Automated**: Runs on every PR and push
- **Comprehensive**: Multiple security tools
- **Integrated**: Results in GitHub Security tab
- **Non-blocking**: Soft failures for flexibility

## 📋 **Outputs**

After deployment, you'll get comprehensive outputs:
```bash
terraform output cluster_name
terraform output cluster_endpoint
terraform output configure_kubectl
terraform output vpc_id
terraform output node_groups
```

## 🏢 **Enterprise Features**

### **Governance**
- Environment-specific approval workflows
- Audit trails for all deployments
- Workspace isolation for state management
- Change management with plan-before-apply

### **Monitoring & Observability**
- Comprehensive logging in GitHub Actions
- Rich deployment summaries
- Direct links to AWS console
- Error handling and recovery

### **Scalability**
- Modular Terraform design
- Reusable components
- Multi-environment support
- Team collaboration features

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run security scans locally
5. Submit a pull request

## 📚 **Best Practices Demonstrated**

### **Infrastructure as Code**
- ✅ Modular Terraform design
- ✅ Variable validation
- ✅ Comprehensive outputs
- ✅ State management

### **Security**
- ✅ Multi-layered security scanning
- ✅ OIDC authentication
- ✅ Least privilege access
- ✅ Private networking

### **DevOps**
- ✅ Automated CI/CD pipelines
- ✅ Multi-environment workflows
- ✅ Rich feedback and monitoring
- ✅ Error handling

### **Cost Management**
- ✅ Spot instance utilization
- ✅ Right-sizing per environment
- ✅ Auto-scaling configuration
- ✅ Resource optimization

## 🔗 **Useful Links**

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [tfsec Security Scanner](https://github.com/aquasecurity/tfsec)
- [Checkov Policy Scanner](https://github.com/bridgecrewio/checkov)

## 📄 **License**

This project is licensed under the Apache 2.0 License. See the [LICENSE](LICENSE) file for details.

## 📢 **Connect**

Built with ❤️ by [Abdihakim Said](https://www.linkedin.com/in/said-devops/)

- 💼 [LinkedIn](https://www.linkedin.com/in/said-devops/)
- 📝 [Medium](https://medium.com/@said-devops)
- 🐙 [GitHub](https://github.com/abdihakim-said)

---

⭐ **Star this repository if it helped you!**
