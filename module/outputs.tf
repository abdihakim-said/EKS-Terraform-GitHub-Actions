# =============================================================================
# VPC OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC where EKS cluster is deployed"
  value       = aws_vpc.vpc.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.vpc.cidr_block
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets where EKS nodes are deployed"
  value       = aws_subnet.private-subnet[*].id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets for load balancers"
  value       = aws_subnet.public-subnet[*].id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.ngw.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

# =============================================================================
# EKS CLUSTER OUTPUTS
# =============================================================================

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = var.is-eks-cluster-enabled ? aws_eks_cluster.eks[0].name : null
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = var.is-eks-cluster-enabled ? aws_eks_cluster.eks[0].arn : null
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = var.is-eks-cluster-enabled ? aws_eks_cluster.eks[0].endpoint : null
  sensitive   = true
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = var.is-eks-cluster-enabled ? aws_eks_cluster.eks[0].version : null
}

output "cluster_platform_version" {
  description = "Platform version for the EKS cluster"
  value       = var.is-eks-cluster-enabled ? aws_eks_cluster.eks[0].platform_version : null
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = var.is-eks-cluster-enabled ? aws_eks_cluster.eks[0].status : null
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.eks-cluster-sg.id
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group created by Amazon EKS"
  value       = var.is-eks-cluster-enabled ? aws_eks_cluster.eks[0].vpc_config[0].cluster_security_group_id : null
}

# =============================================================================
# IAM OUTPUTS
# =============================================================================

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = var.is_eks_role_enabled ? aws_iam_role.eks-cluster-role[0].name : null
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = var.is_eks_role_enabled ? aws_iam_role.eks-cluster-role[0].arn : null
}

output "node_group_iam_role_name" {
  description = "IAM role name associated with EKS node group"
  value       = var.is_eks_nodegroup_role_enabled ? aws_iam_role.eks-nodegroup-role[0].name : null
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN associated with EKS node group"
  value       = var.is_eks_nodegroup_role_enabled ? aws_iam_role.eks-nodegroup-role[0].arn : null
}

# =============================================================================
# OIDC PROVIDER OUTPUTS
# =============================================================================

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = var.is-eks-cluster-enabled ? aws_eks_cluster.eks[0].identity[0].oidc[0].issuer : null
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider for service account authentication"
  value       = aws_iam_openid_connect_provider.eks-oidc.arn
}

# =============================================================================
# NODE GROUP OUTPUTS
# =============================================================================

output "node_groups" {
  description = "EKS node groups information"
  value = {
    ondemand = {
      arn            = aws_eks_node_group.ondemand-node.arn
      status         = aws_eks_node_group.ondemand-node.status
      capacity_type  = aws_eks_node_group.ondemand-node.capacity_type
      instance_types = aws_eks_node_group.ondemand-node.instance_types
      scaling_config = aws_eks_node_group.ondemand-node.scaling_config
    }
    spot = {
      arn            = aws_eks_node_group.spot-node.arn
      status         = aws_eks_node_group.spot-node.status
      capacity_type  = aws_eks_node_group.spot-node.capacity_type
      instance_types = aws_eks_node_group.spot-node.instance_types
      scaling_config = aws_eks_node_group.spot-node.scaling_config
    }
  }
}

# =============================================================================
# ADD-ONS OUTPUTS (SIMPLIFIED)
# =============================================================================

output "cluster_addons" {
  description = "Map of EKS cluster addons"
  value = {
    for k, v in aws_eks_addon.eks-addons : k => {
      addon_name    = v.addon_name
      addon_version = v.addon_version
    }
  }
}
