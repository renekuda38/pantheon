# Jenkins Master-Agent Setup Guide

Complete guide for setting up Jenkins CI/CD environment with master-worker architecture using Docker containers.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Start Jenkins Master](#start-jenkins-master)
  - [Option A: Docker Compose (Recommended)](#option-a-docker-compose-recommended)
  - [Option B: Docker Run](#option-b-docker-run)
- [UI Setup - Plugins & Node Configuration](#ui-setup---plugins--node-configuration)
- [Start Jenkins Agent (Inbound Agent)](#start-jenkins-agent-inbound-agent)
  - [Option A: Docker Compose (Recommended)](#option-a-docker-compose-recommended-1)
  - [Option B: Docker Run](#option-b-docker-run-1)
- [Start Jenkins Agent (Ubuntu Agent)](#start-jenkins-agent-ubuntu-agent)
  - [Option A: Docker Compose (Recommended)](#option-a-docker-compose-recommended-2)
  - [Option B: Docker Run](#option-b-docker-run-2)
- [Parameters Explained](#parameters-explained)
- [Security Notes](#security-notes)
- [Use Agent in Pipeline](#use-agent-in-pipeline)
- [Backup & Recovery](#backup--recovery)
- [Container Management](#container-management)

---

## Prerequisites

- **Docker** installed and running
- **Docker Compose** v2+ installed
- Available ports:
  - `8080` - Jenkins Web UI
  - `50000` - Agent communication (JNLP)
- Network connectivity between master and agent containers

---

## Start Jenkins Master

### Option A: Docker Compose (Recommended)

Uses `docker-compose.jenkins.yml` for consistent and reproducible setup.

```bash
# Start Jenkins master
docker compose -f docker-compose.jenkins.yml up -d jenkins-master

# Verify container is running
docker ps | grep jenkins-master

# Check logs for initial admin password
docker compose -f docker-compose.jenkins.yml logs jenkins-master
```

### Option B: Docker Run

Alternative approach using direct `docker run` commands.

```bash
# 1. Create network (if not exists)
docker network create pantheon-network

# 2. Create persistent volume
docker volume create jenkins_home

# 3. Pull Jenkins LTS image
docker pull jenkins/jenkins:lts-jdk17

# 4. Run Jenkins master container
docker run -d \
  --name jenkins-master \
  --restart unless-stopped \
  --network pantheon-network \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts-jdk17
```

---

## UI Setup - Plugins & Node Configuration

### 1. Get Initial Admin Password

```bash
# From docker compose
docker compose -f docker-compose.jenkins.yml logs jenkins-master | grep -A 5 "initial"

# Or directly from container
docker exec jenkins-master cat /var/jenkins_home/secrets/initialAdminPassword
```

### 2. Complete Setup Wizard

1. Navigate to `http://localhost:8080`
2. Enter initial admin password
3. **Install suggested plugins** (includes Pipeline, Git, Credentials, SSH Agent)
4. Create admin user
5. Jenkins URL: `http://localhost:8080`

### 3. Install Additional Plugins (Optional)

**Manage Jenkins → Plugins → Available plugins**

Recommended for Docker integration:
- **Docker Pipeline** - `docker.build()` syntax in Jenkinsfile
- **Docker plugin** - Docker cloud agents support

```bash
# Alternative: install via CLI
docker exec jenkins-master jenkins-plugin-cli --plugins \
  docker-workflow \
  docker-plugin
```

### 4. Create Multibranch Pipeline

**New Item → Multibranch Pipeline**

| Setting | Value |
|---------|-------|
| Name | `taskmaster-pipeline` (or your preferred name) |
| Display Name | `master` |
| Branch Sources | Add source → Git |
| Repository URL | Your GitHub repository `.git` URL |
| Scan Multibranch Pipeline Triggers | Periodically if not otherwise run → 1 minute (or your preference) |
| Docker label | `python docker linux uv` |

Click **Save** to create the pipeline.

### 5. Configure Credentials for Pipeline

Since the Jenkinsfile uses `withCredentials`, you need to create credentials in Jenkins UI.

**Manage Jenkins → Security → Credentials → System → Global credentials → Add Credentials**

| Setting | Value |
|---------|-------|
| Kind | Secret text |
| Secret | Your actual password/secret value |
| ID | `postgres-password` (or match the ID used in your Jenkinsfile) |
| Description | PostgreSQL password (optional) |

Click **Save** to create the credential.

**Note:** Repeat this process for any other secrets referenced in your Jenkinsfile using `withCredentials`.

### 6. Create Node for Agent

**Manage Jenkins → Nodes → New Node**

| Setting | Value |
|---------|-------|
| Name | `docker-worker` (for inbound agent) or `ubuntu-worker` (for ubuntu agent) |
| Type | **Permanent Agent** |
| Remote root directory | `/home/jenkins/agent` |
| Labels | `docker linux python` or `ubuntu linux python uv` |
| Usage | Use this node as much as possible |
| Launch method | **Launch agent by connecting it to the controller** |

### 7. Get Agent Secret

1. Click **Save**
2. Click on the newly created node name
3. Copy the **SECRET** from the connection instructions
4. Store the secret in `.env.jenkins` or `.env.jenkins-ubuntu` file

---

## Start Jenkins Agent (Inbound Agent)

Agent based on the official `jenkins/inbound-agent` image with Docker and Python support.

### Option A: Docker Compose (Recommended)

```bash
# 1. Copy example env file and add your secret
cp .env.jenkins.example .env.jenkins

# 2. Edit .env.jenkins and paste your secret from Jenkins UI
# JENKINS_AGENT_SECRET=<your-secret-here>

# 3. Start agent
docker compose -f docker-compose.jenkins.yml --env-file .env.jenkins up -d jenkins-agent

# 4. Verify agent is connected
docker compose -f docker-compose.jenkins.yml logs -f jenkins-agent
```

**Useful commands:**
```bash
# View logs
docker compose -f docker-compose.jenkins.yml logs -f jenkins-agent

# Restart agent
docker compose -f docker-compose.jenkins.yml restart jenkins-agent

# Rebuild after Dockerfile changes
docker compose -f docker-compose.jenkins.yml build jenkins-agent
docker compose -f docker-compose.jenkins.yml --env-file .env.jenkins up -d jenkins-agent

# Start everything (master + agent)
docker compose -f docker-compose.jenkins.yml --env-file .env.jenkins up -d
```

### Option B: Docker Run

```bash
# 1. Build agent image
docker build -f Dockerfile.jenkins-agent -t jenkins-docker-agent:latest .

# 2. Run agent container
docker run -d \
  --name jenkins-agent-docker01 \
  --restart unless-stopped \
  --network pantheon-network \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins-docker-agent:latest \
  -url http://jenkins-master:8080 \
  -secret <YOUR_SECRET_HERE> \
  -name docker-worker \
  -workDir /home/jenkins/agent
```

---

## Start Jenkins Agent (Ubuntu Agent)

Custom agent based on `ubuntu:24.04` with **uv** package manager, Docker CLI and Python 3. Suitable for projects using modern Python tooling.

### Option A: Docker Compose (Recommended)

```bash
# 1. Copy example env file and add your secret
cp .env.jenkins-ubuntu.example .env.jenkins-ubuntu

# 2. Edit .env.jenkins-ubuntu and paste your secret from Jenkins UI
# JENKINS_UBUNTU_AGENT_SECRET=<your-secret-here>

# 3. Build and start agent
docker compose -f docker-compose.jenkins-agent-ubuntu.yml --env-file .env.jenkins-ubuntu up -d --build

# 4. Verify agent is connected
docker compose -f docker-compose.jenkins-agent-ubuntu.yml logs -f jenkins-agent-ubuntu
```

**Useful commands:**
```bash
# View logs
docker compose -f docker-compose.jenkins-agent-ubuntu.yml logs -f jenkins-agent-ubuntu

# Restart agent
docker compose -f docker-compose.jenkins-agent-ubuntu.yml restart jenkins-agent-ubuntu

# Rebuild after Dockerfile changes
docker compose -f docker-compose.jenkins-agent-ubuntu.yml build
docker compose -f docker-compose.jenkins-agent-ubuntu.yml --env-file .env.jenkins-ubuntu up -d
```

### Option B: Docker Run

```bash
# 1. Build agent image
docker build -f Dockerfile.jenkins-ubuntu -t jenkins-ubuntu-agent:latest .

# 2. Run agent container
docker run -d \
  --name jenkins-agent-ubuntu01 \
  --restart unless-stopped \
  --network pantheon-network \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins-ubuntu-agent:latest \
  -url http://jenkins-master:8080 \
  -secret <YOUR_SECRET_HERE> \
  -name ubuntu-worker \
  -workDir /home/jenkins/agent
```

---

## Parameters Explained

| Parameter | Description |
|-----------|-------------|
| `--network pantheon-network` | Same network as backend containers (api, db) - enables communication between containers via hostname |
| `-v /var/run/docker.sock:/var/run/docker.sock` | Mount Docker socket for Docker-in-Docker builds. **⚠️ Security risk** - see section below |
| `-url http://jenkins-master:8080` | Jenkins master URL. Uses container name as hostname within Docker network |
| `-secret <token>` | Authentication token from Jenkins UI. Never commit to git! Use `.env` file |
| `-name docker-worker` or `-name ubuntu-worker` | Must **exactly** match the node name in Jenkins UI |
| `-workDir /home/jenkins/agent` | Agent working directory where workspace files are stored |

---

## Security Notes

### Docker Socket Mount

**⚠️ Docker socket mount (`/var/run/docker.sock`) = root access to host system!**

- Current setup is only for **dev/learning purposes**
- Container with access to Docker socket can:
  - Run privileged containers
  - Access host filesystem
  - Potentially escalate privileges on host

### Production Alternatives

| Solution | Description | Security |
|----------|-------|------------|
| **Kaniko** | Rootless image builds | ✅ Best |
| **Docker-in-Docker** | Privileged container with own Docker daemon | ⚠️ Medium |
| **SSH Agents** | Dedicated build VM with SSH access | ✅ Good |
| **Kubernetes Agents** | Ephemeral pods for builds | ✅ Good |

### Best Practices

- **Never** commit secrets to git repository
- Use `.env` files for secrets (they are in `.gitignore`)
- In production use Jenkins Credentials Manager
- Rotate secrets regularly
- Use RBAC for Jenkins users

---

## Use Agent in Pipeline

### Basic Agent Selection

```groovy
pipeline {
    agent {
        label 'docker'  // Any agent with 'docker' label
    }

    stages {
        stage('Build') {
            steps {
                sh 'docker --version'
                sh 'python3 --version'
            }
        }
    }
}
```

### Specific Node Selection

```groovy
pipeline {
    agent {
        label 'ubuntu-worker'  // Specific node by name/label
    }

    stages {
        stage('Build with uv') {
            steps {
                sh 'uv --version'
                sh 'uv sync'
            }
        }
    }
}
```

### Multiple Agents

```groovy
pipeline {
    agent none  // No default agent

    stages {
        stage('Build on Docker Agent') {
            agent { label 'docker' }
            steps {
                sh 'docker build -t myapp .'
            }
        }

        stage('Test on Ubuntu Agent') {
            agent { label 'ubuntu' }
            steps {
                sh 'uv run pytest'
            }
        }
    }
}
```

---

## Backup & Recovery

### What to Backup

**Critical (must backup):**
| Path | Description |
|------|-------------|
| `/var/jenkins_home/config.xml` | Main Jenkins configuration |
| `/var/jenkins_home/jobs/` | All job definitions and build history |
| `/var/jenkins_home/credentials.xml` | Encrypted secrets |
| `/var/jenkins_home/users/` | User accounts |
| `/var/jenkins_home/secrets/` | Master key for decryption |

**Optional (can rebuild):**
| Path | Description |
|------|-------------|
| `/var/jenkins_home/plugins/` | Can be reinstalled |
| `/var/jenkins_home/workspace/` | Transient build data |

### Backup Commands

```bash
# Full backup of jenkins_home volume
docker run --rm \
  -v jenkins_home:/data \
  -v $(pwd)/backups:/backup \
  ubuntu tar czf /backup/jenkins_backup_$(date +%Y%m%d_%H%M%S).tar.gz /data

# List backups
ls -la backups/
```

### Restore Commands

```bash
# Stop Jenkins first
docker stop jenkins-master

# Restore from backup
docker run --rm \
  -v jenkins_home:/data \
  -v $(pwd)/backups:/backup \
  ubuntu bash -c "rm -rf /data/* && tar xzf /backup/jenkins_backup_YYYYMMDD_HHMMSS.tar.gz -C /"

# Start Jenkins
docker start jenkins-master
```

---

## Container Management

### View Logs

```bash
# Master logs
docker logs jenkins-master
docker logs -f jenkins-master  # Follow/tail

# Agent logs
docker logs jenkins-agent-docker01
docker logs jenkins-agent-ubuntu01

# With docker compose
docker compose -f docker-compose.jenkins.yml logs -f
```

### Container Lifecycle

```bash
# Stop containers
docker stop jenkins-master jenkins-agent-docker01

# Start containers
docker start jenkins-master jenkins-agent-docker01

# Restart containers
docker restart jenkins-master

# Remove containers (keeps volumes)
docker rm jenkins-agent-docker01

# With docker compose
docker compose -f docker-compose.jenkins.yml down      # Stop and remove
docker compose -f docker-compose.jenkins.yml down -v   # Also remove volumes
```

### Execute Commands Inside Container

```bash
# Interactive bash shell
docker exec -it jenkins-master bash

# Run single command
docker exec jenkins-master cat /var/jenkins_home/config.xml

# Check installed plugins
docker exec jenkins-master ls /var/jenkins_home/plugins/
```

### Inspect Container

```bash
# Container details
docker inspect jenkins-master

# Volume details
docker volume inspect jenkins_home

# Network details
docker network inspect pantheon-network
```

### Jenkins Service Restart (Without Container Restart)

```bash
# Graceful restart via CLI (finishes running jobs)
docker exec jenkins-master java -jar /usr/share/jenkins/jenkins-cli.jar \
  -s http://localhost:8080/ -auth admin:YOUR_PASSWORD safe-restart

# Or via UI: Manage Jenkins → Prepare for Shutdown → Restart
```

---
