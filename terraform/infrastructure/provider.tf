provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      Project     = "cloud-devops-lab-project"
      Environment = "lab"
      ManagedBy   = "Terraform"
    }
  }
}
