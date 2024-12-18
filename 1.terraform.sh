terraform init
terraform plan -out=eks-plan.tfplan
terraform apply "eks-plan.tfplan"
aws eks update-kubeconfig --name eks-demo-cluster
