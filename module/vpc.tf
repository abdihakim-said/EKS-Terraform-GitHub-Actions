# =============================================================================
# LOCAL VALUES
# =============================================================================

locals {
  cluster-name = var.cluster-name

  # Common tags to be assigned to all resources
  common_tags = {
    Environment                                   = var.env
    Project                                       = "EKS-Cluster"
    ManagedBy                                     = "Terraform"
    "kubernetes.io/cluster/${local.cluster-name}" = "owned"
  }
}

# =============================================================================
# VPC
# =============================================================================

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr-block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = var.vpc-name
  })
}

# Restrict default security group to deny all traffic
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id

  # Remove all default rules - no ingress or egress allowed
  ingress = []
  egress  = []

  tags = merge(local.common_tags, {
    Name = "${var.vpc-name}-default-sg-restricted"
  })
}

# VPC Flow Logs for security monitoring
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.vpc.id

  tags = merge(local.common_tags, {
    Name = "${var.vpc-name}-flow-logs"
  })
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flowlogs/${var.vpc-name}"
  retention_in_days = 365  # 1 year retention for compliance
  kms_key_id        = aws_kms_key.vpc_flow_log_key.arn

  tags = merge(local.common_tags, {
    Name = "${var.vpc-name}-flow-logs"
  })
}

# KMS Key for CloudWatch Log Group encryption
resource "aws_kms_key" "vpc_flow_log_key" {
  description             = "KMS key for VPC Flow Logs encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true  # Enable automatic key rotation

  # Explicit key policy for security compliance
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vpc/flowlogs/${var.vpc-name}"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.vpc-name}-flow-log-key"
  })
}

# Data sources for account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# KMS Key Alias
resource "aws_kms_alias" "vpc_flow_log_key_alias" {
  name          = "alias/${var.vpc-name}-flow-log-key"
  target_key_id = aws_kms_key.vpc_flow_log_key.key_id
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "flow_log_role" {
  name = "${var.vpc-name}-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.vpc-name}-flow-log-role"
  })
}

# IAM Policy for VPC Flow Logs
resource "aws_iam_role_policy" "flow_log_policy" {
  name = "${var.vpc-name}-flow-log-policy"
  role = aws_iam_role.flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect = "Allow"
        Resource = "${aws_cloudwatch_log_group.vpc_flow_log.arn}:*"
      }
    ]
  })
}

# =============================================================================
# INTERNET GATEWAY
# =============================================================================

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags, {
    Name = var.igw-name
  })

  depends_on = [aws_vpc.vpc]
}

# =============================================================================
# PUBLIC SUBNETS
# =============================================================================

resource "aws_subnet" "public-subnet" {
  count                   = var.pub-subnet-count
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(var.pub-cidr-block, count.index)
  availability_zone       = element(var.pub-availability-zone, count.index)
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name                     = "${var.pub-sub-name}-${count.index + 1}"
    Type                     = "Public"
    "kubernetes.io/role/elb" = "1"
  })

  depends_on = [aws_vpc.vpc]
}

# =============================================================================
# PRIVATE SUBNETS
# =============================================================================

resource "aws_subnet" "private-subnet" {
  count                   = var.pri-subnet-count
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(var.pri-cidr-block, count.index)
  availability_zone       = element(var.pri-availability-zone, count.index)
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name                              = "${var.pri-sub-name}-${count.index + 1}"
    Type                              = "Private"
    "kubernetes.io/role/internal-elb" = "1"
  })

  depends_on = [aws_vpc.vpc]
}

# =============================================================================
# PUBLIC ROUTE TABLE
# =============================================================================

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, {
    Name = var.public-rt-name
    Type = "Public"
  })

  depends_on = [aws_vpc.vpc, aws_internet_gateway.igw]
}

# =============================================================================
# PUBLIC ROUTE TABLE ASSOCIATIONS
# =============================================================================

resource "aws_route_table_association" "public-rt-association" {
  count          = var.pub-subnet-count # Fixed: Use variable instead of hardcoded value
  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.public-subnet[count.index].id

  depends_on = [
    aws_vpc.vpc,
    aws_subnet.public-subnet,
    aws_route_table.public-rt
  ]
}

# =============================================================================
# ELASTIC IP FOR NAT GATEWAY
# =============================================================================

resource "aws_eip" "ngw-eip" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = var.eip-name
  })

  depends_on = [aws_internet_gateway.igw]
}

# =============================================================================
# NAT GATEWAY
# =============================================================================

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw-eip.id
  subnet_id     = aws_subnet.public-subnet[0].id

  tags = merge(local.common_tags, {
    Name = var.ngw-name
  })

  depends_on = [
    aws_vpc.vpc,
    aws_eip.ngw-eip,
    aws_subnet.public-subnet
  ]
}

# =============================================================================
# PRIVATE ROUTE TABLE
# =============================================================================

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = merge(local.common_tags, {
    Name = var.private-rt-name
    Type = "Private"
  })

  depends_on = [aws_vpc.vpc, aws_nat_gateway.ngw]
}

# =============================================================================
# PRIVATE ROUTE TABLE ASSOCIATIONS
# =============================================================================

resource "aws_route_table_association" "private-rt-association" {
  count          = var.pri-subnet-count # Fixed: Use variable instead of hardcoded value
  route_table_id = aws_route_table.private-rt.id
  subnet_id      = aws_subnet.private-subnet[count.index].id

  depends_on = [
    aws_vpc.vpc,
    aws_subnet.private-subnet,
    aws_route_table.private-rt
  ]
}

# =============================================================================
# SECURITY GROUP FOR EKS CLUSTER
# =============================================================================

resource "aws_security_group" "eks-cluster-sg" {
  name_prefix = "${var.eks-sg}-" # Use name_prefix for uniqueness
  description = "Security group for EKS cluster control plane"
  vpc_id      = aws_vpc.vpc.id

  # HTTPS access for EKS API server
  ingress {
    description = "HTTPS access to EKS API server"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # SECURITY IMPROVEMENT: Restrict to specific CIDR blocks
    # Replace with your organization's IP ranges or VPC CIDR
    cidr_blocks = [var.cidr-block] # Only allow access from within VPC
  }

  # More restrictive egress rules
  # HTTPS for AWS API calls
  egress {
    description = "HTTPS for AWS services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP for package updates and container registries
  egress {
    description = "HTTP for package updates"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS resolution
  egress {
    description = "DNS resolution"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NTP for time synchronization
  egress {
    description = "NTP time sync"
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Internal VPC communication
  egress {
    description = "Internal VPC communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.cidr-block]
  }

  tags = merge(local.common_tags, {
    Name = var.eks-sg
  })

  # Ensure VPC is created first
  depends_on = [aws_vpc.vpc]
}