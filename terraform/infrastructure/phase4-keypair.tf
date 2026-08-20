# ------------------------------------------------------------
# Phase 4 - EC2 SSH Key Pair
# ------------------------------------------------------------

resource "aws_key_pair" "devops" {
  key_name = "${var.project_name}-key"

  public_key = file(
    pathexpand(var.ssh_public_key_path)
  )

  tags = {
    Name = "${var.project_name}-key"
  }
}
