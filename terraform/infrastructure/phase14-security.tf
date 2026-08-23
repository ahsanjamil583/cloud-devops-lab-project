data "aws_caller_identity" "phase14" {}


# ============================================================
# Management EC2 dedicated IAM role
# ============================================================

resource "aws_iam_role" "management_ci" {
  name = "${var.project_name}-management-ci-role"

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
    Name = "${var.project_name}-management-ci-role"
  }
}


resource "aws_iam_instance_profile" "management_ci" {
  name = "${var.project_name}-management-ci-profile"
  role = aws_iam_role.management_ci.name
}


# ============================================================
# Preserve Management EC2 CloudWatch permissions
# ============================================================

resource "aws_iam_role_policy_attachment" "management_cloudwatch" {
  role       = aws_iam_role.management_ci.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}


# ============================================================
# Preserve original S3 read-only requirement
# ============================================================

resource "aws_iam_role_policy_attachment" "management_s3_readonly" {
  role       = aws_iam_role.management_ci.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}


# ============================================================
# Jenkins can read ONLY explicitly approved SSM parameters
# ============================================================

resource "aws_iam_role_policy" "management_jenkins_ssm_read" {
  name = "${var.project_name}-jenkins-ssm-read"

  role = aws_iam_role.management_ci.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadJenkinsParameters"
        Effect = "Allow"

        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]

        Resource = [
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.phase14.account_id}:parameter/cloud-devops-lab/jenkins/dockerhub/username",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.phase14.account_id}:parameter/cloud-devops-lab/jenkins/dockerhub/token",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.phase14.account_id}:parameter/cloud-devops-lab/jenkins/deploy/ssh_private_key",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.phase14.account_id}:parameter/cloud-devops-lab/jenkins/sonar/token"
        ]
      }
    ]
  })
}


output "management_ci_role_name" {
  value = aws_iam_role.management_ci.name
}
