# =============================================================================
# PRODUCTION ENVIRONMENT CONFIGURATION
# =============================================================================

env        = "prod"
aws-region = "us-east-1"

# Network Configuration - Different CIDR for production
vpc-cidr-block        = "10.18.0.0/16"
vpc-name              = "vpc"
igw-name              = "igw"
pub-subnet-count      = 3
pub-cidr-block        = ["10.18.0.0/20", "10.18.16.0/20", "10.18.32.0/20"]
pub-availability-zone = ["us-east-1a", "us-east-1b", "us-east-1c"]
pub-sub-name          = "subnet-public"
pri-subnet-count      = 3
pri-cidr-block        = ["10.18.128.0/20", "10.18.144.0/20", "10.18.160.0/20"]
pri-availability-zone = ["us-east-1a", "us-east-1b", "us-east-1c"]
pri-sub-name          = "subnet-private"
public-rt-name        = "public-route-table"
private-rt-name       = "private-route-table"
eip-name              = "elasticip-ngw"
ngw-name              = "ngw"
eks-sg                = "eks-sg"

# EKS Configuration - Production (High availability, secure)
is-eks-cluster-enabled     = true
cluster-version            = "1.31"
cluster-name               = "eks-cluster"
endpoint-private-access    = true
endpoint-public-access     = false                       # Production should be private
ondemand_instance_types    = ["m5a.large", "m5a.xlarge"] # More powerful instances
spot_instance_types        = ["c5a.large", "c5a.xlarge", "m5a.large", "m5a.xlarge", "c5.large", "m5.large"]
desired_capacity_on_demand = "3" # Higher for production
min_capacity_on_demand     = "3"
max_capacity_on_demand     = "10"
desired_capacity_spot      = "3"
min_capacity_spot          = "2"
max_capacity_spot          = "20"

# EKS Add-ons - Same versions for consistency
addons = [
  {
    name    = "vpc-cni",
    version = "v1.19.2-eksbuild.1"
  },
  {
    name    = "coredns"
    version = "v1.11.4-eksbuild.1"
  },
  {
    name    = "kube-proxy"
    version = "v1.31.3-eksbuild.2"
  },
  {
    name    = "aws-ebs-csi-driver"
    version = "v1.38.1-eksbuild.1"
  }
]
