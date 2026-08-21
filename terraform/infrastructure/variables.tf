variable "aws_region" {
  description = "AWS region for the project"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Common project name used for AWS resources"
  type        = string
  default     = "cloud-devops-lab-project"
}

variable "trusted_ssh_cidr" {
  description = "Public IPv4 CIDR allowed to SSH into the management host"
  type        = string
}

variable "management_instance_type" {
  description = "EC2 instance type for Bastion/DevOps management host"
  type        = string
  default     = "m7i-flex.large"
}

variable "app_instance_type" {
  description = "EC2 instance type for private application server"
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key on the Terraform control machine"
  type        = string
  default     = "~/.ssh/cloud-devops-lab-project.pub"
}
