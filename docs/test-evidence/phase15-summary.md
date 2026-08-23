# Phase 15 — End-to-End Validation

## Success Path

- [x] E2E smoke test passes
- [x] Git push triggers Jenkins
- [x] Lint passes
- [x] Unit tests pass
- [x] SonarQube analysis passes
- [x] Quality Gate passes
- [x] Docker image builds
- [x] Immutable DockerHub tag is published
- [x] Ansible deploys image to private App EC2
- [x] Application `/health` returns HTTP 200
- [x] Prometheus targets remain UP
- [x] Grafana monitoring remains healthy
- [x] CloudWatch Agent remains healthy
- [x] Security controls remain active

## Failure Tests

### FAIL-01 — Unit Test Failure

- [x] Jenkins pipeline fails at Unit Tests
- [x] Sonar/build/publish/deploy stages do not continue
- [x] Previously deployed application remains healthy

### FAIL-02 — SonarQube Quality Gate Failure

- [x] SonarQube reports a quality violation
- [x] Quality Gate fails
- [x] Docker publish/deployment does not run
- [x] Existing application remains healthy
- [x] Temporary bad code is removed

### FAIL-03 — Jenkins Down

- [x] Prometheus reports Jenkins `up = 0`
- [x] JenkinsDown becomes pending
- [x] JenkinsDown becomes firing after configured duration
- [x] Alertmanager receives alert
- [x] Slack/mock receives notification
- [x] Jenkins is restored
- [x] Alert resolves

### FAIL-04 — EC2 High CPU

- [x] CPU utilization rises above configured threshold
- [x] CloudWatch observes high CPU
- [x] CloudWatch alarm enters ALARM state
- [x] CPU workload is stopped
- [x] Alarm returns toward OK

### FAIL-05 — App Container Stop

- [x] Application container is intentionally stopped
- [x] `/health` fails as expected
- [x] Container is restored
- [x] `/health` returns HTTP 200 again

### FAIL-06 — Invalid Deployment

- [x] Deployment with nonexistent image fails
- [x] Existing application container remains running
- [x] `/health` remains HTTP 200

## Security Verification

- [x] Root SSH disabled
- [x] Password SSH disabled
- [x] UFW active
- [x] Fail2Ban active
- [x] Jenkins uses IAM role
- [x] SSM secrets remain outside Git
- [x] Terraform reports no drift

## Final Result

Phase 15: PASS / FAIL
