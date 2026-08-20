# ------------------------------------------------------------
# Phase 4 - Outputs
# ------------------------------------------------------------

output "ubuntu_ami_id" {
  description = "Ubuntu AMI used for Phase 4 EC2 instances"
  value       = data.aws_ami.ubuntu.id
}

output "management_instance_id" {
  description = "Management/Bastion EC2 instance ID"
  value       = aws_instance.management.id
}

output "management_public_ip" {
  description = "Public IPv4 address of Management/Bastion EC2"
  value       = aws_instance.management.public_ip
}

output "management_private_ip" {
  description = "Private IPv4 address of Management/Bastion EC2"
  value       = aws_instance.management.private_ip
}

output "app_instance_id" {
  description = "Private application EC2 instance ID"
  value       = aws_instance.app.id
}

output "app_private_ip" {
  description = "Private IPv4 address of application EC2"
  value       = aws_instance.app.private_ip
}

output "management_security_group_id" {
  value = aws_security_group.management.id
}

output "app_security_group_id" {
  value = aws_security_group.app.id
}

output "ec2_iam_role_name" {
  value = aws_iam_role.ec2.name
}
