output "app_stack_instance_id" {
  description = "ID of the deployed EC2 instance"
  value       = module.app_stack.instance_id
}

output "app_stack_instance_public_ip" {
  description = "Public IP address of the deployed EC2 instance"
  value       = module.app_stack.instance_public_ip
}

output "app_stack_security_group_id" {
  description = "ID of the security group attached to the instance"
  value       = module.app_stack.security_group_id
}

output "deployment_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "deployment_timestamp" {
  description = "Timestamp of this Terraform deployment"
  value       = timestamp()
}
