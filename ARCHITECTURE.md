# 🏗️ EKS Infrastructure Architecture

## Overview
This document provides a comprehensive overview of the enterprise-grade EKS infrastructure architecture implemented in this project.

## 🌐 CI/CD Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           GitHub Actions Workflow                              │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  📋 Job 1: Validate & Security Scan                                           │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  • Terraform Format & Validate                                         │   │
│  │  • tfsec Security Scanning                                              │   │
│  │  • Checkov Policy Validation                                            │   │
│  │  • SARIF Results Upload                                                 │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  📊 Job 2: Plan (on PR/Manual)                                                │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  • OIDC Authentication                                                  │   │
│  │  • Workspace Selection                                                  │   │
│  │  • Terraform Plan Generation                                            │   │
│  │  • Plan Summary & PR Comments                                           │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  🚀 Job 3: Apply/Destroy (Manual Only)                                        │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  • Environment Protection                                               │   │
│  │  • OIDC Authentication                                                  │   │
│  │  • Terraform Apply/Destroy                                              │   │
│  │  • Rich Deployment Summary                                              │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🔐 Security Architecture

### OIDC Authentication Flow
```
GitHub Actions → AWS STS → Assume Role → Temporary Credentials
     ↓              ↓           ↓              ↓
  Workflow      Identity    IAM Role      Short-lived
  Execution     Provider    Trust         Access Keys
                           Policy
```

### Security Layers
1. **Infrastructure Security**
   - Private EKS endpoints
   - Security groups with least privilege
   - VPC isolation with private subnets
   - IAM roles with minimal permissions

2. **CI/CD Security**
   - OIDC authentication (no long-lived keys)
   - Comprehensive security scanning
   - Environment-specific approvals
   - Audit trails for all deployments

3. **Application Security**
   - Pod Security Standards
   - Network Policies
   - RBAC implementation
   - Container image scanning

## 🗄️ State Management Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           Terraform State Management                           │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  📦 S3 Backend Configuration                                                   │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  Bucket: eks-terraform-state-{account-id}-{timestamp}                  │   │
│  │  ├── Versioning: Enabled                                               │   │
│  │  ├── Encryption: AES-256                                               │   │
│  │  ├── Public Access: Blocked                                            │   │
│  │  └── Lifecycle: 90-day retention                                       │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  🔒 DynamoDB Locking                                                           │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  Table: EKS-Terraform-Lock-Files                                       │   │
│  │  ├── Primary Key: LockID                                               │   │
│  │  ├── Billing: On-Demand                                                │   │
│  │  └── Purpose: Prevent concurrent modifications                         │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  🏗️ Workspace Isolation                                                       │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  • dev workspace    → dev.tfvars    → 10.16.0.0/16                    │   │
│  │  • staging workspace → staging.tfvars → 10.17.0.0/16                  │   │
│  │  • prod workspace   → prod.tfvars   → 10.18.0.0/16                    │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🌐 Network Architecture

### VPC Design
```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              VPC (10.x.0.0/16)                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  🌍 Public Tier (DMZ)                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  AZ-A: 10.x.1.0/24  │  AZ-B: 10.x.2.0/24  │  AZ-C: 10.x.3.0/24        │   │
│  │  ├── Internet Gateway                                                   │   │
│  │  ├── NAT Gateways                                                       │   │
│  │  ├── Load Balancers                                                     │   │
│  │  └── Bastion Hosts (Optional)                                           │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  🔒 Private Tier (Application)                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  AZ-A: 10.x.11.0/24 │  AZ-B: 10.x.12.0/24 │  AZ-C: 10.x.13.0/24       │   │
│  │  ├── EKS Worker Nodes                                                   │   │
│  │  ├── Application Pods                                                   │   │
│  │  ├── Internal Load Balancers                                            │   │
│  │  └── Database Connections                                               │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  🎛️ Control Plane (AWS Managed)                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  • Multi-AZ Deployment                                                  │   │
│  │  • Private API Endpoint                                                 │   │
│  │  • Managed etcd                                                         │   │
│  │  • Automatic Updates                                                    │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 👥 Node Group Architecture

### On-Demand Node Group
- **Purpose**: Critical, stateful workloads
- **Capacity**: Guaranteed compute resources
- **Scaling**: 1-20 nodes (environment dependent)
- **Instance Types**: m5a.large, m5a.xlarge, m5a.2xlarge
- **Use Cases**: Databases, critical services, control plane components

### Spot Instance Node Group
- **Purpose**: Fault-tolerant, stateless workloads
- **Cost Savings**: Up to 90% compared to on-demand
- **Scaling**: 0-10 nodes (environment dependent)
- **Instance Types**: t3a.medium, t3a.large, t3a.xlarge
- **Use Cases**: Batch processing, CI/CD, development workloads

## 📊 Monitoring & Observability

### CloudWatch Integration
```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           Monitoring Stack                                     │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  📈 Container Insights                                                         │
│  ├── Cluster-level metrics                                                     │
│  ├── Node-level metrics                                                        │
│  ├── Pod-level metrics                                                         │
│  └── Application metrics                                                       │
│                                                                                 │
│  📋 Control Plane Logs                                                         │
│  ├── API Server logs                                                           │
│  ├── Audit logs                                                                │
│  ├── Authenticator logs                                                        │
│  └── Controller Manager logs                                                   │
│                                                                                 │
│  🚨 Alerting                                                                   │
│  ├── High CPU/Memory usage                                                     │
│  ├── Pod restart frequency                                                     │
│  ├── Node health status                                                        │
│  └── Cost anomaly detection                                                    │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🔄 Deployment Flow

### Environment Promotion
```
Development → Staging → Production
     ↓           ↓          ↓
  Quick Tests  Integration  Full Testing
  Auto Deploy  Manual      Manual + Approval
  Public API   Private API Private API
```

### Rollback Strategy
1. **Terraform State**: Previous state versions in S3
2. **Application**: Blue/Green deployments
3. **Infrastructure**: Workspace-based isolation
4. **Emergency**: Force unlock and manual intervention

## 💰 Cost Optimization

### Resource Optimization
- **Spot Instances**: 30-70% of compute capacity
- **Right-sizing**: Environment-specific instance types
- **Auto-scaling**: Dynamic capacity adjustment
- **Reserved Instances**: Long-term production workloads

### Cost Monitoring
- **Tagging Strategy**: Environment, Project, Owner tags
- **Budget Alerts**: Monthly spending thresholds
- **Resource Cleanup**: Automated unused resource detection
- **Cost Reports**: Weekly cost breakdown by environment

## 🛡️ Disaster Recovery

### Backup Strategy
- **State Files**: S3 versioning and cross-region replication
- **Application Data**: EBS snapshots and cross-AZ replication
- **Configuration**: Git-based infrastructure as code
- **Secrets**: AWS Secrets Manager with rotation

### Recovery Procedures
1. **Infrastructure**: Terraform apply from backup state
2. **Applications**: Container image redeployment
3. **Data**: EBS snapshot restoration
4. **Network**: VPC peering and route table updates

## 📋 Compliance & Governance

### Security Standards
- **CIS Benchmarks**: Kubernetes and AWS compliance
- **SOC 2**: Infrastructure controls and monitoring
- **GDPR**: Data protection and privacy controls
- **HIPAA**: Healthcare data security (if applicable)

### Audit Trail
- **CloudTrail**: All API calls logged
- **GitHub Actions**: Deployment history and approvals
- **Terraform**: State change tracking
- **Application**: Container and pod-level logging

---

This architecture provides enterprise-grade security, scalability, and maintainability while optimizing for cost and operational efficiency.
