# ============================================================
# CloudWatch Log Groups
# ============================================================

resource "aws_cloudwatch_log_group" "system_logs" {
  name              = "/cloud-devops-lab/system"
  retention_in_days = 14

  tags = {
    Name = "${var.project_name}-system-logs"
  }
}


resource "aws_cloudwatch_log_group" "auth_logs" {
  name              = "/cloud-devops-lab/auth"
  retention_in_days = 14

  tags = {
    Name = "${var.project_name}-auth-logs"
  }
}


# ============================================================
# SNS topic for CloudWatch alarm actions
# ============================================================

resource "aws_sns_topic" "cloudwatch_alerts" {
  name = "${var.project_name}-cloudwatch-alerts"

  tags = {
    Name = "${var.project_name}-cloudwatch-alerts"
  }
}


# ============================================================
# Private Application EC2 - High CPU
# ============================================================

resource "aws_cloudwatch_metric_alarm" "app_high_cpu" {
  alarm_name        = "${var.project_name}-app-high-cpu"
  alarm_description = "Private application EC2 CPU utilization is above 70 percent"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  comparison_operator = "GreaterThanThreshold"
  threshold           = 70

  statistic = "Average"
  period    = 300

  evaluation_periods  = 1
  datapoints_to_alarm = 1

  treat_missing_data = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.app.id
  }

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.cloudwatch_alerts.arn
  ]

  tags = {
    Name = "${var.project_name}-app-high-cpu"
  }
}


# ============================================================
# Management EC2 - High CPU
# ============================================================

resource "aws_cloudwatch_metric_alarm" "management_high_cpu" {
  alarm_name        = "${var.project_name}-management-high-cpu"
  alarm_description = "Management EC2 CPU utilization is above 70 percent"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  comparison_operator = "GreaterThanThreshold"
  threshold           = 70

  statistic = "Average"
  period    = 300

  evaluation_periods  = 1
  datapoints_to_alarm = 1

  treat_missing_data = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.management.id
  }

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.cloudwatch_alerts.arn
  ]

  tags = {
    Name = "${var.project_name}-management-high-cpu"
  }
}


# ============================================================
# Outputs
# ============================================================

output "cloudwatch_alerts_topic_arn" {
  description = "SNS topic used by CloudWatch alarms"
  value       = aws_sns_topic.cloudwatch_alerts.arn
}


output "app_high_cpu_alarm_name" {
  description = "Private app EC2 high CPU alarm"
  value       = aws_cloudwatch_metric_alarm.app_high_cpu.alarm_name
}


output "management_high_cpu_alarm_name" {
  description = "Management EC2 high CPU alarm"
  value       = aws_cloudwatch_metric_alarm.management_high_cpu.alarm_name
}
