# Terraform Remote Backend

## Purpose

Terraform state for the main AWS infrastructure is stored remotely instead of relying on local state.

## Architecture

```text
Terraform CLI
    |
    +---- State ----> Amazon S3
    |
    +---- Lock -----> DynamoDB
    |
    +---- Lock -----> S3 Lockfile
Backend Resources
S3 bucket for Terraform state
S3 bucket versioning enabled
S3 server-side encryption enabled
S3 public access blocked
DynamoDB table for internship-required state locking
DynamoDB partition key: LockID (String)
State Path
infrastructure/terraform.tfstate
Bootstrap

The backend resources are created separately under:

terraform/bootstrap/

The main infrastructure uses:

terraform/infrastructure/

This solves the backend bootstrap dependency where the remote backend must exist before the main Terraform configuration can use it.

Locking Note

The internship specification requires DynamoDB state locking. The project also enables the S3 backend lockfile mechanism for compatibility with current Terraform versions.
