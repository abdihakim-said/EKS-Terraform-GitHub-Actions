# =============================================================================
# EKS CLUSTER OUTPUTS
# =============================================================================

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = module.eks.cluster_version
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

# =============================================================================
# NETWORKING OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.eks.vpc_id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = module.eks.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.eks.public_subnet_ids
}

# =============================================================================
# SECURITY OUTPUTS
# =============================================================================

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = module.eks.oidc_provider_arn
}

# =============================================================================
# NODE GROUP OUTPUTS
# =============================================================================

output "node_groups" {
  description = "EKS node groups"
  value       = module.eks.node_groups
}

# =============================================================================
# KUBECTL CONFIG COMMAND
# =============================================================================

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.aws-region} update-kubeconfig --name ${module.eks.cluster_name}"
}
