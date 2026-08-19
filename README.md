# Cloud DevOps Lab 2025

A mini production-ready DevOps environment built as part of the Cloudico DevOps Internship Challenge.

## Project Objective

Build a secure, automated and observable DevOps environment using:

- AWS
- Terraform
- Ansible
- Docker / Docker Compose
- Jenkins
- SonarQube
- PostgreSQL
- Prometheus
- Grafana
- Nginx
- AWS CloudWatch

## High-Level Architecture

The project uses two AWS EC2 instances:

1. Public Management/Bastion EC2
2. Private Application EC2

The management host will provide controlled access and run the DevOps management stack, while the application workload will run inside the private subnet.

## Infrastructure

- VPC: `10.0.0.0/16`
- Public subnet: `10.0.1.0/24`
- Private subnet: `10.0.2.0/24`
- Internet Gateway
- NAT Gateway
- Bastion / Management EC2
- Private Application EC2

## Project Structure

```text
app/                    Sample application
terraform/bootstrap/    Terraform backend bootstrap
terraform/infrastructure/ AWS infrastructure
ansible/                Configuration management
docker/                 Docker configuration
nginx/                  Reverse proxy configuration
monitoring/             Prometheus/Grafana/alerting
docs/                   Project documentation
Development Workflow

Changes should be developed on feature/phase branches and merged into main through Pull Requests.

Example:

main
  \
   phase/2-terraform-backend
          |
          v
     Pull Request
          |
          v
         main
Current Status

Phase 0: Architecture & Planning - Complete
Phase 1: GitHub & Project Setup - Complete

Documentation

Additional documentation is maintained inside the docs/ directory.

Security

Secrets and credentials must never be committed to the repository. Ansible Vault and AWS Systems Manager Parameter Store will be used during later phases.
