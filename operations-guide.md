# Cloud DevOps Lab — Operations Guide

This guide contains operational checks and troubleshooting procedures for the
Cloud DevOps Lab.

---

# 1. Standard Health Check

## AWS

Always verify the expected AWS region first:

    export AWS_REGION=ap-south-1
    export AWS_DEFAULT_REGION=ap-south-1

    aws configure get region
    aws sts get-caller-identity

Expected region:

    ap-south-1

---

## Terraform

    cd terraform/infrastructure

    terraform validate
    terraform plan

A stable environment should report:

    No changes.

Never apply a Terraform plan that unexpectedly destroys or replaces the VPC,
EC2 instances, or networking resources.

---

## Ansible Connectivity

    cd ansible

    ansible-inventory --graph

    ansible management -m ping
    ansible app -m ping

Both hosts must be reachable before running deployment playbooks.

---

## Management Platform

    ansible management -b --become-user devops -m shell -a \
    "cd /opt/cloud-devops-stack && docker compose ps"

Expected core services include:

- Jenkins
- SonarQube
- PostgreSQL
- Prometheus
- Grafana
- Nginx
- Alertmanager
- Node Exporter
- Sonar exporter

---

## Application Health

    ansible app -b -m shell -a \
    "docker ps --filter name=cloud-devops-lab-app"

Then:

    ansible app -b -m shell -a \
    "curl -i http://127.0.0.1:3000/health"

Expected:

    HTTP 200

---

# 2. Jenkins Is Down

## Symptoms

- `/jenkins/` does not open
- Nginx may return 502
- Prometheus `up{job="jenkins"}` becomes `0`
- `JenkinsDown` may enter pending/firing state

## Diagnose

    cd ansible

    ansible management -b --become-user devops -m shell -a \
    "docker ps -a --filter name=devops-jenkins"

Check logs:

    ansible management -b --become-user devops -m shell -a \
    "docker logs --tail 100 devops-jenkins"

Check Docker resources:

    ansible management -b --become-user devops -m shell -a \
    "docker stats --no-stream"

Check disk:

    ansible management -b -m shell -a \
    "df -h"

Check memory:

    ansible management -b -m shell -a \
    "free -h"

## Recovery

If the container is simply stopped:

    ansible management -b --become-user devops -m shell -a \
    "docker start devops-jenkins"

If configuration reconciliation is required:

    ansible-playbook playbooks/deploy-devops-stack.yml

Verify:

    ansible management -b -m shell -a \
    "curl -s -o /dev/null -w '%{http_code}\n' \
    http://127.0.0.1:8088/jenkins/login"

---

# 3. SonarQube Is Not Responding

## Symptoms

- Jenkins Sonar analysis fails
- Quality Gate does not complete
- `/sonar/` unavailable
- Sonar exporter scrape fails

## Diagnose

    ansible management -b --become-user devops -m shell -a \
    "docker ps -a --filter name=devops-sonarqube"

Check Sonar logs:

    ansible management -b --become-user devops -m shell -a \
    "docker logs --tail 150 devops-sonarqube"

Check PostgreSQL:

    ansible management -b --become-user devops -m shell -a \
    "docker ps --filter name=devops-sonar-db"

Check system requirements:

    ansible management -b -m shell -a \
    "sysctl vm.max_map_count"

Check API:

    ansible management -b -m shell -a \
    "curl -s http://127.0.0.1:8088/sonar/api/system/status"

Expected:

    "status":"UP"

## Recovery

Run:

    ansible-playbook playbooks/deploy-devops-stack.yml

Do not delete SonarQube or PostgreSQL volumes unless data destruction is
explicitly intended.

---

# 4. Application Is Unavailable

## Symptoms

- `/health` fails
- deployed container is absent/stopped/unhealthy
- Jenkins deployment may have failed

## Diagnose

    ansible app -b -m shell -a \
    "docker ps -a --filter name=cloud-devops-lab-app"

Logs:

    ansible app -b -m shell -a \
    "docker logs --tail 100 cloud-devops-lab-app"

Health:

    ansible app -b -m shell -a \
    "curl -i http://127.0.0.1:3000/health"

Check image:

    ansible app -b -m shell -a \
    "docker inspect cloud-devops-lab-app | grep -m1 'Image'"

Check resources:

    ansible app -b -m shell -a \
    "free -h && df -h"

## Recovery

If container is stopped:

    ansible app -b -m shell -a \
    "docker start cloud-devops-lab-app"

If redeployment is required, use the exact previously validated immutable
Docker image:

    ansible-playbook \
      playbooks/deploy-app.yml \
      -e "app_image=<DOCKERHUB_USER>/cloud-devops-lab-app:<BUILD-SHA>"

Verify `/health` returns HTTP 200.

---

# 5. Prometheus Target Is Down

## Diagnose

Query active targets from inside the Management Docker network:

    ansible management -b --become-user devops -m shell -a \
    "docker exec devops-prometheus \
    wget -qO- http://127.0.0.1:9090/api/v1/targets"

Common targets:

- Jenkins
- Management Node Exporter
- Application Node Exporter
- Sonar quality exporter
- Prometheus

## Jenkins target down

Verify:

    docker exec devops-jenkins curl \
    http://127.0.0.1:8080/jenkins/prometheus/

## App Node Exporter target down

On App EC2:

    ansible app -b -m shell -a \
    "curl -s http://127.0.0.1:9100/metrics | head"

Verify UFW:

    ansible app -b -m shell -a \
    "ufw status"

Verify AWS Security Group allows TCP 9100 only from the Management security
group / Management host.

## Sonar exporter down

    ansible management -b --become-user devops -m shell -a \
    "docker logs --tail 100 devops-sonar-exporter"

---

# 6. Grafana Has No Data

First verify Grafana:

    ansible management -b --become-user devops -m shell -a \
    "docker exec devops-jenkins \
    curl -s http://grafana:3000/grafana/api/health"

Then verify Prometheus:

    ansible management -b --become-user devops -m shell -a \
    "docker exec devops-jenkins \
    curl -s http://prometheus:9090/-/ready"

If Prometheus targets are UP but Grafana panels are blank, check the panel
PromQL expression and datasource.

The Grafana datasource must use:

    http://prometheus:9090

not `localhost:9090`.

---

# 7. EC2 Is Unreachable

## Management EC2

Get current public IP:

    cd terraform/infrastructure

    terraform output management_public_ip

Check AWS instance state:

    MANAGEMENT_ID=$(terraform output -raw management_instance_id)

    aws ec2 describe-instance-status \
      --instance-ids "$MANAGEMENT_ID" \
      --include-all-instances

Check Security Group port 22.

Check local private-key permissions:

    chmod 600 <PROJECT_PRIVATE_KEY>

---

## Private App EC2

The Application EC2 is intentionally private.

Do not expect direct Internet SSH.

Test using Ansible:

    cd ansible
    ansible app -m ping

If unreachable:

1. verify Management EC2 is reachable;
2. verify App EC2 is running;
3. verify private-subnet routing;
4. verify Security Group SSH rule;
5. verify UFW SSH rule;
6. verify SSH key;
7. verify bastion/ProxyJump configuration.

---

# 8. Jenkins Deployment Says "No Hosts Matched"

This is a critical failure.

Symptoms:

    Unable to parse ansible/inventory/hosts.ini
    No inventory was parsed
    Could not match supplied host pattern: app
    skipping: no hosts matched

Never treat this as a successful deployment.

Check Jenkins workspace contains the inventory:

    test -f ansible/inventory/hosts.ini

Validate:

    cd ansible
    ansible-inventory --graph

Then:

    ansible app -m ping

The deployment stage must fail if the inventory is missing or no App hosts
match.

---

# 9. DockerHub Push Failure

Check Jenkins AWS/SSM identity:

    aws sts get-caller-identity

Verify approved parameter name:

    aws ssm get-parameter \
      --name /cloud-devops-lab/jenkins/dockerhub/username \
      --query Parameter.Name \
      --output text

Do not print SecureString values into logs.

Check Docker:

    docker version

Check network access to DockerHub.

---

# 10. Invalid Application Deployment

The deployment workflow pulls the requested image before replacing the healthy
container.

If the image does not exist, the playbook should fail without destroying the
running application.

Verify current service remains healthy:

    ansible app -b -m shell -a \
    "curl -s -o /dev/null -w '%{http_code}\n' \
    http://127.0.0.1:3000/health"

Expected:

    200

---

# 11. CloudWatch Logs Missing

Check agent:

    ansible all -b -m shell -a \
    "systemctl status amazon-cloudwatch-agent --no-pager"

Agent log:

    tail -n 100 \
    /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

Check log groups:

    aws logs describe-log-groups \
      --log-group-name-prefix "/cloud-devops-lab/"

Expected:

    /cloud-devops-lab/system
    /cloud-devops-lab/auth

---

# 12. CloudWatch CPU Alarm

Get alarm name:

    cd terraform/infrastructure

    APP_ALARM=$(terraform output -raw app_high_cpu_alarm_name)

Check:

    aws cloudwatch describe-alarms \
      --alarm-names "$APP_ALARM"

Expected threshold:

    70%

Do not leave a manually forced alarm state after testing.

---

# 13. JenkinsDown Alert

Check Prometheus:

    up{job="jenkins"}

Normal value:

    1

Jenkins unavailable:

    0

After the configured `for` duration, `JenkinsDown` should become firing.

Check:

    docker exec devops-prometheus \
      wget -qO- \
      http://127.0.0.1:9090/api/v1/alerts

Then Alertmanager:

    docker exec devops-prometheus \
      wget -qO- \
      http://alertmanager:9093/api/v2/alerts

After Jenkins recovery, the alert should resolve.

---

# 14. Security Verification

SSH:

    sshd -T | grep -E \
    'permitrootlogin|passwordauthentication|pubkeyauthentication'

Expected:

    permitrootlogin no
    passwordauthentication no
    pubkeyauthentication yes

UFW:

    ufw status verbose

Fail2Ban:

    fail2ban-client status sshd

Secrets:

- never commit `.env`
- never commit SSH private keys
- never commit AWS access keys
- never commit DockerHub PAT
- never commit Sonar token
- keep Ansible Vault encrypted
- retrieve Jenkins CI/CD secrets through SSM

---

# 15. Emergency Recovery Order

For an unknown outage, troubleshoot in this order:

    AWS instance state
         ↓
    Network / Security Groups
         ↓
    SSH / Ansible connectivity
         ↓
    Docker daemon
         ↓
    Containers
         ↓
    Application health
         ↓
    Prometheus targets
         ↓
    Grafana / alerts
         ↓
    CloudWatch logs

This prevents random restarts and keeps troubleshooting evidence-driven.
