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

1. **Logout and login** (to apply docker group membership)
2. Configure `backend/.env` based on `.env.example`
3. Start the project: `docker compose up -d`
