terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "3.0.1"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

# VPC
resource "aws_vpc" "StagingVpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Staging VPC"
  }
}

resource "aws_subnet" "PublicSubnet01Block" {
  vpc_id            = aws_vpc.StagingVpc.id
  cidr_block        = "10.0.0.0/18"
  availability_zone = "us-east-1a"

  tags = {
    Name                     = "Staging Public Subnet 1",
    "PrivateSubnet01"        = "PrivateSubnet01Block",
    "kubernetes.io/role/elb" = "1"
  }
}
resource "aws_subnet" "PublicSubnet02Block" {
  vpc_id            = aws_vpc.StagingVpc.id
  cidr_block        = "10.0.64.0/18"
  availability_zone = "us-east-1c"

  tags = {
    Name                     = "Staging Public Subnet 2",
    "PrivateSubnet02"        = "PrivateSubnet02Block",
    "kubernetes.io/role/elb" = "1"
  }
}
resource "aws_subnet" "PrivateSubnet03Block" {
  vpc_id            = aws_vpc.StagingVpc.id
  cidr_block        = "10.0.128.0/18"
  availability_zone = "us-east-1a"

  tags = {
    Name                              = "Staging Private Subnet 1",
    "PrivateSubnet03"                 = "PrivateSubnet03Block",
    "kubernetes.io/role/internal-elb" = "1"
  }
}
resource "aws_subnet" "PrivateSubnet04Block" {
  vpc_id            = aws_vpc.StagingVpc.id
  cidr_block        = "10.0.192.0/18"
  availability_zone = "us-east-1c"

  tags = {
    Name                              = "Staging Private Subnet 2",
    "PrivateSubnet04"                 = "PrivateSubnet04Block",
    "kubernetes.io/role/internal-elb" = "1"
  }
}

#internet gateway
resource "aws_internet_gateway" "InternetGateway" {
  vpc_id = aws_vpc.StagingVpc.id
  tags = {
    Name = "Staging Internet Gateway"
  }
}


resource "aws_route_table" "PublicRouteTable" {
  vpc_id = aws_vpc.StagingVpc.id
  tags = {
    "Network" = "Public",
    "Name" = "Staging Public Route Table"
  }
}

resource "aws_route_table" "PrivateRouteTable01" {
  vpc_id = aws_vpc.StagingVpc.id
  tags = {
    "Network" = "Private01",
    "Name" = "Staging Private Route Table 1"
  }
}
resource "aws_route_table" "PrivateRouteTable02" {
  vpc_id = aws_vpc.StagingVpc.id
  tags = {
    "Network" = "Private02",
    "Name" = "Staging Private Route Table 2"
  }
}

resource "aws_eip" "EIP1" {
  vpc = true
  tags = {
    Name = "Staging NAT IP 1"
  }
}

resource "aws_eip" "EIP2" {
  vpc = true
  tags = {
    Name = "Staging NAT IP 2"
  }
}

resource "aws_nat_gateway" "NatGateway01" {
  allocation_id = aws_eip.EIP1.id
  subnet_id     = aws_subnet.PublicSubnet01Block.id
  tags = {
    Name = "Staging NAT Gateway 1"
  }
}

resource "aws_nat_gateway" "NatGateway02" {
  allocation_id = aws_eip.EIP2.id
  subnet_id     = aws_subnet.PublicSubnet02Block.id
  tags = {
    Name = "Staging NAT Gateway 2"
  }
}

resource "aws_route" "PublicRoute" {
  route_table_id            = aws_route_table.PublicRouteTable.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.InternetGateway.id
}

resource "aws_route" "PrivateRoute01" {
  route_table_id            = aws_route_table.PrivateRouteTable01.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.NatGateway01.id
}

resource "aws_route" "PrivateRoute02" {
  route_table_id            = aws_route_table.PrivateRouteTable02.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.NatGateway02.id
}

resource "aws_route_table_association" "PublicSubnet01RouteTableAssociation" {
  subnet_id = aws_subnet.PublicSubnet01Block.id
  route_table_id = aws_route_table.PublicRouteTable.id
}

resource "aws_route_table_association" "PublicSubnet02RouteTableAssociation" {
  subnet_id = aws_subnet.PublicSubnet02Block.id
  route_table_id = aws_route_table.PublicRouteTable.id
}

resource "aws_route_table_association" "PrivateSubnet01RouteTableAssociation" {
  subnet_id = aws_subnet.PrivateSubnet03Block.id
  route_table_id = aws_route_table.PrivateRouteTable01.id
}

resource "aws_route_table_association" "PrivateSubnet02RouteTableAssociation" {
  subnet_id = aws_subnet.PrivateSubnet04Block.id
  route_table_id = aws_route_table.PrivateRouteTable02.id
}


resource "aws_security_group" "ControlPlaneSecurityGroup" {
  name        = "StagingControlPlaneSecurityGroup"
  description = "Staging Cluster communication with worker nodes"
  vpc_id      = aws_vpc.StagingVpc.id
  tags = {
    Name = "Staging Security Group"
  }
}

###### Cluster
resource "aws_iam_role" "clusterRole" {
  name = "stagingSa"

  assume_role_policy = <<POLICY
{
"Version": "2012-10-17",
"Statement": [
    {
        "Effect": "Allow",
        "Principal": {
            "Service": "eks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
    }
]
}
  POLICY
}

resource "aws_iam_role_policy_attachment" "clusterroleAmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.clusterRole.name
}

resource "aws_iam_role_policy_attachment" "clusterroleAmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.clusterRole.name
}


###### Nodegroup
resource "aws_iam_role" "StagingNoderole" {
  name = "eksNodeGroupStaging"


  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "StagingAmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.StagingNoderole.name
}

resource "aws_iam_role_policy_attachment" "StagingAmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.StagingNoderole.name
}

resource "aws_iam_role_policy_attachment" "StagingAmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.StagingNoderole.name
}

resource "aws_eks_cluster" "Staging" {
  name     = var.clustername
  role_arn = aws_iam_role.clusterRole.arn
  # version = "1.22"
  
  vpc_config {
    endpoint_private_access = true
    subnet_ids      = [aws_subnet.PublicSubnet01Block.id, aws_subnet.PublicSubnet02Block.id, aws_subnet.PrivateSubnet03Block.id, aws_subnet.PrivateSubnet04Block.id]
  #  security_group_ids = [aws_security_group.ControlPlaneSecurityGroup.id]
  }
  depends_on = [
    aws_iam_role_policy_attachment.clusterroleAmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.clusterroleAmazonEKSVPCResourceController,
  ]
}


resource "aws_eks_node_group" "StagingSpotNodeGgroup" {
  cluster_name    = aws_eks_cluster.Staging.name
  node_group_name = "spotnodegroup"
  node_role_arn   = aws_iam_role.StagingNoderole.arn
  subnet_ids      = [aws_subnet.PrivateSubnet03Block.id, aws_subnet.PrivateSubnet04Block.id]
  instance_types  = var.spot_instance_types
  capacity_type   = "SPOT"

  scaling_config {
    desired_size = var.spot_desired_size
    max_size     = var.spot_max_size
    min_size     = var.spot_min_size
  }
  
#   labels = {
#     "node.kubernetes.io/lifecycle" = "spot"
#   }
  
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
################################################################
# OIDC Provider Thumbprint
data "tls_certificate" "staging_thumbprint" {
  url = aws_eks_cluster.Staging.identity[0].oidc[0].issuer
}

# OIDC Provider for IRSA
resource "aws_iam_openid_connect_provider" "staging_oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.staging_thumbprint.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.Staging.identity[0].oidc[0].issuer
}

# IAM Trust Policy for EBS CSI Driver
data "aws_iam_policy_document" "ebs_csi_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringLike"
      variable = "${replace(aws_iam_openid_connect_provider.staging_oidc_provider.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${replace(aws_iam_openid_connect_provider.staging_oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.staging_oidc_provider.arn]
    }
  }
}

# IAM Role for EBS CSI Driver
resource "aws_iam_role" "ebs_csi_driver_role_staging" {
  name               = "AmazonEKS_EBS_CSI_DriverRole_Staging"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role_policy.json
}

# Attach EBS CSI Driver Policy
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver_role_staging.name
}

# Install EBS CSI Driver as Addon
resource "aws_eks_addon" "ebs_csi_driver_addon" {
  cluster_name             = aws_eks_cluster.Staging.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.32.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_driver_role_staging.arn
}

### outputs
output "nat_gateway_eips" {
  description = "EIP addresses assigned to NAT Gateways"
  value = {
    nat_gateway_1 = aws_eip.EIP1.public_ip
    nat_gateway_2 = aws_eip.EIP2.public_ip
  }
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.Staging.name
  # sensitive = true
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = aws_eks_cluster.Staging.endpoint
}

output "eks_cluster_security_group" {
  description = "The security group attached to the EKS cluster"
  value       = aws_security_group.ControlPlaneSecurityGroup.id
}

output "eks_node_group_subnets" {
  description = "The private subnets used by the EKS node group"
  value       = aws_eks_node_group.StagingSpotNodeGgroup.subnet_ids
}