output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${aws_eks_cluster.eks_cluster.name}"
}
