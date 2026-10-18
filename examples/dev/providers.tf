provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "mhkhan01"
      Repository  = "https://github.com/mhkhan01/terraform-aws-vpc-foundation"
    }
  }
}
