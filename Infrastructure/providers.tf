# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "grocery-shop"
      Environment = "development"
      ManagedBy   = "terraform"
    }
  }
}
