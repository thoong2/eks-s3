provider "aws" {
  region = "ap-southeast-1" # Thay thế bằng region của bạn
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
