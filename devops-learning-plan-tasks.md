# DevOps Learning Plan — Structured Version

## Task 1 — Linux & Bash Basics
**Description:**  
Set up Linux environment and create basic scripts, including Jenkins-focused health checks.

**Subtasks:**
- Install Ubuntu (VM or WSL)
- Create `setup.sh`
- Create `healthcheck_jenkins.sh`
- Use exit codes correctly
- Commit scripts

---

## Task 2 — Python Environment with uv
**Description:**  
Reuse FastAPI app and manage environment using uv.

**Subtasks:**
- Install uv
- Create venv
- Add FastAPI app
- Add `/health` endpoint
- Install dependencies
- Update README

---

## Task 3 — Dockerize FastAPI Application
**Description:**  
Containerize FastAPI app.

**Subtasks:**
- Create Dockerfile
- Build image
- Create healthcheck script
- Commit all files

---

## Task 4 — Jenkins Setup using Docker
**Description:**  
Run Jenkins master in Docker.

**Subtasks:**
- Run Jenkins LTS container
- Install plugins
- Document setup

---

## Task 5 — First Jenkins Pipeline
**Description:**  
Create initial CI pipeline.

**Subtasks:**
- Add Jenkinsfile
- Checkout
- Install dependencies
- Run tests
- Build Docker image

---

## Task 6 — Jenkins Docker Agent Worker
**Description:**  
Add containerized Jenkins agent.

**Subtasks:**
- Create Dockerfile for agent
- Install tools
- Register agent
- Use `docker-worker` label

---

## Task 7 — Jenkins Ubuntu 24.04 Worker
**Description:**  
Docker-based Jenkins agent using Ubuntu 24.04.

**Subtasks:**
- Create `Dockerfile.jenkins-ubuntu`
- Install JDK, Python, uv, Docker CLI, Git
- Register agent
- Update pipeline label

---

## Task 8 — curl/wget with Auth and Insecure Mode
**Description:**  
Improve health checks.

**Subtasks:**
- Expand `healthcheck_jenkins.sh`
- Add FastAPI health script
- Add healthcheck stage to pipeline

---

# Bonus Tasks

## Task 9 — Terraform VM Deployment
**Subtasks:**
- Write Terraform config
- Output public IP
- Add Makefile targets
- Document usage

---

## Task 10 — Ansible Deployment
**Subtasks:**
- Install Docker
- Deploy FastAPI container
- Test with curl
- Integrate with Jenkins

---

## Task 11 — End-to-End Deployment Pipeline
**Subtasks:**
- Trigger on push
- Build & test
- Build Docker image
- Terraform apply
- Ansible deploy
- Run curl tests