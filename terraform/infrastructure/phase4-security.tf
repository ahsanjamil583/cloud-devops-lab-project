# ------------------------------------------------------------
# Phase 4 - Security Groups
# ------------------------------------------------------------

# ============================================================
# Management / Bastion Security Group
# ============================================================

resource "aws_security_group" "management" {
  name        = "${var.project_name}-management-sg"
  description = "Security group for Bastion and DevOps management host"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-management-sg"
  }
}

# SSH access ONLY from our trusted public IP.
resource "aws_vpc_security_group_ingress_rule" "management_ssh" {
  security_group_id = aws_security_group.management.id

  description = "SSH from trusted administrator IP"

  cidr_ipv4   = var.trusted_ssh_cidr
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

# Allow outbound connections.
resource "aws_vpc_security_group_egress_rule" "management_all_outbound" {
  security_group_id = aws_security_group.management.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}


# ============================================================
# Private Application Security Group
# ============================================================

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for private application server"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

# SSH is NOT exposed to the Internet.
# Only instances carrying the management SG can SSH to the app.
resource "aws_vpc_security_group_ingress_rule" "app_ssh_from_management" {
  security_group_id = aws_security_group.app.id

  description                  = "SSH from management host only"
  referenced_security_group_id = aws_security_group.management.id

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_all_outbound" {
  security_group_id = aws_security_group.app.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}
