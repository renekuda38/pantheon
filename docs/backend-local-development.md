# TaskMaster API - Local Development

Local development of Python application with uv package manager.

> **Production/CI environment** uses `docker-compose.yml` in `backend/` directory, which handles building and deploying containers (API + PostgreSQL).

---

## 1. Setup Python Environment

```bash
# Navigate to project root
cd pantheon

# Create virtual environment
uv venv .venv

# Activate venv
source .venv/bin/activate

# Install dependencies (development)
cd backend
uv pip install -e ".[dev]"
```

---

## 2. Dependency Management - Key Differences

### Installation Methods

| Method | Description | Usage |
|--------|-------------|-------|
| `uv pip install -r requirements.lock` | Installs exact versions from lock file | **Production** - reproducible builds |
| `uv pip install -e .` | Editable install from pyproject.toml | Development - core dependencies only |
| `uv pip install -e ".[dev]"` | Editable install + dev dependencies | **Development** - includes pytest, httpx |

### What is Editable Install (`-e`)?

**The application behaves as an installed Python library:**

```bash
# With editable install you can import from anywhere in venv:
python -c "from taskmaster_api.app import app; print(app.title)"

# Code changes are reflected IMMEDIATELY without reinstallation
# Ideal for development - edit code, run, test
```

**How it works:**
- `uv pip install -e .` creates a symlink in `site-packages/`
- Python imports directly from your working directory
- No file copying = immediate reflection of changes

### Generating Lock Files

```bash
cd backend

# Production dependencies (from pyproject.toml [dependencies])
uv pip compile pyproject.toml -o requirements.lock

# Development dependencies (from pyproject.toml [project.optional-dependencies.dev])
uv pip compile pyproject.toml --extra dev -o requirements-dev.lock
```

**Why two lock files?**

| File | Contents | Where it's used |
|------|----------|-----------------|
| `requirements.lock` | Runtime dependencies only (fastapi, uvicorn, psycopg2) | Dockerfile.api, production |
| `requirements-dev.lock` | Runtime + dev (pytest, httpx, pytest-asyncio) | Local development, CI tests |

### When to Use What?

```bash
# DEVELOPMENT (local)
uv pip install -e ".[dev]"     # Editable + dev tools

# PRODUCTION (Docker/CI)
uv pip install -r requirements.lock   # Exact versions, no dev tools

# CI TESTS (Jenkins)
uv pip install -r requirements-dev.lock   # Or -e ".[dev]"
```

**Production best practice:**
```dockerfile
# In Dockerfile NEVER use -e (editable)
# Code is copied into image, symlink not needed
COPY requirements.lock .
RUN uv pip install -r requirements.lock
```

---

## 3. Docker Compose - Running Containers

### Starting with Docker Compose

```bash
cd backend

# Create .env file (or use existing .env.example)
cp .env.example .env

# Build and start
docker-compose up -d --build

# Follow logs
docker-compose logs -f
```

### Environment Variables and .env File

**Variables in `docker-compose.yml` are loaded from `.env` file on the host:**

```yaml
# docker-compose.yml
environment:
  POSTGRES_USER: ${POSTGRES_USER}
  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
  POSTGRES_DB: ${POSTGRES_DB}
```

```bash
# .env (on host, same directory as docker-compose.yml)
POSTGRES_USER=taskmaster
POSTGRES_PASSWORD=secretpassword123
POSTGRES_DB=taskmaster_db
DATABASE_URL=postgresql://taskmaster:secretpassword123@db:5432/taskmaster_db
IMAGE_TAG=latest
```

**How it works:**
1. Docker Compose automatically looks for `.env` in the same directory
2. `${VARIABLE}` syntax is replaced with value from `.env`
3. If variable doesn't exist, you can define a default: `${IMAGE_TAG:-latest}`

**Security note:**
```bash
# .env file should NEVER be in Git repository!
# Check .gitignore:
echo ".env" >> .gitignore
```

### Verify .env is Loaded Correctly

```bash
# Display interpolated values
docker-compose config

# Output shows actual values instead of ${VARIABLE}
```

---

## 4. Testing

> **Prerequisite:** Containers must be running (`docker-compose up -d`)

### Health Check

```bash
# API health
curl http://localhost:8000/health

# DB connection
curl http://localhost:8000/db-health
```

### CRUD Operations

```bash
# List all tasks (should show 3 from init.sql)
curl http://localhost:8000/tasks

# Create new task
curl -X POST http://localhost:8000/tasks \
  -H "Content-Type: application/json" \
  -d '{"task_name": "New task", "task_desc": "Task description", "accomplish_time": 5}'

# Get task by ID
curl http://localhost:8000/tasks/1

# Update task
curl -X PUT http://localhost:8000/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{"done": true}'

# Delete task
curl -X DELETE http://localhost:8000/tasks/1
```

### Run pytest

```bash
# Requires dev dependencies
pytest

# Verbose output
pytest -v

# Specific test
pytest tests/test_api.py -v
```

---

## 5. API Documentation

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

---

## 6. Project Structure

```
backend/
├── taskmaster_api/
│   ├── app.py              # FastAPI application
│   ├── models.py           # Pydantic models
│   ├── database.py         # Database connection
│   └── crud.py             # CRUD operations
├── init.sql                # DB schema + test data
├── Dockerfile.api          # API container (multi-stage, non-root)
├── Dockerfile.db           # PostgreSQL container
├── docker-compose.yml      # Full stack orchestration
├── pyproject.toml          # Project metadata + dependencies
├── requirements.lock       # Locked production deps
├── requirements-dev.lock   # Locked dev deps
├── .env.example            # Environment template
└── .dockerignore           # Build context exclusions
```

---

## 7. Quick Reference

| Task | Command |
|------|---------|
| Local dev setup | `uv pip install -e ".[dev]"` |
| Run API | `uvicorn taskmaster_api.app:app --reload` |
| Run tests | `pytest -v` |
| Update prod deps | `uv pip compile pyproject.toml -o requirements.lock` |
| Update dev deps | `uv pip compile pyproject.toml --extra dev -o requirements-dev.lock` |
| Docker build + run | `docker-compose up -d --build` |
| Docker logs | `docker-compose logs -f api` |
| Docker cleanup | `docker-compose down -v` |
