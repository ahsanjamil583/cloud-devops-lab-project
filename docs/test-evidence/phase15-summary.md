# Phase 15 — End-to-End Validation

## Success Path

- [ ] E2E smoke test passes
- [ ] Git push triggers Jenkins
- [ ] Lint passes
- [ ] Unit tests pass
- [ ] SonarQube analysis passes
- [ ] Quality Gate passes
- [ ] Docker image builds
- [ ] Immutable DockerHub tag is published
- [ ] Ansible deploys image to private App EC2
- [ ] Application `/health` returns HTTP 200
- [ ] Prometheus targets remain UP
- [ ] Grafana monitoring remains healthy
- [ ] CloudWatch Agent remains healthy
- [ ] Security controls remain active

## Failure Tests

### FAIL-01 — Unit Test Failure

- [ ] Jenkins pipeline fails at Unit Tests
- [ ] Sonar/build/publish/deploy stages do not continue
- [ ] Previously deployed application remains healthy

### FAIL-02 — SonarQube Quality Gate Failure

- [ ] SonarQube reports a quality violation
- [ ] Quality Gate fails
- [ ] Docker publish/deployment does not run
- [ ] Existing application remains healthy
- [ ] Temporary bad code is removed

### FAIL-03 — Jenkins Down

- [ ] Prometheus reports Jenkins `up = 0`
- [ ] JenkinsDown becomes pending
- [ ] JenkinsDown becomes firing after configured duration
- [ ] Alertmanager receives alert
- [ ] Slack/mock receives notification
- [ ] Jenkins is restored
- [ ] Alert resolves

### FAIL-04 — EC2 High CPU

- [ ] CPU utilization rises above configured threshold
- [ ] CloudWatch observes high CPU
- [ ] CloudWatch alarm enters ALARM state
- [ ] CPU workload is stopped
- [ ] Alarm returns toward OK

### FAIL-05 — App Container Stop

- [ ] Application container is intentionally stopped
- [ ] `/health` fails as expected
- [ ] Container is restored
- [ ] `/health` returns HTTP 200 again

### FAIL-06 — Invalid Deployment

- [ ] Deployment with nonexistent image fails
- [ ] Existing application container remains running
- [ ] `/health` remains HTTP 200

## Security Verification

- [ ] Root SSH disabled
- [ ] Password SSH disabled
- [ ] UFW active
- [ ] Fail2Ban active
- [ ] Jenkins uses IAM role
- [ ] SSM secrets remain outside Git
- [ ] Terraform reports no drift

## Final Result

Phase 15: PASS / FAIL
