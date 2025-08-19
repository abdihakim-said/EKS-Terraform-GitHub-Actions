# =============================================================================
# BASIC CONFIGURATION
# =============================================================================

variable "aws-region" {
  description = "AWS region for resources"
  type        = string
}

variable "env" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "cluster-name" {
  description = "EKS cluster name"
  type        = string
}

# =============================================================================
# NETWORKING
# =============================================================================

variable "vpc-cidr-block" {
  description = "VPC CIDR block"
  type        = string
}

variable "vpc-name" {
  description = "VPC name"
  type        = string
}

variable "igw-name" {
  description = "Internet Gateway name"
  type        = string
}

variable "pub-subnet-count" {
  description = "Number of public subnets"
  type        = number
}

variable "pub-cidr-block" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "pub-availability-zone" {
  description = "Public subnet availability zones"
  type        = list(string)
}

variable "pub-sub-name" {
  description = "Public subnet name prefix"
  type        = string
}

variable "pri-subnet-count" {
  description = "Number of private subnets"
  type        = number
}

variable "pri-cidr-block" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
}

variable "pri-availability-zone" {
  description = "Private subnet availability zones"
  type        = list(string)
}

variable "pri-sub-name" {
  description = "Private subnet name prefix"
  type        = string
}

variable "public-rt-name" {
  description = "Public route table name"
  type        = string
}

variable "private-rt-name" {
  description = "Private route table name"
  type        = string
}

variable "eip-name" {
  description = "Elastic IP name"
  type        = string
}

variable "ngw-name" {
  description = "NAT Gateway name"
  type        = string
}

variable "eks-sg" {
  description = "EKS security group name"
  type        = string
}

# =============================================================================
# EKS CLUSTER
# =============================================================================

variable "is-eks-cluster-enabled" {
  description = "Enable EKS cluster creation"
  type        = bool
}

variable "cluster-version" {
  description = "Kubernetes version"
  type        = string
}

variable "endpoint-private-access" {
  description = "Enable private API endpoint"
  type        = bool
}

variable "endpoint-public-access" {
  description = "Enable public API endpoint"
  type        = bool
}

# =============================================================================
# NODE GROUPS
# =============================================================================

variable "ondemand_instance_types" {
  description = "On-demand instance types"
  type        = list(string)
  default     = ["t3a.medium"]
}

variable "spot_instance_types" {
  description = "Spot instance types"
  type        = list(string)
}

variable "desired_capacity_on_demand" {
  description = "Desired on-demand nodes"
  type        = string
}

variable "min_capacity_on_demand" {
  description = "Minimum on-demand nodes"
  type        = string
}

variable "max_capacity_on_demand" {
  description = "Maximum on-demand nodes"
  type        = string
}

variable "desired_capacity_spot" {
  description = "Desired spot nodes"
  type        = string
}

variable "min_capacity_spot" {
  description = "Minimum spot nodes"
  type        = string
}

variable "max_capacity_spot" {
  description = "Maximum spot nodes"
  type        = string
}

# =============================================================================
# ADD-ONS
# =============================================================================

variable "addons" {
  description = "EKS add-ons to install"
  type = list(object({
    name    = string
    version = string
  }))
}