# Jenkins Master Build Workaround (Task 5 Only)

> ⚠️ **NOT PRODUCTION-READY - TEMPORARY WORKAROUND**
>
> This setup runs builds directly on Jenkins master. This is **NOT recommended** and violates Jenkins best practices.  
> Use this ONLY for Task 5 to test your first pipeline. Proper agent-based setup comes in Task 6-7.
>
> **For production setup, see:** [jenkins-setup.md](./jenkins-setup.md)

---

## Quick Setup

### 1. Run Jenkins Master with Docker Socket

```bash
docker run -d \
  --name jenkins-master \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --restart unless-stopped \
  jenkins/jenkins:lts
```

**Key difference from production setup:**
- Added: `-v /var/run/docker.sock:/var/run/docker.sock` - allows Jenkins to build Docker images
- ⚠️ **Security risk:** Master can control host Docker daemon

---

### 2. Initial Jenkins Setup

1. Get admin password:
   ```bash
   docker logs jenkins-master
   ```

2. Navigate to `http://localhost:8080`

3. Install **suggested plugins**

4. Create admin user

---

### 3. Install Additional Plugins

**Manage Jenkins → Plugins → Available plugins**

Install:
- **Docker Pipeline** - enables `docker.build()` in Jenkinsfile
- **Docker** - Docker cloud support

Or via CLI:
```bash
docker exec jenkins-master jenkins-plugin-cli --plugins \
  docker-workflow \
  docker-plugin
```

Restart Jenkins after plugin installation.

---

### 4. Install Docker in Jenkins Container

```bash
# Enter container as root
docker exec -u root -it jenkins-master bash

# Update package list and install Docker CLI
apt-get update
apt-get install -y docker.io

# Exit
exit
```

---

### 5. Install uv for Jenkins User

```bash
# Enter container as jenkins user
docker exec -u jenkins -it jenkins-master bash

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Verify installation
source ~/.profile
uv --version

# Exit
exit
```

**Restart container**:
```bash
docker restart jenkins-master
```

---

## Verification

Test that everything works:

```bash
# Enter as jenkins user
docker exec -u jenkins -it jenkins-master bash

# Test uv
uv --version

# Test docker
docker ps

# Both should work without errors
exit
```

---

## Why This Is Temporary

| Problem | Impact | Proper Solution (Task 6-7) |
|---------|--------|---------------------------|
| Master runs builds | Security risk, resource contention | Dedicated build agents |
| Docker socket mounted | Master can control host Docker | Agents run in isolated environments |
| Tools in master | Doesn't scale, hard to maintain | Tools baked into agent images |
| `agent any` | No isolation | `agent { label 'docker-worker' }` |

---

## Cleanup (After Task 7)

Once you have proper agents running:

1. Remove tools from master:
   ```bash
   docker exec -u root -it jenkins-master bash
   apt-get remove -y docker.io
   exit
   ```

2. Recreate master **without** Docker socket:
   ```bash
   docker stop jenkins-master
   docker rm jenkins-master
   
   # Run with clean setup from jenkins-setup.md
   docker run -d \
     --name jenkins-master \
     --restart unless-stopped \
     -p 8080:8080 \
     -p 50000:50000 \
     -v jenkins_home:/var/jenkins_home \
     jenkins/jenkins:lts-jdk17
   ```

3. Update Jenkinsfiles to use agent labels instead of `agent any`

---

**Remember:** This is a learning exercise. In production, Jenkins master should **never** run builds directly! 🚀
