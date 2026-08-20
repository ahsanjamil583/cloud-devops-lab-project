# ------------------------------------------------------------
# Phase 4 - IAM Role and Instance Profile
# ------------------------------------------------------------

resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}


# CloudWatch access required by the internship project.
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}


# S3 access required by the internship project.
#
# We use read-only access here rather than S3 Full Access.
# In the final security-hardening phase we can narrow this
# further to only the exact application bucket/prefix required.
resource "aws_iam_role_policy_attachment" "s3_readonly" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}


# EC2 cannot attach a role directly.
# It receives it through an instance profile.
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}
