# Terraform settings and required provider versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.49.0"
    }
  }

  required_version = ">= 1.2"
}
