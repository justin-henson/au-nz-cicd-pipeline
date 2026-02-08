# Backend configuration for Terraform state management
#
# PRODUCTION CONFIGURATION (currently commented for demo purposes):
# Uncomment and configure the following for production use with remote state:
#
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "cicd-pipeline/terraform.tfstate"
#     region         = "ap-southeast-2"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#
#     # Use this to enable state locking and consistency checking
#     # DynamoDB table must have a primary key named "LockID" (String)
#   }
# }
#
# SETUP INSTRUCTIONS:
#
# 1. Create S3 bucket for state storage:
#    aws s3 mb s3://your-terraform-state-bucket --region ap-southeast-2
#    aws s3api put-bucket-versioning --bucket your-terraform-state-bucket \
#      --versioning-configuration Status=Enabled
#    aws s3api put-bucket-encryption --bucket your-terraform-state-bucket \
#      --server-side-encryption-configuration \
#      '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
#
# 2. Create DynamoDB table for state locking:
#    aws dynamodb create-table \
#      --table-name terraform-state-lock \
#      --attribute-definitions AttributeName=LockID,AttributeType=S \
#      --key-schema AttributeName=LockID,KeyType=HASH \
#      --billing-mode PAY_PER_REQUEST \
#      --region ap-southeast-2
#
# 3. Initialize Terraform with backend:
#    terraform init -backend-config="bucket=your-terraform-state-bucket"
#
# WHY S3 + DYNAMODB:
# - S3 provides durable, versioned state storage
# - DynamoDB enables state locking to prevent concurrent modifications
# - Encryption at rest protects sensitive data in state files
# - Versioning allows state rollback if needed
#
# DEMO CONFIGURATION:
# For this demo, we use local state (default).
# In CI/CD, each workflow run gets a fresh state unless backend is configured.
# This is acceptable for demo purposes but NOT for production.
