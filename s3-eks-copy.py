import boto3

def download_s3_bucket():
  s3 = boto3.client('s3')
  s3.download_file("s3-eks-test-bucket", "k8s-session.txt", "k8s-session.txt")

download_s3_bucket()
