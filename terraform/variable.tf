variable "access_key" {
  description = "AWS access key"
  sensitive   = true
}

variable "secret_key" {
  description = "AWS secret key"
  sensitive   = true
}

variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "clustername" {
  default     = "staging"
  description = "EKS Cluster Name"
}

variable "spot_instance_types" {
  default     = ["t3.medium"]
  description = "SPOT instance types"
}

variable "spot_max_size" { default = 10 }
variable "spot_min_size" { default = 2 }
variable "spot_desired_size" { default = 2 }
