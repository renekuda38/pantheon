#!/bin/bash

set -euo pipefail

# logging fuction
function log() 
{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${*:2}"
}

# check for root privileges
if [ "${EUID}" -ne 0 ]; then
  echo '[ERROR] root privilages required!'
  echo "usage: sudo $0"  
  exit 1
fi

# get directory where script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# check if .env file exists and source it (if .env exists)
if [ -f "${SCRIPT_DIR}/.env" ]; then
  log INFO "Loading environment variables from .env file ..."
  source "${SCRIPT_DIR}/.env"
else
  log WARNING ".env file not found in ${SCRIPT_DIR} directory - using defaults"
fi

# ====================
# start setup
# ====================
log SUCCESS "====================================================="
log SUCCESS "  Pantheon Project - Development Environment Setup   "
log SUCCESS "====================================================="

log INFO 'setup has been started ...'

# ====================
# udpate packages
# ====================

# update package index
log INFO 'updating package index ...'

dnf update -qq

# ====================
# install packages
# ====================

# install required packages
log INFO 'installing required packages ...'

dnf install -y -qq --skip-unavailable \
  curl \
  wget \
  git \
  vim \
  jq \
  tree \
  htop \
  net-tools \
  ca-certificates \
  gnupg \
  lsb-release \
  @development-tools

log SUCCESS "Base packages installed"

# ====================
# install docker
# ====================

log INFO "Checking Docker installation..."

if command -v docker &> /dev/null; then
  log SUCCESS "docker is already installed: $(docker --version)"
else
  log INFO "installing Docker ..."

  dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
  dnf install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  log SUCCESS "Docker installed successfully: $(docker --version)"
fi

# Enable and start Docker service
systemctl enable docker
systemctl start docker

# Add current user to docker group (if not root)
# true if the length of the string is non-zero
if [ -n "${SUDO_USER:-}" ]; then
  usermod -aG docker "${SUDO_USER}"
  log INFO "Added ${SUDO_USER} to docker group (logout and login to apply)"
else
  log WARN "could not determine user - docker group not configured"
fi

# ====================
# install Python
# ====================
log INFO "installing Python ..."

dnf install -y -qq python3 python3-pip python3-devel

log SUCCESS "python installed: $(python3 --version)"

# ====================
# install uv
# ====================
log INFO "checking uv installation..."

# Add uv to PATH for current session
export PATH="/root/.local/bin:$PATH"

if [ -f "/root/.local/bin/uv" ]; then
  log SUCCESS "uv is already installed for user root: $(uv --version)"
else
  log INFO "installing uv ..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Install for sudo user as well
if [ -n "${SUDO_USER:-}" ]; then
  if [ -f "/home/${SUDO_USER}/.local/bin/uv" ]; then
    log SUCCESS "uv is already installed for user ${SUDO_USER}: $(uv --version)"
  else
    su - "${SUDO_USER}" -c "curl -LsSf https://astral.sh/uv/install.sh | sh"
  fi
else
  log WARN "Could not determine user - uv installed only for root user"
fi

log SUCCESS "uv installed successfully"


# ====================
# create runtime dirs
# ====================
log INFO "creating runtime directories..."

mkdir -p "${SCRIPT_DIR}"/{logs,temp,data}

chmod 750 "${SCRIPT_DIR}"/logs
chmod 700 "${SCRIPT_DIR}"/data

log SUCCESS "runtime directories created in ${SCRIPT_DIR}"

# ====================
# configure git
# ====================
log INFO "Configuring Git..."

if [ -n "${GIT_EMAIL:-}" ] && [ -n "${GIT_USERNAME:-}" ]; then
  git config --global user.email "${GIT_EMAIL}"
  git config --global user.name "${GIT_USERNAME}"
  log SUCCESS "Git configured with email: ${GIT_EMAIL}"
else
  log WARNING "GIT_EMAIL and GIT_USERNAME not set in .env - skipping Git configuration"
  log INFO "You can set them later with:"
  log INFO "  git config --global user.email 'your-email@example.com'"
  log INFO "  git config --global user.name 'Your Name'"
fi

# Create .gitignore
if [ ! -f "${SCRIPT_DIR}/.gitignore" ]; then
  cat > "${SCRIPT_DIR}/.gitignore" << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
.venv/
venv/
ENV/
env/

# Docker
.dockerignore

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Environment
.env
.env.local

# Logs
logs/
*.log

# OS
.DS_Store
Thumbs.db

# Temporary
temp/
tmp/
*.tmp
EOF
  log SUCCESS "Created .gitignore file"
fi

# ====================
# setup completion
# ====================
log SUCCESS "==================================================================="
log SUCCESS "  Setup completed successfully!"
log SUCCESS "==================================================================="

echo ""
log INFO "Summary of installed tools:"
echo "  - Docker: $(docker --version)"
echo "  - Python: $(python3 --version)"
echo "  - uv: $(uv --version 2>/dev/null || echo 'installed (restart shell)')"
echo "  - Git: $(git --version)"
echo ""
log INFO "Next steps:"
echo "  1. Logout and login again (to apply docker group membership)"
echo "  2. Navigate to your project: cd ${SCRIPT_DIR}"
echo "  3. Copy backend/.env.example to backend/.env and configure it"
echo "  4. Initialize backend: cd backend && uv venv && source .venv/bin/activate"
echo "  5. Install dependencies: uv pip install -r requirements.txt"
echo "  6. Start development: docker compose up -d"
echo ""

# completed
log SUCCESS 'setup completed!'

exit 0