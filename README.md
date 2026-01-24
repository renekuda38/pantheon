# Pantheon Project

This project is a learning platform designed for developing and deploying a FastAPI application named TaskMaster API. It covers the integration of modern DevOps tools including Jenkins, Docker, Terraform, and Ansible.

---

## Documentation and Learning Path

All detailed project documentation is located in the docs/ directory. Please refer to the following files for specific instructions:

* **[Setup Guide](./setup.md)**
  * Quick reference for running the development environment setup script, including optional Git configuration.
* **[DevOps Learning Plan](./docs/devops-learning-plan-tasks.md)**
  * A structured roadmap containing 11 tasks covering Linux basics, Python environment management, containerization, and CI/CD automation.
* **[App and Environment Setup](./docs/app-virtual-env-uv.md)**
  * Instructions for managing the Python environment using the uv package manager, installing dependencies, and running the FastAPI application.
* **[Jenkins Setup](./docs/jenkins-setup.md)**
  * Documentation for local Jenkins development, including persistent volume creation, plugin management, and Docker agent configuration.
---

## Project Structure

**backend/**: Contains the FastAPI application source code, including models, database connection logic, and CRUD operations.
    **taskmaster_api/**: Python package with the core application logic.
        `__init__.py`: Package initializer (empty).
        `app.py`: FastAPI application with REST endpoints for task CRUD operations and health checks.
        `crud.py`: Database operations (create, read, update, delete) using raw SQL with psycopg2.
        `database.py`: PostgreSQL connection management using psycopg2 with RealDictCursor.
        `models.py`: Pydantic models for request/response validation (TaskCreate, TaskUpdate, TaskResponse).
    `.dockerignore`: Excludes unnecessary files from Docker build context (.venv, __pycache__, logs).
    `.env.example`: Template for environment variables (database credentials, connection URL).
    `docker-compose.yml`: Multi-container setup for API and PostgreSQL with health checks and networking.
    `Dockerfile.api`: Multi-stage build for FastAPI app using uv package manager, runs as non-root user.
    `Dockerfile.db`: PostgreSQL 16 Alpine image with init.sql schema initialization.
    `init.sql`: Database schema definition and seed data for the tasks table.
    `pyproject.toml`: Python project metadata and dependencies managed by uv/hatch.
    `README.md`: Backend-specific documentation.
    `requirements.lock`: Locked production dependencies for reproducible builds.
    `requirements-dev.lock`: Locked development dependencies (pytest, httpx).
    `requirements.txt`: Pip-compatible dependency list.

**scripts/**: Includes bash scripts for health checks of the Jenkins service and the FastAPI application.
    `.env.example`: Template for healthcheck script configuration (URLs, tokens, SSL settings).
    `healthcheck_fastapi.sh`: Liveness/readiness probe for FastAPI with retry logic and exponential backoff.
    `healthcheck_jenkins.sh`: Jenkins health check with Basic auth support and retry mechanism.

**docs/**: Centralized directory for all project-related documentation and manuals.
    `app-virtual-env-uv.md`: Guide for Python environment setup using uv package manager.
    `devops-learning-plan-tasks.md`: Structured learning roadmap with 11 progressive DevOps tasks.
    `jenkins-setup.md`: Jenkins master-agent architecture setup and configuration guide.

`.gitignore`: Git ignore rules for Python cache, environments, logs, and sensitive files.
`Dockerfile.jenkins-agent`: Jenkins inbound agent with Docker CLI, uv, and Python for CI/CD builds.
`Dockerfile.jenkins-ubuntu`: Ubuntu-based Jenkins agent with full toolchain (Java, Docker, uv, Python).
`Jenkinsfile`: Declarative pipeline with stages: checkout, install, test, build, deploy, healthcheck.
`setup.md`: Quick reference for running the development environment setup script.
`setup.sh`: Automated setup script installing Docker, Python, uv, and configuring the environment.
---

## Quick Start

To set up the development environment (see [setup.md](./setup.md) for details), run:

```bash
chmod +x setup.sh
sudo ./setup.sh
```
---
