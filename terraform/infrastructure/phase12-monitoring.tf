resource "aws_vpc_security_group_ingress_rule" "app_node_exporter_from_management" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.management.id

  from_port   = 9100
  to_port     = 9100
  ip_protocol = "tcp"

  description = "Allow Prometheus on management host to scrape app node exporter"

  tags = {
    Name = "${var.project_name}-app-node-exporter-from-management"
  }
}
