# Architecture

## AWS Network

```text
Internet
   |
Internet Gateway
   |
   +-----------------------------+
   | Public Subnet 10.0.1.0/24   |
   |                             |
   | Management / Bastion EC2    |
   | - Nginx                     |
   | - Jenkins                   |
   | - SonarQube                 |
   | - PostgreSQL                |
   | - Prometheus                |
   | - Grafana                   |
   +--------------+--------------+
                  |
                  | Private VPC communication
                  |
   +--------------v--------------+
   | Private Subnet 10.0.2.0/24  |
   |                             |
   | Application EC2             |
   | - Dockerized Node.js app    |
   | - Monitoring exporter       |
   +--------------+--------------+
                  |
             NAT Gateway
                  |
              Internet
Network CIDRs
VPC: 10.0.0.0/16
Public subnet: 10.0.1.0/24
Private subnet: 10.0.2.0/24
Application Access

The application server has no public IP and is reached through the management layer.

Management Services

Nginx will provide reverse proxy access for:

/jenkins
/sonar
/grafana
Deployment Flow
GitHub
  |
Jenkins
  |
Tests / Lint
  |
SonarQube
  |
Docker Build
  |
DockerHub
  |
Ansible
  |
Private Application EC2

