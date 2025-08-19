# 🚀 EKS Deployment Guide

This guide will walk you through deploying your EKS infrastructure from scratch to a fully functional Kubernetes cluster.

## 📋 Prerequisites

Before starting, ensure you have:

- ✅ AWS CLI installed and configured
- ✅ Terraform >= 1.5.0 installed
- ✅ kubectl installed
- ✅ GitHub repository created
- ✅ Admin access to AWS account

## 🚀 Step 1: Set Up Backend Infrastructure

The first step is to create the S3 bucket and DynamoDB table for Terraform state management.

```bash
# Run the automated setup script
./setup-backend.sh
```

**What this does:**
- Creates S3 bucket with versioning and encryption
- Creates DynamoDB table for state locking
- Configures security best practices

**Expected Output:**
```
✅ S3 Bucket: dev-aman-tf-bucket
✅ DynamoDB Table: Lock-Files
✅ Region: us-east-1
```

## 🚀 Step 2: Configure GitHub OIDC (Optional but Recommended)

For secure CI/CD without long-lived AWS credentials:

```bash
# Run the OIDC setup script
./setup-github-oidc.sh
```

**What this does:**
- Creates OIDC identity provider in AWS
- Creates IAM role for GitHub Actions
- Generates GitHub secrets configuration

**Manual Alternative:**
If you prefer manual setup, follow the detailed guide in `setup-github-oidc.md`.

## 🚀 Step 3: Deploy EKS Infrastructure

### Option A: Local Deployment

```bash
# Navigate to the eks directory
cd eks

# Initialize Terraform
terraform init

# Create and select workspace for dev environment
terraform workspace new dev
terraform workspace select dev

# Review the deployment plan
terraform plan -var-file=dev.tfvars

# Deploy the infrastructure
terraform apply -var-file=dev.tfvars
```

### Option B: GitHub Actions Deployment (Recommended)

1. **Push your code to GitHub:**
   ```bash
   git add .
   git commit -m "Add EKS infrastructure with enterprise features"
   git push origin main
   ```

2. **Configure GitHub Secrets:**
   - Go to your repository settings
   - Add secret: `AWS_ROLE_TO_ASSUME` with the role ARN from Step 2

3. **Run the deployment:**
   - Go to Actions tab
   - Select "EKS Infrastructure Deployment"
   - Choose:
     - Environment: `dev`
     - Action: `apply`
   - Run workflow

## 🚀 Step 4: Configure kubectl

After successful deployment, configure kubectl to access your cluster:

```bash
# Get the kubectl configuration command from Terraform output
terraform output configure_kubectl

# Or manually configure
aws eks --region us-east-1 update-kubeconfig --name dev-medium-eks-cluster

# Verify cluster access
kubectl get nodes
kubectl get pods --all-namespaces
```

**Expected Output:**
```
NAME                                        STATUS   ROLES    AGE   VERSION
ip-10-16-xxx-xxx.ec2.internal              Ready    <none>   5m    v1.31.x
ip-10-16-xxx-xxx.ec2.internal              Ready    <none>   5m    v1.31.x
```

## 🚀 Step 5: Verify Deployment

### Check Cluster Status
```bash
# Cluster information
kubectl cluster-info

# Node status
kubectl get nodes -o wide

# System pods
kubectl get pods -n kube-system

# EKS add-ons
kubectl get pods -n kube-system | grep -E "(coredns|aws-node|kube-proxy|ebs-csi)"
```

### Check AWS Resources
```bash
# EKS cluster
aws eks describe-cluster --name dev-medium-eks-cluster --region us-east-1

# Node groups
aws eks describe-nodegroup --cluster-name dev-medium-eks-cluster --nodegroup-name dev-medium-eks-cluster-on-demand-nodes --region us-east-1

# VPC and subnets
terraform output vpc_id
terraform output private_subnet_ids
```

## 🚀 Step 6: Deploy Sample Application (Optional)

Test your cluster with a sample application:

```bash
# Create a sample deployment
kubectl create deployment nginx --image=nginx:latest

# Expose the deployment
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Check the service
kubectl get services

# Get the external IP (may take a few minutes)
kubectl get service nginx -w
```

## 🚀 Step 7: Multi-Environment Deployment

### Deploy Staging Environment

```bash
# Using Terraform locally
terraform workspace new staging
terraform workspace select staging
terraform plan -var-file=staging.tfvars
terraform apply -var-file=staging.tfvars

# Using GitHub Actions
# Run workflow with environment: staging
```

### Deploy Production Environment

```bash
# Using Terraform locally
terraform workspace new prod
terraform workspace select prod
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars

# Using GitHub Actions
# Run workflow with environment: prod (requires approval)
```

## 🔧 Troubleshooting

### Common Issues

#### 1. "Backend initialization failed"
```bash
# Solution: Ensure S3 bucket and DynamoDB table exist
./setup-backend.sh
```

#### 2. "Access denied" errors
```bash
# Solution: Check AWS credentials and permissions
aws sts get-caller-identity
aws iam get-user
```

#### 3. "Cluster not accessible"
```bash
# Solution: Update kubeconfig
aws eks --region us-east-1 update-kubeconfig --name dev-medium-eks-cluster

# Check AWS credentials
aws sts get-caller-identity
```

#### 4. "Nodes not joining cluster"
```bash
# Check node group status
aws eks describe-nodegroup --cluster-name dev-medium-eks-cluster --nodegroup-name dev-medium-eks-cluster-on-demand-nodes --region us-east-1

# Check CloudFormation stacks
aws cloudformation list-stacks --stack-status-filter CREATE_IN_PROGRESS UPDATE_IN_PROGRESS
```

### Useful Commands

```bash
# Check Terraform state
terraform state list
terraform show

# Check specific resources
terraform state show module.eks.aws_eks_cluster.eks[0]

# Refresh state
terraform refresh -var-file=dev.tfvars

# Import existing resources (if needed)
terraform import module.eks.aws_eks_cluster.eks[0] dev-medium-eks-cluster
```

## 🧹 Cleanup

### Destroy Infrastructure

```bash
# Using Terraform locally
terraform destroy -var-file=dev.tfvars

# Using GitHub Actions
# Run workflow with action: destroy
```

### Cleanup Backend (Optional)

```bash
# Delete S3 bucket contents
aws s3 rm s3://dev-aman-tf-bucket --recursive

# Delete S3 bucket
aws s3api delete-bucket --bucket dev-aman-tf-bucket --region us-east-1

# Delete DynamoDB table
aws dynamodb delete-table --table-name Lock-Files --region us-east-1
```

## 📊 Cost Estimation

### Monthly Costs (Approximate)

| Environment | EKS Cluster | EC2 Instances | NAT Gateway | Total |
|-------------|-------------|---------------|-------------|-------|
| Dev         | $73         | $30-60        | $45         | ~$150 |
| Staging     | $73         | $60-120       | $45         | ~$300 |
| Production  | $73         | $120-240      | $45         | ~$450 |

**Cost Optimization Tips:**
- Use spot instances for non-production workloads
- Right-size instances based on actual usage
- Consider using Fargate for certain workloads
- Enable cluster autoscaler

## 🎯 Next Steps

After successful deployment:

1. **Set up monitoring:** Install Prometheus, Grafana, or use AWS CloudWatch
2. **Configure logging:** Set up centralized logging with Fluentd or AWS CloudWatch Logs
3. **Implement GitOps:** Use ArgoCD or Flux for application deployment
4. **Security hardening:** Implement Pod Security Standards, Network Policies
5. **Backup strategy:** Set up ETCD backups and disaster recovery

## 📚 Additional Resources

- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EKS Workshop](https://www.eksworkshop.com/)

---

🎉 **Congratulations! You now have a production-ready EKS cluster with enterprise-grade CI/CD!**
