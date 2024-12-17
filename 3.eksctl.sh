eksctl create iamserviceaccount \
  --name s3-access-sa \
  --namespace default \
  --cluster eks-demo-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
  --approve
