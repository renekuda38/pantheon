--- FILE: pantheon/README.md ---

# Pantheon Project

This project is a learning platform designed for developing and deploying a FastAPI application named TaskMaster API. It covers the integration of modern DevOps tools including Jenkins, Docker, Terraform, and Ansible.

## Documentation and Learning Path

All detailed project documentation is located in the docs/ directory. Please refer to the following files for specific instructions:

* **[DevOps Learning Plan](./docs/devops-learning-plan-tasks.md)**: A structured roadmap containing 11 tasks covering Linux basics, Python environment management, containerization, and CI/CD automation.
* **[App and Environment Setup](./docs/app-virtual-env-uv.md)**: Comprehensive instructions for managing the Python environment using the uv package manager, installing dependencies, and running the FastAPI application.
* **[Jenkins Setup](./docs/jenkins-setup.md)**: Documentation for local Jenkins development, including persistent volume creation, plugin management, and Docker agent configuration.
* **[Jenkins Master Workaround](./docs/jenkins-master-workaround.md)**: A temporary configuration guide for running builds directly on the Jenkins master node during Task 5.

## Project Structure

* **backend/**: Contains the FastAPI application source code, including models, database connection logic, and CRUD operations.
* **scripts/**: Includes bash scripts for health checks of the Jenkins service and the FastAPI application.
* **docs/**: Centralized directory for all project-related documentation and manuals.
* **Jenkinsfile**: The Groovy-based pipeline definition for automated builds and testing.
* **Dockerfile.jenkins-agent**: Dockerfile for the Jenkins inbound agent used to offload builds from the master node.

## Quick Start

To initialize the project environment and run initial scripts, execute the setup script from the root:

```bash
chmod +x setup.sh
./setup.sh