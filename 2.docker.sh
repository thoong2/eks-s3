aws ecr create-repository --repository-name my-app
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com

docker build -t my-app .
docker tag my-app:latest <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/my-app:latest
docker push <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/my-app:latest
