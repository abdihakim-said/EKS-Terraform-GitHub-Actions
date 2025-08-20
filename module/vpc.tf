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
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.vpc-name}-flow-logs"
  })
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

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = var.eks-sg
  })

  # Ensure VPC is created first
  depends_on = [aws_vpc.vpc]
}