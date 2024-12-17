variable "cluster_name" {
  description = "Tên của EKS Cluster"
  default     = "eks-demo-cluster"
}

variable "node_instance_type" {
  description = "Loại EC2 instance cho node"
  default     = "t2.micro"
}

variable "desired_capacity" {
  description = "Số lượng node mong muốn"
  default     = 2
}
