provider "aws" {
  region = var.aws_region

  # Default tags applied to all resources for cost tracking and governance
  default_tags {
    tags = {
      Project     = "cicd-pipeline"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Repository  = "github.com/justin-henson/cicd-pipeline"
      CostCenter  = "DevOps-Portfolio"
    }
  }
}
