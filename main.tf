# Lấy VPC mặc định
data "aws_vpc" "default" {
  default = true
}

# Lấy các subnet trong VPC mặc định
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Tạo IAM Role cho EKS
resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Principal = { Service = "eks.amazonaws.com" },
      Effect    = "Allow",
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Tạo EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids  # Sử dụng các subnet của VPC mặc định
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# Node Group
resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks-node-group"
  node_role_arn   = aws_iam_role.eks_role.arn

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = 2
    min_size     = 2
  }

  instance_types = [var.node_instance_type]

  subnet_ids = data.aws_subnets.default.ids  # Cung cấp subnet cho node group
}
