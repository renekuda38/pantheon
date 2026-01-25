# Setup

Development environment setup for the Pantheon project.

## Usage

```bash
sudo ./setup.sh
```

## Optional: Git configuration

Create a `.env` file before running:

```bash
GIT_USERNAME="Your Name"
GIT_EMAIL="your@email.com"
```

If `.env` doesn't exist, git can be configured manually later.

## What gets installed

- **Base packages**: curl, wget, git, vim, jq, tree, htop, net-tools
- **Docker**: Docker Engine + Compose plugin
- **Python**: python3, pip, venv
- **uv**: modern Python package manager

## After installation

1. Logout and login again (to apply docker group membership)
2. Navigate to your project: `cd ${SCRIPT_DIR}`
3. Copy `backend/.env.example` to `backend/.env` and configure it
4. Initialize backend: `cd backend && uv venv && source .venv/bin/activate`
5. Install dependencies: `uv pip install -e ".[dev]"`
6. Start development: `docker compose up -d`