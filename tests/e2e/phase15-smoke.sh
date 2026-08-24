#!/usr/bin/env bash

set -uo pipefail


# ============================================================
# Cloud DevOps Lab - Phase 15 End-to-End Smoke Test
# ============================================================


ROOT_DIR="$(
    cd "$(dirname "${BASH_SOURCE[0]}")/../.." &&
    pwd
)"

ANSIBLE_DIR="${ROOT_DIR}/ansible"
TERRAFORM_DIR="${ROOT_DIR}/terraform/infrastructure"


export AWS_REGION="ap-south-1"
export AWS_DEFAULT_REGION="ap-south-1"


PASSED=0
FAILED=0


check() {

    local description="$1"
    local command="$2"

    printf "\n[TEST] %s\n" "$description"

    if bash -lc "$command"; then

        printf "[PASS] %s\n" "$description"

        PASSED=$((PASSED + 1))

    else

        printf "[FAIL] %s\n" "$description"

        FAILED=$((FAILED + 1))

    fi
}


echo "============================================================"
echo " Cloud DevOps Lab - Phase 15 E2E Smoke Test"
echo "============================================================"


# ============================================================
# AWS / Terraform
# ============================================================

check \
    "AWS identity is available" \
    "aws sts get-caller-identity >/dev/null"


check \
    "AWS region is ap-south-1" \
    'test "$(aws configure get region)" = "ap-south-1"'


check \
    "Terraform configuration is valid" \
    "cd '${TERRAFORM_DIR}' && terraform validate >/dev/null"


# ============================================================
# Ansible connectivity
# ============================================================

check \
    "Management EC2 reachable through Ansible" \
    "cd '${ANSIBLE_DIR}' && ansible management -m ping >/dev/null"


check \
    "Private App EC2 reachable through Ansible" \
    "cd '${ANSIBLE_DIR}' && ansible app -m ping >/dev/null"


# ============================================================
# SSH security
# ============================================================

check \
    "Root SSH login disabled on all hosts" \
    "cd '${ANSIBLE_DIR}' &&
     ansible all -b -m shell -a \"
       sshd -T | grep -q '^permitrootlogin no$'
     \" >/dev/null"


check \
    "Password SSH authentication disabled" \
    "cd '${ANSIBLE_DIR}' &&
     ansible all -b -m shell -a \"
       sshd -T | grep -q '^passwordauthentication no$'
     \" >/dev/null"


check \
    "UFW is active on all hosts" \
    "cd '${ANSIBLE_DIR}' &&
     ansible all -b -m shell -a \"
       ufw status | grep -q 'Status: active'
     \" >/dev/null"


check \
    "Fail2Ban sshd jail is active" \
    "cd '${ANSIBLE_DIR}' &&
     ansible all -b -m shell -a \"
       fail2ban-client status sshd >/dev/null
     \" >/dev/null"


# ============================================================
# Management Docker platform
# ============================================================

check \
    "Core management containers are running" \
    "cd '${ANSIBLE_DIR}' &&
     ansible management -b --become-user devops -m shell -a '
       for container in \
         devops-jenkins \
         devops-sonarqube \
         devops-sonar-db \
         devops-prometheus \
         devops-grafana \
         devops-nginx \
         devops-node-exporter-management \
         devops-sonar-exporter \
         devops-alertmanager
       do
         docker ps -q --filter \"name=\$container\" |
           grep -q . || exit 1
       done
     ' >/dev/null"


check \
    "Nginx configuration is valid" \
    "cd '${ANSIBLE_DIR}' &&
     ansible management -b --become-user devops -m shell -a '
       docker exec devops-nginx nginx -t
     ' >/dev/null"


# ============================================================
# Nginx application routes
# ============================================================

check \
    "Jenkins reverse-proxy endpoint responds" \
    "cd '${ANSIBLE_DIR}' &&
     ansible management -b -m shell -a '
       code=\$(curl -s -o /dev/null -w \"%{http_code}\" \
         http://127.0.0.1:8088/jenkins/login)

       echo \"\$code\" | grep -Eq \"^(200|302|403)$\"
     ' >/dev/null"


check \
    "SonarQube reports UP" \
    "cd '${ANSIBLE_DIR}' &&
     ansible management -b --become-user devops -m shell -a '
       docker exec devops-sonarqube \
         curl -fsS \
         http://127.0.0.1:9000/sonar/api/system/status |
         grep -q UP
     ' >/dev/null"


check \
    "Grafana health endpoint responds" \
    "cd '${ANSIBLE_DIR}' &&
     ansible management -b -m shell -a '
       curl -fsS \
         http://127.0.0.1:8088/grafana/api/health |
         grep -q database
     ' >/dev/null"


# ============================================================
# Private application
# ============================================================

check \
    "Application container is running" \
    "cd '${ANSIBLE_DIR}' &&
     ansible app -b -m shell -a '
       docker ps -q \
         --filter name=cloud-devops-lab-app |
         grep -q .
     ' >/dev/null"


check \
    "Application /health returns HTTP 200" \
    "cd '${ANSIBLE_DIR}' &&
     ansible app -b -m shell -a '
       curl -fsS \
         http://127.0.0.1:3000/health \
         >/dev/null
     ' >/dev/null"


check \
    "App Node Exporter is serving metrics" \
    "cd '${ANSIBLE_DIR}' &&
     ansible app -b -m shell -a '
       curl -fsS \
         http://127.0.0.1:9100/metrics |
         grep -q node_cpu_seconds_total
     ' >/dev/null"


# ============================================================
# Prometheus / Alertmanager
# ============================================================

check \
    "Prometheus has no DOWN scrape targets" \
    "cd '${ANSIBLE_DIR}' &&
     ansible management -b --become-user devops -m shell -a '
       data=\$(docker exec devops-prometheus \
         wget -qO- \
         http://127.0.0.1:9090/api/v1/targets)

       echo \"\$data\" | grep -q '\"'\"'activeTargets'\"'\"'

       ! echo \"\$data\" | grep -q '\"'\"'health'\"'\"':'\"'\"'down'\"'\"'
     ' >/dev/null"


check \
    "Alertmanager is healthy" \
    "cd '${ANSIBLE_DIR}' &&
     ansible management -b --become-user devops -m shell -a '
       docker exec devops-prometheus \
         wget -qO- \
         http://alertmanager:9093/-/healthy |
         grep -qi ok
     ' >/dev/null"


# ============================================================
# CloudWatch
# ============================================================

check \
    "CloudWatch Agent active on Management EC2" \
    "cd '${ANSIBLE_DIR}' &&
     ansible management -b -m shell -a '
       systemctl is-active --quiet amazon-cloudwatch-agent
     ' >/dev/null"


check \
    "CloudWatch Agent active on App EC2" \
    "cd '${ANSIBLE_DIR}' &&
     ansible app -b -m shell -a '
       systemctl is-active --quiet amazon-cloudwatch-agent
     ' >/dev/null"


check \
    "CloudWatch system log group exists" \
    "aws logs describe-log-groups \
       --log-group-name-prefix /cloud-devops-lab/system \
       --query 'logGroups[].logGroupName' \
       --output text |
       grep -q '/cloud-devops-lab/system'"


check \
    "CloudWatch auth log group exists" \
    "aws logs describe-log-groups \
       --log-group-name-prefix /cloud-devops-lab/auth \
       --query 'logGroups[].logGroupName' \
       --output text |
       grep -q '/cloud-devops-lab/auth'"


check \
    "CloudWatch CPU alarms exist" \
    "aws cloudwatch describe-alarms \
       --alarm-name-prefix cloud-devops-lab-project \
       --query 'MetricAlarms[].MetricName' \
       --output text |
       grep -q CPUUtilization"


# ============================================================
# Jenkins IAM / SSM
# ============================================================

check \
    "Jenkins can use EC2 IAM identity" \
    "cd '${ANSIBLE_DIR}' &&
     ansible management -b --become-user devops -m shell -a '
       docker exec \
         -e AWS_REGION=ap-south-1 \
         -e AWS_DEFAULT_REGION=ap-south-1 \
         devops-jenkins \
         aws sts get-caller-identity \
         >/dev/null
     ' >/dev/null"


check \
    "Jenkins can read approved SSM parameter" \
    "cd '${ANSIBLE_DIR}' &&
     ansible management -b --become-user devops -m shell -a '
       docker exec \
         -e AWS_REGION=ap-south-1 \
         -e AWS_DEFAULT_REGION=ap-south-1 \
         devops-jenkins \
         aws ssm get-parameter \
           --name /cloud-devops-lab/jenkins/dockerhub/username \
           --query Parameter.Name \
           --output text |
           grep -q /cloud-devops-lab/jenkins/dockerhub/username
     ' >/dev/null"


echo
echo "============================================================"
echo " Phase 15 Results"
echo "============================================================"

echo "Passed: ${PASSED}"
echo "Failed: ${FAILED}"

echo


if [ "$FAILED" -eq 0 ]; then

    echo "PHASE 15 SMOKE TEST: PASS"

    exit 0

else

    echo "PHASE 15 SMOKE TEST: FAIL"

    exit 1

fi
