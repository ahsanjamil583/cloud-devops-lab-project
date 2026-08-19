variable "aws_region" {
  description = "AWS region for the DevOps lab"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "cloud-devops-lab-project"
}
