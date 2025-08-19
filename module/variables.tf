# =============================================================================
# GENERAL VARIABLES
# =============================================================================

variable "cluster-name" {
  description = "Name of the EKS cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.cluster-name)) && length(var.cluster-name) <= 100
    error_message = "Cluster name must start with a letter, contain only alphanumeric characters and hyphens, and be less than 100 characters."
  }
}

variable "env" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "test"], var.env)
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}

# =============================================================================
# VPC VARIABLES
# =============================================================================

variable "cidr-block" {
  description = "CIDR block for VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr-block, 0))
    error_message = "VPC CIDR block must be a valid IPv4 CIDR."
  }
}

variable "vpc-name" {
  description = "Name of the VPC"
  type        = string
}

variable "igw-name" {
  description = "Name of the Internet Gateway"
  type        = string
}

# =============================================================================
# PUBLIC SUBNET VARIABLES
# =============================================================================

variable "pub-subnet-count" {
  description = "Number of public subnets"
  type        = number

  validation {
    condition     = var.pub-subnet-count >= 2 && var.pub-subnet-count <= 6
    error_message = "Public subnet count must be between 2 and 6 for high availability."
  }
}

variable "pub-cidr-block" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)

  validation {
    condition     = alltrue([for cidr in var.pub-cidr-block : can(cidrhost(cidr, 0))])
    error_message = "All public subnet CIDR blocks must be valid IPv4 CIDRs."
  }
}

variable "pub-availability-zone" {
  description = "List of availability zones for public subnets"
  type        = list(string)

  validation {
    condition     = length(var.pub-availability-zone) >= 2
    error_message = "At least 2 availability zones are required for high availability."
  }
}

variable "pub-sub-name" {
  description = "Base name for public subnets"
  type        = string
}

# =============================================================================
# PRIVATE SUBNET VARIABLES
# =============================================================================

variable "pri-subnet-count" {
  description = "Number of private subnets"
  type        = number

  validation {
    condition     = var.pri-subnet-count >= 2 && var.pri-subnet-count <= 6
    error_message = "Private subnet count must be between 2 and 6 for high availability."
  }
}

variable "pri-cidr-block" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)

  validation {
    condition     = alltrue([for cidr in var.pri-cidr-block : can(cidrhost(cidr, 0))])
    error_message = "All private subnet CIDR blocks must be valid IPv4 CIDRs."
  }
}

variable "pri-availability-zone" {
  description = "List of availability zones for private subnets"
  type        = list(string)

  validation {
    condition     = length(var.pri-availability-zone) >= 2
    error_message = "At least 2 availability zones are required for high availability."
  }
}

variable "pri-sub-name" {
  description = "Base name for private subnets"
  type        = string
}

# =============================================================================
# ROUTING VARIABLES
# =============================================================================

variable "public-rt-name" {
  description = "Name of the public route table"
  type        = string
}

variable "private-rt-name" {
  description = "Name of the private route table"
  type        = string
}

variable "eip-name" {
  description = "Name of the Elastic IP for NAT Gateway"
  type        = string
}

variable "ngw-name" {
  description = "Name of the NAT Gateway"
  type        = string
}

# =============================================================================
# SECURITY GROUP VARIABLES
# =============================================================================

variable "eks-sg" {
  description = "Name of the EKS security group"
  type        = string
}

# =============================================================================
# IAM VARIABLES
# =============================================================================

variable "is_eks_role_enabled" {
  description = "Whether to create EKS cluster IAM role"
  type        = bool
  default     = true
}

variable "is_eks_nodegroup_role_enabled" {
  description = "Whether to create EKS node group IAM role"
  type        = bool
  default     = true
}

# =============================================================================
# EKS CLUSTER VARIABLES
# =============================================================================

variable "is-eks-cluster-enabled" {
  description = "Whether to create the EKS cluster"
  type        = bool
  default     = true
}

variable "cluster-version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string

  validation {
    condition     = can(regex("^1\\.(2[4-9]|3[0-9])$", var.cluster-version))
    error_message = "Cluster version must be a valid Kubernetes version (e.g., 1.24, 1.25, etc.)."
  }
}

variable "endpoint-private-access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint-public-access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

# =============================================================================
# EKS ADD-ONS VARIABLES
# =============================================================================

variable "addons" {
  description = "Map of cluster addon configurations to enable for the cluster"
  type = list(object({
    name    = string
    version = string
  }))
  default = []

  validation {
    condition = alltrue([
      for addon in var.addons : contains([
        "vpc-cni", "coredns", "kube-proxy", "aws-ebs-csi-driver",
        "aws-efs-csi-driver", "aws-load-balancer-controller"
      ], addon.name)
    ])
    error_message = "Addon names must be valid EKS addon names."
  }
}

# =============================================================================
# NODE GROUP VARIABLES - ON-DEMAND
# =============================================================================

variable "ondemand_instance_types" {
  description = "List of instance types for on-demand node group"
  type        = list(string)
  default     = ["t3a.medium"]

  validation {
    condition     = length(var.ondemand_instance_types) > 0
    error_message = "At least one instance type must be specified for on-demand nodes."
  }
}

variable "desired_capacity_on_demand" {
  description = "Desired number of on-demand nodes"
  type        = string

  validation {
    condition     = can(tonumber(var.desired_capacity_on_demand)) && tonumber(var.desired_capacity_on_demand) >= 1
    error_message = "Desired capacity for on-demand nodes must be at least 1."
  }
}

variable "min_capacity_on_demand" {
  description = "Minimum number of on-demand nodes"
  type        = string

  validation {
    condition     = can(tonumber(var.min_capacity_on_demand)) && tonumber(var.min_capacity_on_demand) >= 1
    error_message = "Minimum capacity for on-demand nodes must be at least 1."
  }
}

variable "max_capacity_on_demand" {
  description = "Maximum number of on-demand nodes"
  type        = string

  validation {
    condition     = can(tonumber(var.max_capacity_on_demand)) && tonumber(var.max_capacity_on_demand) >= 1
    error_message = "Maximum capacity for on-demand nodes must be at least 1."
  }
}

# =============================================================================
# NODE GROUP VARIABLES - SPOT
# =============================================================================

variable "spot_instance_types" {
  description = "List of instance types for spot node group"
  type        = list(string)

  validation {
    condition     = length(var.spot_instance_types) > 0
    error_message = "At least one instance type must be specified for spot nodes."
  }
}

variable "desired_capacity_spot" {
  description = "Desired number of spot nodes"
  type        = string

  validation {
    condition     = can(tonumber(var.desired_capacity_spot)) && tonumber(var.desired_capacity_spot) >= 0
    error_message = "Desired capacity for spot nodes must be 0 or greater."
  }
}

variable "min_capacity_spot" {
  description = "Minimum number of spot nodes"
  type        = string

  validation {
    condition     = can(tonumber(var.min_capacity_spot)) && tonumber(var.min_capacity_spot) >= 0
    error_message = "Minimum capacity for spot nodes must be 0 or greater."
  }
}

variable "max_capacity_spot" {
  description = "Maximum number of spot nodes"
  type        = string

  validation {
    condition     = can(tonumber(var.max_capacity_spot)) && tonumber(var.max_capacity_spot) >= 0
    error_message = "Maximum capacity for spot nodes must be 0 or greater."
  }
}