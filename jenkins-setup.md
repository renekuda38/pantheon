# Jenkins Setup Documentation

## Table of Contents
- [Local Development Setup](#local-development-setup)
- [Plugin Management](#plugin-management)
- [Backup & Recovery](#backup--recovery)

---

## Local Development Setup

### Prerequisites
- Docker installed
- Ports 8080 and 50000 available

### 1. Pull Jenkins LTS Image
```bash
docker pull jenkins/jenkins:lts-jdk17
```

### 2. Create Persistent Volume
```bash
docker volume create jenkins_home
```

### 3. Run Jenkins Master Container
```bash
docker run -d \
  --name jenkins-master \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts-jdk17
```

### 4. Initial Setup

**Get initial admin password:**
```bash
docker logs jenkins-master
# or
docker exec jenkins-master cat /var/jenkins_home/secrets/initialAdminPassword
```

**Setup wizard:**
1. Navigate to `http://localhost:8080`
2. Enter initial admin password
3. Install suggested plugins
4. Create admin user
5. Jenkins URL: `http://localhost:8080` (change in production)

---

## Plugin Management

### Essential Plugins (Installed)
- Pipeline 
- Git
- Credentials 
- SSH Agent
- ... other listed within suggested plugins

### Additional Required Plugins
**Install via:** Manage Jenkins → Plugins → Available plugins

#### For Docker Integration (Task 5-7)
- **Docker Pipeline** - `docker.build()` syntax in Jenkinsfile
- **Docker plugin** - Docker cloud agents support

#### For Future Tasks
- **Ansible plugin** (Task 10)
- **Terraform plugin** (Task 9) - optional, can use sh commands

**Installation command (alternative):**
```bash
docker exec jenkins-master jenkins-plugin-cli --plugins \
  docker-workflow \
  docker-plugin
```

---

## Jenkins Agents

### Docker Agent Setup (Task 6)

**Purpose:** Offload builds from master to dedicated agent with Docker capabilities.

#### 1. Build Agent Image

**Dockerfile.jenkins-agent:**
```dockerfile
FROM jenkins/inbound-agent

USER root

RUN apt-get update && apt-get install -y \
    docker.io \
    git \
    python3 \
    python3-pip \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN usermod -aG docker jenkins

USER jenkins

RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/jenkins/.cargo/bin:${PATH}"

WORKDIR /home/jenkins/agent
```

**Build:**
```bash
docker build -f Dockerfile.jenkins-agent -t jenkins-docker-agent:latest .
```

#### 2. Create Node in Jenkins UI

**Manage Jenkins → Nodes → New Node**
- Name: `docker-worker`
- Type: **Permanent Agent**
- Remote root directory: `/home/jenkins/agent`
- Labels: `docker linux python`
- Launch method: **Launch agent by connecting it to the controller**

**Save → Copy SECRET from connection instructions**

#### 3. Run Agent Container
```bash
docker run -d \
  --name jenkins-agent-docker01 \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins-docker-agent:latest \
  -url http://host.docker.internal:8080 \
  -secret  \
  -name docker-worker \
  -workDir /home/jenkins/agent
```

**Parameters explained:**
- `-v /var/run/docker.sock` - mount for Docker-in-Docker builds (⚠️ security risk)
- `-url` - Jenkins master URL (`host.docker.internal` for Docker Desktop on macOS)
- `-secret` - authentication token from Jenkins UI
- `-name` - must match Jenkins node name exactly
- `-workDir` - agent workspace directory

#### 4. Use Agent in Pipeline

**Jenkinsfile:**
```groovy
pipeline {
    agent {
        label 'docker'  // any agent with 'docker' label
    }
    // or
    agent {
        node 'docker-worker'  // specific node
    }
    
    stages {
        // your stages
    }
}
```

#### Troubleshooting

**Permission denied: /var/run/docker.sock**
```bash
# macOS - check socket group:
ls -la /Users/$USER/.docker/run/docker.sock

# Fix: ensure --group-add matches socket GID
docker inspect jenkins-agent-docker01 | grep -A5 GroupAdd
```

**Agent offline:**
```bash
# Check agent logs:
docker logs jenkins-agent-docker01

# Look for "Connected" message
# Verify secret and node name match Jenkins UI
```

**uv not found in pipeline:**
- Ensure `ENV PATH="/home/jenkins/.cargo/bin:${PATH}"` is in Dockerfile
- Rebuild image after adding ENV line

#### Security Notes

⚠️ **Docker socket mount = root access to host!**
- Current setup is for **dev/learning only**
- Production alternatives:
  - Docker-in-Docker (privileged container)
  - Kaniko (rootless builds)
  - Dedicated build VMs with SSH agents

---

## Configuration

### Jenkins Home Structure
```
/var/jenkins_home/
├── config.xml              # Main Jenkins config
├── credentials.xml         # Encrypted credentials
├── jobs/                   # All pipeline jobs
├── plugins/                # Installed plugins
├── secrets/                # Initial admin password, keys
├── users/                  # User accounts
└── workspace/              # Job workspaces
```

### Credentials Setup
**Manage Jenkins → Credentials → System → Global credentials**

Will be needed for:
- GitHub (Personal Access Token) - Task 5
- Docker Hub (username/password) - Task 5
- SSH keys for servers (Task 9-10)

**Security best practice:** Never hardcode credentials in Jenkinsfile!

---

## Backup & Recovery

### What to Backup
**Critical:**
- `/var/jenkins_home/config.xml` - main configuration
- `/var/jenkins_home/jobs/` - all job definitions
- `/var/jenkins_home/credentials.xml` - encrypted secrets
- `/var/jenkins_home/users/` - user accounts

**Optional:**
- `/var/jenkins_home/plugins/` - can be reinstalled
- `/var/jenkins_home/workspace/` - transient data, can rebuild

### Backup Strategy

**Manual backup (good for dev):**
```bash
# Backup entire jenkins_home
docker run --rm -v jenkins_home:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/jenkins_backup_$(date +%Y%m%d).tar.gz /data
```

**Restore:**
```bash
docker run --rm -v jenkins_home:/data -v $(pwd):/backup \
  ubuntu tar xzf /backup/jenkins_backup_YYYYMMDD.tar.gz -C /
```

---

## Container Management

### Useful Commands
```bash
# View logs
docker logs jenkins-master
docker logs -f jenkins-master  # follow/tail

# Restart Jenkins
docker restart jenkins-master

# Stop/Start
docker stop jenkins-master
docker start jenkins-master

# Execute commands inside container
docker exec -it jenkins-master bash

# Inspect container
docker inspect jenkins-master

# Check volume
docker volume inspect jenkins_home
```

### Restart Jenkins Service (without container restart)
```bash
# Graceful restart (finishes running jobs)
docker exec jenkins-master java -jar /usr/share/jenkins/jenkins-cli.jar \
  -s http://localhost:8080/ -auth admin:YOUR_PASSWORD safe-restart

# Or via UI: Manage Jenkins → Prepare for Shutdown → Restart
```

---