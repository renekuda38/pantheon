# Jenkins Master-Agent Setup Guide

Kompletný sprievodca nastavením Jenkins CI/CD prostredia s master-worker architektúrou pomocou Docker kontajnerov.

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

Používa `docker-compose.jenkins.yml` pre konzistentný a reprodukovateľný setup.

```bash
# Start Jenkins master
docker-compose -f docker-compose.jenkins.yml up -d jenkins-master

# Verify container is running
docker ps | grep jenkins-master

# Check logs for initial admin password
docker-compose -f docker-compose.jenkins.yml logs jenkins-master
```

### Option B: Docker Run

Alternatívny prístup pomocou priamych `docker run` príkazov.

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
# From docker-compose
docker-compose -f docker-compose.jenkins.yml logs jenkins-master | grep -A 5 "initial"

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

### 4. Create Node for Agent

**Manage Jenkins → Nodes → New Node**

| Setting | Value |
|---------|-------|
| Name | `docker-worker` (for inbound agent) or `ubuntu-worker` (for ubuntu agent) |
| Type | **Permanent Agent** |
| Remote root directory | `/home/jenkins/agent` |
| Labels | `docker linux python` or `ubuntu linux python uv` |
| Usage | Use this node as much as possible |
| Launch method | **Launch agent by connecting it to the controller** |

### 5. Get Agent Secret

1. Click **Save**
2. Click on the newly created node name
3. Copy the **SECRET** from the connection instructions
4. Store the secret in `.env.jenkins` or `.env.jenkins-ubuntu` file

---

## Start Jenkins Agent (Inbound Agent)

Agent založený na oficiálnom `jenkins/inbound-agent` image s Docker a Python podporou.

### Option A: Docker Compose (Recommended)

```bash
# 1. Copy example env file and add your secret
cp .env.jenkins.example .env.jenkins

# 2. Edit .env.jenkins and paste your secret from Jenkins UI
# JENKINS_AGENT_SECRET=<your-secret-here>

# 3. Start agent
docker-compose -f docker-compose.jenkins.yml --env-file .env.jenkins up -d jenkins-agent

# 4. Verify agent is connected
docker-compose -f docker-compose.jenkins.yml logs -f jenkins-agent
```

**Useful commands:**
```bash
# View logs
docker-compose -f docker-compose.jenkins.yml logs -f jenkins-agent

# Restart agent
docker-compose -f docker-compose.jenkins.yml restart jenkins-agent

# Rebuild after Dockerfile changes
docker-compose -f docker-compose.jenkins.yml build jenkins-agent
docker-compose -f docker-compose.jenkins.yml --env-file .env.jenkins up -d jenkins-agent

# Start everything (master + agent)
docker-compose -f docker-compose.jenkins.yml --env-file .env.jenkins up -d
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

Custom agent založený na `ubuntu:24.04` s **uv** package managerom, Docker CLI a Python 3. Vhodný pre projekty používajúce moderný Python tooling.

### Option A: Docker Compose (Recommended)

```bash
# 1. Copy example env file and add your secret
cp .env.jenkins-ubuntu.example .env.jenkins-ubuntu

# 2. Edit .env.jenkins-ubuntu and paste your secret from Jenkins UI
# JENKINS_UBUNTU_AGENT_SECRET=<your-secret-here>

# 3. Build and start agent
docker-compose -f docker-compose.jenkins-agent-ubuntu.yml --env-file .env.jenkins-ubuntu up -d --build

# 4. Verify agent is connected
docker-compose -f docker-compose.jenkins-agent-ubuntu.yml logs -f jenkins-agent-ubuntu
```

**Useful commands:**
```bash
# View logs
docker-compose -f docker-compose.jenkins-agent-ubuntu.yml logs -f jenkins-agent-ubuntu

# Restart agent
docker-compose -f docker-compose.jenkins-agent-ubuntu.yml restart jenkins-agent-ubuntu

# Rebuild after Dockerfile changes
docker-compose -f docker-compose.jenkins-agent-ubuntu.yml build
docker-compose -f docker-compose.jenkins-agent-ubuntu.yml --env-file .env.jenkins-ubuntu up -d
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
| `--network pantheon-network` | Rovnaká sieť ako backend kontajnery (api, db) - umožňuje komunikáciu medzi kontajnermi cez hostname |
| `-v /var/run/docker.sock:/var/run/docker.sock` | Mount Docker socketu pre Docker-in-Docker buildy. **⚠️ Security risk** - viď sekciu nižšie |
| `-url http://jenkins-master:8080` | Jenkins master URL. Používa container name ako hostname v rámci Docker siete |
| `-secret <token>` | Autentifikačný token z Jenkins UI. Nikdy necommituj do gitu! Použi `.env` súbor |
| `-name docker-worker` alebo `-name ubuntu-worker` | Musí **presne** zodpovedať názvu node v Jenkins UI |
| `-workDir /home/jenkins/agent` | Pracovný adresár agenta kde sa ukladajú workspace súbory |

---

## Security Notes

### Docker Socket Mount

**⚠️ Docker socket mount (`/var/run/docker.sock`) = root prístup k host systému!**

- Aktuálny setup je len pre **dev/learning účely**
- Kontajner s prístupom k Docker socketu môže:
  - Spúšťať privilegované kontajnery
  - Pristupovať k host súborovému systému
  - Potenciálne eskalovať privilégiá na host

### Production Alternatives

| Riešenie | Popis | Bezpečnosť |
|----------|-------|------------|
| **Kaniko** | Rootless image builds | ✅ Najlepšia |
| **Docker-in-Docker** | Privileged container s vlastným Docker daemonom | ⚠️ Stredná |
| **SSH Agents** | Dedicated build VM s SSH prístupom | ✅ Dobrá |
| **Kubernetes Agents** | Ephemeral pods pre buildy | ✅ Dobrá |

### Best Practices

- **Never** commituj secrets do git repozitára
- Použi `.env` súbory pre secrets (sú v `.gitignore`)
- V produkcii použi Jenkins Credentials Manager
- Rotuj secrets pravidelne
- Použi RBAC pre Jenkins používateľov

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

# With docker-compose
docker-compose -f docker-compose.jenkins.yml logs -f
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

# With docker-compose
docker-compose -f docker-compose.jenkins.yml down      # Stop and remove
docker-compose -f docker-compose.jenkins.yml down -v   # Also remove volumes
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
