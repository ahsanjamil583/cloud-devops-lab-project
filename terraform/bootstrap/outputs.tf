output "state_bucket_name" {
  description = "S3 bucket used for Terraform remote state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB table used for Terraform state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "aws_region" {
  description = "AWS region containing the backend resources"
  value       = var.aws_region
}

output "aws_account_id" {
  description = "AWS account hosting the lab"
  value       = data.aws_caller_identity.current.account_id
}
