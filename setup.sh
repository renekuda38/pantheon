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

apt-get update -qq

# ====================
# install packages
# ====================

# install required packages
log INFO 'installing required packages ...'

apt-get install -y -qq \
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
  software-properties-common \
  apt-transport-https \
  build-essential

log SUCCESS "Base packages installed"

# ====================
# install docker
# ====================

log INFO "Checking Docker installation..."

if command -v docker &> /dev/null; then
  log SUCCESS "docker is already installed: $(docker --version)"
else
  log INFO "installing Docker ..."

  # add Docker's official GPG key:
  install -m 0755 -d /etc/apt/keyrings

  if [ -f /etc/os-release ] && grep -qi ubuntu /etc/os-release; then
    DISTRO="ubuntu"
    CODENAME="$({ . /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}"; })"
  else
    DISTRO="debian"
    CODENAME="$(lsb_release -cs)"
  fi

  curl -fsSL "https://download.docker.com/linux/${DISTRO}/gpg" -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

  # add the repository to Apt sources:
  tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/${DISTRO}
Suites: ${CODENAME}
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  # install Docker Engine
  apt-get update -qq
  apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

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
fi

# ====================
# install Python
# ====================
log INFO "Installing Python..."

apt-get install -y -qq python3 python3-pip python3-venv python3-dev

log SUCCESS "python installed: $(python3 --version)"

# ====================
# install uv
# ====================
log INFO "checking uv installation..."

if command -v uv &> /dev/null; then
  log SUCCESS "uv is already installed: $(uv --version)"
else
  log INFO "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh

  # Add uv to PATH for current session
  export PATH="/root/.local/bin:$PATH"

  if [ -n "${SUDO_USER:-}" ]; then
    # Install for sudo user as well
    su - "${SUDO_USER}" -c "curl -LsSf https://astral.sh/uv/install.sh | sh"
  fi

  log SUCCESS "uv installed successfully"
fi

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