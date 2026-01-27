# Pantheon Project

This project is a learning platform designed for developing and deploying a FastAPI application named TaskMaster API. It covers the integration of modern DevOps tools including Jenkins, Docker, Terraform, and Ansible.

---

## Documentation and Learning Path

All detailed project documentation is located in the docs/ directory. Please refer to the following files for specific instructions:

* **[Setup Guide](./setup.md)**
  * Quick reference for running the development environment setup script, including optional Git configuration.
* **[DevOps Learning Plan](./docs/devops-learning-plan-tasks.md)**
  * A structured roadmap containing 11 tasks covering Linux basics, Python environment management, containerization, and CI/CD automation.
* **[Backend Local Development](./docs/backend-local-development.md)**
  * Local development guide covering Python environment setup with uv, dependency management (editable installs vs lock files), Docker Compose workflow, and API testing.
* **[Jenkins Setup](./docs/jenkins-setup.md)**
  * Complete Jenkins CI/CD setup guide including master-agent architecture, Docker-based agents, persistent volumes, plugin management, and backup strategies.
---

## Project Structure

* **backend/**: Contains the FastAPI application source code, including models, database connection logic, and CRUD operations.
    * **taskmaster_api/**: Python package with the core application logic.
        * **\_\_init\_\_.py**: Package initializer (empty).
        * **app.py**: FastAPI application with REST endpoints for task CRUD operations and health checks.
        * **crud.py**: Database operations (create, read, update, delete) using raw SQL with psycopg2.
        * **database.py**: PostgreSQL connection management using psycopg2 with RealDictCursor.
        * **models.py**: Pydantic models for request/response validation (TaskCreate, TaskUpdate, TaskResponse).
    * **.dockerignore**: Excludes unnecessary files from Docker build context (.venv, \_\_pycache\_\_, logs).
    * **.env.example**: Template for environment variables (database credentials, connection URL).
    * **docker-compose.yml**: Multi-container setup for API and PostgreSQL with health checks and networking.
    * **Dockerfile.api**: Multi-stage build for FastAPI app using uv package manager, runs as non-root user.
    * **Dockerfile.db**: PostgreSQL 16 Alpine image with init.sql schema initialization.
    * **init.sql**: Database schema definition and seed data for the tasks table.
    * **pyproject.toml**: Python project metadata and dependencies managed by uv/hatch.
    * **README.md**: Backend-specific documentation.
    * **requirements.lock**: Locked production dependencies for reproducible builds.
    * **requirements-dev.lock**: Locked development dependencies (pytest, httpx).
    * **requirements.txt**: Pip-compatible dependency list.

* **docs/**: Centralized directory for all project-related documentation and manuals.
    * **backend-local-development.md**: Local development guide with uv, Docker Compose, and testing workflows.
    * **devops-learning-plan-tasks.md**: Structured learning roadmap with 11 progressive DevOps tasks.
    * **jenkins-setup.md**: Jenkins master-agent architecture setup, Docker agents, and CI/CD configuration.

* **scripts/**: Includes bash scripts for health checks of the Jenkins service and the FastAPI application.
    * **.env.example**: Template for healthcheck script configuration (URLs, tokens, SSL settings).
    * **healthcheck_fastapi.sh**: Liveness/readiness probe for FastAPI with retry logic and exponential backoff.
    * **healthcheck_jenkins.sh**: Jenkins health check with Basic auth support and retry mechanism.
    * **jenkins-agent-entrypoint.sh**: Fixes docker.sock permissions before starting agent and download agent.jar in runtime.

* **.env.jenkins.example**: Template for Jenkins agents secret configuration.
* **.gitignore**: Git ignore rules for Python cache, environments, logs, and sensitive files.
* **docker-compose.jenkins.yml**: Jenkins master + inbound agent stack with networking, volumes, and health checks.
* **docker-compose.jenkins-agent-ubuntu.yml**: Ubuntu-based Jenkins agent stack for projects using uv package manager.
* **Dockerfile.jenkins-agent**: Jenkins inbound agent with Docker CLI, uv, and Python for CI/CD builds.
* **Dockerfile.jenkins-agent-ubuntu**: Ubuntu-based Jenkins agent with full toolchain (Java, Docker, uv, Python).
* **Jenkinsfile**: Declarative pipeline with stages: checkout, install, test, build, deploy, healthcheck.
* **setup.md**: Quick reference for running the development environment setup script.
* **setup.sh**: Automated setup script installing Docker, Python, uv, and configuring the environment (Debian/Ubuntu).
* **setup-dnf.sh**: Automated setup script for Fedora/RHEL-based systems using dnf package manager.
---

## Quick Start

To set up the development environment (see [setup.md](./setup.md) for details), run:

* if you work on Ubuntu (tested), Debian and its derivates (like Kali Linux, Parrot OS, Linux Mint, etc.)

```bash
chmod +x setup.sh
sudo ./setup.sh
```

* if you work on Fedora (tested), CentOS, RHEL and its derivates (like Oracle Linux, AlmaLinux, Rocky Linux, etc.)

```bash
chmod +x setup-dnf.sh
sudo ./setup-dnf.sh
```

Scripts should not work on Arch Linux (pacman), openSUSE (zypper), Alpine Linux (apk).

## Next Steps

After running `setup.sh`, you can:

1. **Start local development** - Follow [Backend Local Development](./docs/backend-local-development.md) to set up Python environment, run containers with Docker Compose, and test the API.

2. **Set up Jenkins CI/CD** - Follow [Jenkins Setup](./docs/jenkins-setup.md) to configure Jenkins master with Docker-based agents for automated builds and deployments.

---
