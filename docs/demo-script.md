# Cloud DevOps Lab — 10 Minute Demo Script

## 00:00–00:40 — Introduction

Say:

"This project is a mini production-style DevOps environment running on AWS.
It covers Infrastructure as Code, configuration management, CI/CD, static code
analysis, monitoring, centralized logging, alerting and security hardening."

Show:

- repository homepage
- architecture-diagram.png

Explain briefly:

- Management EC2 = public/bastion/DevOps platform
- App EC2 = private workload server
- AWS region = ap-south-1

---

## 00:40–02:00 — Terraform Infrastructure

Terminal:

    cd terraform/infrastructure

    export AWS_REGION=ap-south-1
    export AWS_DEFAULT_REGION=ap-south-1

    aws configure get region
    terraform validate
    terraform plan

Show that Terraform reports a clean/stable plan.

Then:

    terraform output

Briefly point out:

- VPC
- public subnet
- private subnet
- Management EC2
- App EC2
- NAT Gateway
- IAM
- CloudWatch resources

Say:

"Terraform manages the infrastructure declaratively and uses remote state."

Do not run a destructive apply during the demo.

---

## 02:00–03:10 — Ansible Configuration

Terminal:

    cd ../../ansible

    ansible-inventory --graph

    ansible management -m ping
    ansible app -m ping

Show one playbook:

    ansible-playbook playbooks/deploy-devops-stack.yml --syntax-check

Then:

    ansible management -b --become-user devops -m shell -a \
    "cd /opt/cloud-devops-stack && docker compose ps"

Explain:

"Terraform creates servers. Ansible configures and deploys software to them."

Show Management services running.

---

## 03:10–05:50 — Jenkins CI/CD

Open:

    http://localhost:8088/jenkins/

Show `cloud-devops-lab-ci`.

Trigger/use a normal build.

Explain stages:

- Checkout
- Verify tooling
- AWS IAM/SSM verification
- dependency installation
- lint
- unit tests
- Sonar analysis
- Quality Gate
- Docker build
- DockerHub push
- Ansible deployment

Say:

"If tests or the Quality Gate fail, deployment does not run."

Show successful Stage View.

Then show DockerHub immutable image tag.

Terminal:

    ansible app -b -m shell -a \
    "docker ps --filter name=cloud-devops-lab-app"

Then:

    ansible app -b -m shell -a \
    "curl -i http://127.0.0.1:3000/health"

Show HTTP 200.

---

## 05:50–06:40 — SonarQube

Open:

    http://localhost:8088/sonar/

Show:

- project
- Quality Gate
- issues
- vulnerabilities/code smells

Say:

"SonarQube acts as a deployment gate. Jenkins waits for this result before
continuing."

---

## 06:40–08:00 — Prometheus + Grafana

Open:

    http://localhost:8088/grafana/

Open:

    Cloud DevOps Lab - Observability

Show:

- Management/App CPU
- memory
- Jenkins build duration
- Jenkins build results
- Sonar quality issues
- Quality Gate status
- target health

Say:

"Prometheus scrapes the EC2 exporters, Jenkins, Sonar quality exporter and
itself. Grafana visualizes the stored metrics."

---

## 08:00–08:50 — Alerts

Show Prometheus/Alertmanager evidence or saved Phase 13 test evidence.

Explain:

    Jenkins unavailable
          ↓
    Prometheus up = 0
          ↓
    JenkinsDown for 5 minutes
          ↓
    Alertmanager
          ↓
    Slack / mock webhook

Show firing/resolved notification evidence.

Then show CloudWatch CPU alarm:

    AWS Console
    → CloudWatch
    → Alarms

Show threshold:

    CPUUtilization > 70%

---

## 08:50–09:30 — CloudWatch + Security

Show CloudWatch log groups:

- /cloud-devops-lab/system
- /cloud-devops-lab/auth

Terminal:

    ansible all -b -m shell -a \
    "sshd -T | grep -E \
    'permitrootlogin|passwordauthentication|pubkeyauthentication'"

Show:

    permitrootlogin no
    passwordauthentication no
    pubkeyauthentication yes

Mention:

- UFW
- Fail2Ban
- private App EC2
- IMDSv2
- SSM SecureString
- IAM least privilege
- Ansible Vault

Do not display decrypted secret values.

---

## 09:30–10:00 — Final Summary

Show architecture diagram again.

Say:

"The end-to-end flow is GitHub to Jenkins, through linting, tests and
SonarQube, then DockerHub and Ansible deployment to the private EC2 server.
Prometheus, Grafana and CloudWatch provide observability, while Alertmanager
provides alert routing. Security is enforced through private networking,
firewalls, IAM, SSM, Vault and hardened SSH."

End with:

"The project demonstrates a complete mini production-style DevOps lifecycle
from provisioning to deployment, monitoring, alerting and operational
documentation."
