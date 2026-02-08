provider "aws" {
  region = var.aws_region

  # Default tags applied to all resources for cost tracking and governance
  default_tags {
    tags = {
      Project     = "au-nz-cicd-pipeline"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Repository  = "github.com/justin-henson/au-nz-cicd-pipeline"
      CostCenter  = "DevOps-Portfolio"
    }
  }
}
