Dưới đây là hướng dẫn chi tiết hơn với thông tin cụ thể cần thay thế trong các file cấu hình Terraform, Dockerfile và Kubernetes YAML. Tôi cũng sẽ sử dụng VPC mặc định để đơn giản hóa.

1. Chuẩn bị thông tin
Trước khi bắt đầu, bạn cần xác định và chuẩn bị các thông tin sau:

AWS Account ID:

Lấy từ AWS CLI:
bash
Copy code
aws sts get-caller-identity
Trường Account sẽ là AWS Account ID của bạn.
AWS Region:

Ví dụ: us-east-1. Bạn có thể thay đổi sang region khác nếu cần.
S3 Bucket Name:

Tạo một S3 bucket hoặc dùng bucket có sẵn:
bash
Copy code
aws s3 mb s3://my-eks-demo-bucket
ECR Repository Name:

Tên repository sẽ là my-app.
2. Khởi tạo EKS Cluster với Terraform
Cấu trúc thư mục
plaintext
Copy code
eks-cluster/
│
├── provider.tf
├── variables.tf
├── main.tf
├── outputs.tf
└── eksctl-commands.sh
File provider.tf
Cấu hình provider cho AWS:

hcl
Copy code
provider "aws" {
  region = "us-east-1" # Thay thế bằng region của bạn
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
File variables.tf
Khai báo các biến:

hcl
Copy code
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
File main.tf
Sử dụng VPC mặc định và khởi tạo EKS Cluster:

hcl
Copy code
# Lấy VPC mặc định
data "aws_vpc" "default" {
  default = true
}

# Lấy subnet mặc định trong VPC
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
    subnet_ids = data.aws_subnets.default.ids
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
}
File outputs.tf
In ra thông tin kết quả:

hcl
Copy code
output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${aws_eks_cluster.eks_cluster.name}"
}
Chạy Terraform
Khởi tạo Terraform:

bash
Copy code
terraform init
Xem trước kế hoạch:

bash
Copy code
terraform plan
Áp dụng cấu hình:

bash
Copy code
terraform apply
Cập nhật kubeconfig:

bash
Copy code
aws eks update-kubeconfig --name eks-demo-cluster
3. Tạo Docker Image và Push lên AWS ECR
File Dockerfile
Dockerfile
Copy code
FROM amazonlinux:2

RUN yum install -y aws-cli

COPY script.sh /app/script.sh
RUN chmod +x /app/script.sh

CMD ["/app/script.sh"]
File script.sh
bash
Copy code
#!/bin/bash
echo "Downloading file from S3..."
aws s3 cp s3://my-eks-demo-bucket/my-file.txt /tmp/my-file.txt
echo "File downloaded successfully!"
Push Docker Image lên ECR
Tạo repository trên ECR:

bash
Copy code
aws ecr create-repository --repository-name my-app
Đăng nhập vào ECR:

bash
Copy code
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
Build và push Docker image:

bash
Copy code
docker build -t my-app .
docker tag my-app:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
4. Triển khai Deployment trên EKS
Tạo Service Account IRSA
bash
Copy code
eksctl create iamserviceaccount \
  --name s3-access-sa \
  --namespace default \
  --cluster eks-demo-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
  --approve
File deployment.yaml
yaml
Copy code
apiVersion: apps/v1
kind: Deployment
metadata:
  name: s3-access-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: s3-access
  template:
    metadata:
      labels:
        app: s3-access
    spec:
      serviceAccountName: s3-access-sa
      containers:
      - name: s3-access-container
        image: <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
Triển khai Deployment
bash
Copy code
kubectl apply -f deployment.yaml
5. Tạo S3 VPC Endpoint
Tạo VPC endpoint cho S3:

bash
Copy code
aws ec2 create-vpc-endpoint \
  --vpc-id <vpc-id> \
  --service-name com.amazonaws.us-east-1.s3 \
  --route-table-ids <route-table-id>
Kiểm tra log pod:

bash
Copy code
kubectl logs -l app=s3-access
Tóm tắt các thông tin cần thay thế
<account-id>: AWS Account ID.
my-eks-demo-bucket: Tên S3 bucket.
us-east-1: Region của bạn.
<vpc-id> và <route-table-id>: Thông tin VPC mặc định (lấy từ AWS Console hoặc CLI).
Sau khi hoàn tất các bước trên, pod sẽ truy cập S3 bucket thành công thông qua IAM Role for Service Account (IRSA) và S3 VPC Endpoint.