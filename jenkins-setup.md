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