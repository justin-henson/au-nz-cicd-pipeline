output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.app.private_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.app.id
}

output "instance_state" {
  description = "Current state of the EC2 instance"
  value       = aws_instance.app.instance_state
}
