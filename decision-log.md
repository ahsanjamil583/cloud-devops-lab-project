# Cloud DevOps Lab — Architecture Decision Log

This document records the major architectural and operational decisions made
during the Cloud DevOps Lab.

---

## ADR-001 — AWS Region: ap-south-1

### Decision

All project infrastructure is explicitly deployed in:

`ap-south-1`

### Reason

A single explicit region prevents accidental resource creation in another AWS
region and keeps infrastructure, monitoring, and IAM references consistent.

### Operational Rule

Before Terraform operations:

    export AWS_REGION=ap-south-1
    export AWS_DEFAULT_REGION=ap-south-1

    aws configure get region
    aws sts get-caller-identity

---

## ADR-002 — Terraform for Infrastructure as Code

### Decision

Use Terraform for AWS infrastructure provisioning.

### Reason

Terraform provides:

- declarative infrastructure
- reproducible environments
- dependency management
- execution plans
- state tracking
- provider-based AWS integration

### Trade-off

Terraform state must be protected carefully.

### Mitigation

Remote S3 state and state locking are used.

---

## ADR-003 — Remote Terraform State

### Decision

Store Terraform state remotely rather than relying on local state.

### Reason

Remote state improves:

- durability
- collaboration
- state consistency
- recovery
- locking

State files may contain sensitive infrastructure information and must not be
committed to Git.

---

## ADR-004 — Public Management EC2 + Private Application EC2

### Decision

Run the DevOps management platform in the public subnet while keeping the
application server in the private subnet.

### Reason

The Management EC2 requires controlled administrative connectivity.

The application does not require direct inbound Internet access.

This reduces the public attack surface.

---

## ADR-005 — Management EC2 as Bastion

### Decision

Use the Management EC2 instance as both the DevOps host and controlled access
path toward the private Application EC2.

### Reason

This avoids exposing SSH on the private Application EC2 directly to the
Internet.

### Trade-off

The Management EC2 becomes security-sensitive.

### Mitigation

- restrictive Security Group
- SSH key authentication
- root login disabled
- password login disabled
- UFW
- Fail2Ban
- IMDSv2
- least-privilege IAM

---

## ADR-006 — NAT Gateway for Private App Outbound Access

### Decision

Use a NAT Gateway for outbound connectivity from the private subnet.

### Reason

The private App EC2 needs outbound connectivity for activities such as Docker
image pulls and package access without accepting direct inbound Internet
connections.

---

## ADR-007 — Ansible for Configuration Management

### Decision

Use Ansible after Terraform provisions the EC2 infrastructure.

### Reason

Terraform manages infrastructure lifecycle.

Ansible manages operating-system and application configuration.

Keeping these responsibilities separate reduces complex provisioning logic in
Terraform.

---

## ADR-008 — Docker for Application Packaging

### Decision

Package the Node.js application as a Docker image.

### Reason

Docker provides:

- reproducible runtime
- dependency isolation
- immutable build artifacts
- easy CI/CD integration
- DockerHub distribution

---

## ADR-009 — Docker Compose for Management Services

### Decision

Run Jenkins, SonarQube, PostgreSQL, Prometheus, Grafana, Nginx and related
monitoring services through Docker Compose on the Management EC2 instance.

### Reason

The lab requires multiple cooperating services.

Docker Compose provides a simple declarative service topology without requiring
a Kubernetes cluster for a small environment.

### Trade-off

The Management EC2 is a single-node platform.

This is acceptable for the scope of the lab but would require high-availability
design in a production platform.

---

## ADR-010 — Nginx as Single Web Access Layer

### Decision

Use Nginx path-based reverse proxy routes:

- `/jenkins/`
- `/sonar/`
- `/grafana/`

### Reason

This provides one controlled entry point instead of publishing separate
Jenkins, SonarQube and Grafana host ports.

### Security Choice

Nginx is bound to loopback and accessed through an SSH tunnel rather than
exposing DevOps management interfaces publicly.

---

## ADR-011 — Jenkins Declarative Pipeline

### Decision

Store CI/CD logic in a root `Jenkinsfile`.

### Reason

Pipeline-as-code provides:

- version control
- peer review
- reproducibility
- traceability
- consistent CI behavior

### Pipeline Policy

Deployment occurs only after:

- lint succeeds
- unit tests succeed
- Sonar analysis succeeds
- Quality Gate passes

---

## ADR-012 — SonarQube Quality Gate Before Docker Publication

### Decision

Run the Quality Gate before Docker image publishing/deployment.

### Reason

Poor-quality code should not reach the deployment artifact or application
server.

Flow:

    Tests
       ↓
    Sonar Analysis
       ↓
    Quality Gate
       ↓
    PASS → Docker Build / Publish
    FAIL → STOP

---

## ADR-013 — PostgreSQL Persistence for SonarQube

### Decision

Use PostgreSQL with persistent Docker volumes for SonarQube.

### Reason

SonarQube data must survive container recreation.

Container lifecycle and persistent data lifecycle should remain separate.

---

## ADR-014 — DockerHub as Image Registry

### Decision

Publish validated application images to DockerHub.

### Reason

The Jenkins build environment and private App EC2 need a shared distribution
location for immutable Docker artifacts.

### Tagging

Deploy immutable `BUILD-SHA` style tags rather than relying exclusively on
`latest`.

This improves traceability and rollback.

---

## ADR-015 — Ansible-Driven Application Deployment

### Decision

Jenkins triggers Ansible for deployment instead of embedding all SSH/Docker
commands directly in the Jenkinsfile.

### Reason

Deployment logic belongs in configuration/deployment automation.

This keeps Jenkins focused on orchestration and keeps server state logic
reusable outside Jenkins.

---

## ADR-016 — Pull New Image Before Replacing Healthy App

### Decision

Attempt the new image pull before replacing the currently running application
container.

### Reason

A nonexistent or unavailable image should not cause the healthy application to
be removed.

This behavior was validated during end-to-end failure testing.

---

## ADR-017 — Prometheus for Metrics

### Decision

Use Prometheus as the main metric collection system.

### Reason

Prometheus supports:

- pull-based monitoring
- exporters
- PromQL
- service health metrics
- Jenkins metrics
- host metrics
- alert rules
- Grafana integration

---

## ADR-018 — Node Exporter for EC2 Host Metrics

### Decision

Deploy Node Exporter for operating-system metrics.

### Reason

Node Exporter exposes CPU, memory, filesystem and other Linux host metrics in
Prometheus format.

The private App Node Exporter is restricted to Management/Prometheus access.

---

## ADR-019 — Custom Sonar Quality Exporter

### Decision

Use a small exporter to retrieve project-level quality metrics from the
SonarQube Web API.

### Reason

The dashboard requirement focuses on Sonar project code-quality issues rather
than only SonarQube server JVM/runtime health.

---

## ADR-020 — Grafana Provisioning as Code

### Decision

Provision the Prometheus datasource and Grafana dashboard from versioned files.

### Reason

Manually created dashboards would exist only inside Grafana state.

Provisioning them from Git makes monitoring reproducible.

---

## ADR-021 — Alertmanager for Prometheus Notifications

### Decision

Route Prometheus alerts through Alertmanager.

### Reason

Prometheus evaluates alert conditions while Alertmanager handles notification
routing, grouping and resolved notifications.

A Slack-compatible mock receiver is supported so alert delivery can be tested
without exposing external credentials.

---

## ADR-022 — CloudWatch in Parallel with Prometheus

### Decision

Use both Prometheus and AWS CloudWatch.

### Reason

They cover different needs.

Prometheus provides platform/application monitoring and Grafana dashboards.

CloudWatch provides AWS-native metrics, centralized logs and AWS alarms.

The two systems provide complementary observability rather than being
duplicates.

---

## ADR-023 — SSM Parameter Store for Jenkins Runtime Secrets

### Decision

Store Jenkins CI/CD runtime secrets in AWS Systems Manager Parameter Store.

### Reason

Secrets must not be hardcoded in:

- Jenkinsfile
- Git
- Docker images
- shell scripts

Jenkins obtains approved parameters using the Management EC2 IAM role.

No static AWS access keys are required.

---

## ADR-024 — Separate Management IAM Role

### Decision

Give the Management EC2 a dedicated IAM role for CI/CD operations.

### Reason

The private App EC2 should not be able to read Jenkins deployment secrets.

This follows least privilege.

---

## ADR-025 — Ansible Vault for Configuration Secrets

### Decision

Use Ansible Vault for secrets required by Ansible-managed configuration.

### Reason

Encrypted configuration can safely remain under version control while
plaintext values stay protected.

---

## ADR-026 — IMDSv2 Required

### Decision

Require EC2 Instance Metadata Service v2.

### Reason

IMDSv2 provides stronger metadata credential protection.

The Management instance allows the container-aware hop configuration required
for Jenkins IAM access, while the App instance is more restrictive.

---

## ADR-027 — UFW + Fail2Ban + Security Groups

### Decision

Use multiple security layers rather than relying only on AWS Security Groups.

### Layers

    AWS Security Group
          ↓
    UFW
          ↓
    Fail2Ban
          ↓
    OpenSSH configuration

### Reason

Defense in depth limits the effect of a single misconfiguration.

---

## ADR-028 — Key-Only SSH

### Decision

Disable root and password SSH authentication.

### Expected SSH settings

    PermitRootLogin no
    PasswordAuthentication no
    PubkeyAuthentication yes

---

## ADR-029 — End-to-End Failure Testing

### Decision

Validate controlled failure conditions, not only successful deployment.

### Scenarios

- failed unit test
- Sonar Quality Gate failure
- Jenkins outage
- high EC2 CPU
- application container outage
- invalid Docker image deployment

### Reason

A production-style system should fail predictably and recover cleanly.

---

## Final Architecture Principle

The overall project follows this responsibility model:

    Terraform
       ↓
    Infrastructure

    Ansible
       ↓
    Configuration

    Jenkins
       ↓
    CI/CD orchestration

    Docker
       ↓
    Deployable artifact

    SonarQube
       ↓
    Quality enforcement

    Prometheus + Grafana
       ↓
    Observability

    CloudWatch
       ↓
    AWS-native monitoring/logging

    Alertmanager
       ↓
    Notifications

    SSM + IAM + Vault
       ↓
    Secrets and security
