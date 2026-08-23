# ------------------------------------------------------------
# Phase 4 - EC2 Instances
# ------------------------------------------------------------

# ============================================================
# Public Management / Bastion EC2
# ============================================================

resource "aws_instance" "management" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.management_instance_type

  subnet_id = aws_subnet.public.id

  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.management.id
  ]

  key_name = aws_key_pair.devops.key_name

  iam_instance_profile = aws_iam_instance_profile.management_ci.name

  # Require Instance Metadata Service v2.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-management"
    Role = "bastion-management"
  }

  # Make sure the public routing is established before
  # we create a host that we expect to SSH into.
  depends_on = [
    aws_route_table_association.public
  ]
}


# ============================================================
# Private Application EC2
# ============================================================

resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.app_instance_type

  subnet_id = aws_subnet.private.id

  # Critical security setting:
  # private app server must NOT receive a public IPv4 address.
  associate_public_ip_address = false

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  key_name = aws_key_pair.devops.key_name

  iam_instance_profile = aws_iam_instance_profile.ec2.name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 15
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-app"
    Role = "application"
  }

  # Ensure NAT/private route is ready so the server has
  # outbound Internet access after launch.
  depends_on = [
    aws_route_table_association.private
  ]
}
