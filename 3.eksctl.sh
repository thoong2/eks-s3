eksctl utils associate-iam-oidc-provider --region=ap-southeast-1 --cluster=eks-demo-cluster --approve


eksctl create iamserviceaccount \
  --name s3-access-sa \
  --namespace default \
  --cluster eks-demo-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
  --approve
