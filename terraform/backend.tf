terraform {
  backend "s3" {
    # These values will be provided by backend.tfvars during terraform init
    # bucket = "your-terraform-state-bucket"
    # key    = "eks/staging/terraform.tfstate"
    # region = "us-east-1"
  }
}