# Root module composing child modules
#
# This demonstrates modular Terraform design:
# - Root module handles variable inputs and outputs
# - Child modules encapsulate resource logic
# - Enables reusability and testing of modules independently

# Data source to get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# App stack module: demonstrates a simple application deployment
module "app_stack" {
  source = "./modules/app-stack"

  # Pass variables from root to module
  project_name      = var.project_name
  environment       = var.environment
  instance_type     = var.instance_type
  ami_id            = data.aws_ami.amazon_linux_2.id
  allowed_ssh_cidr  = var.allowed_ssh_cidr
  enable_monitoring = var.enable_monitoring

  # Merge common tags with module-specific tags
  tags = merge(
    var.common_tags,
    {
      Module = "app-stack"
    }
  )
}

# This is a minimal example for demo purposes.
# In a real pipeline, you might have additional modules:
# - Network module (VPC, subnets, route tables)
# - Database module (RDS, ElastiCache)
# - Monitoring module (CloudWatch dashboards, alarms)
# - Load balancer module (ALB, target groups)
#
# Each module would be tested independently and composed here.
