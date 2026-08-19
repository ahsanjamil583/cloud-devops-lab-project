# Decision Log

This document records important architectural and implementation decisions.

---

## ADR-001: Use Terraform for Infrastructure Provisioning

**Status:** Accepted

Terraform will be used to provision AWS infrastructure so that infrastructure is reproducible, version controlled and automated.

---

## ADR-002: Use Two EC2 Instances

**Status:** Accepted

The challenge requires a bastion host and a private application server.

The public EC2 will act as the management/bastion host and will also host the Docker Compose management stack for the scope of this lab.

For a larger production environment, separating the bastion host from CI/CD and monitoring services would be preferable.

---

## ADR-003: Keep Application Server Private

**Status:** Accepted

The application EC2 will be placed in the private subnet without direct public inbound access.

Outbound internet access will be provided through the NAT Gateway.

---

## ADR-004: GitHub Pull Request Workflow

**Status:** Accepted

The `main` branch will be protected. Development changes will be made on separate branches and merged through Pull Requests.
