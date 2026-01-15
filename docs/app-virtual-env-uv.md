# TaskMaster API - Local Development

Manual setup of FastAPI application without Docker Compose.

## Prerequisites

- Python 3.12+
- uv package manager
- Docker (for PostgreSQL)

---

## 1. Start PostgreSQL

```bash
docker run -d \
  --name postgres-dev \
  -e POSTGRES_USER=taskmaster \
  -e POSTGRES_PASSWORD=taskmaster123 \
  -e POSTGRES_DB=taskmaster_db \
  -p 5432:5432 \
  postgres:16-alpine
```

---

## 2. Initialize Database

After PostgreSQL starts, create table and seed test data:

```bash
docker exec -i postgres-dev psql -U taskmaster -d taskmaster_db < backend/init.sql
```

This creates the `tasks` table and inserts 3 test records.

---

## 3. Setup Python Environment

```bash
# Navigate to project root
cd pantheon

# Create virtual environment
uv venv .venv

# Activate venv
source .venv/bin/activate

# Install dependencies
cd backend
uv pip install -r requirements.lock
```

---

## 4. Configure Environment Variables

```bash
# Set DATABASE_URL (in the same terminal where you'll run the app)
export DATABASE_URL="postgresql://taskmaster:taskmaster123@localhost:5432/taskmaster_db"
```

Or create a `.env` file:

```bash
echo 'DATABASE_URL=postgresql://taskmaster:taskmaster123@localhost:5432/taskmaster_db' > .env
```

---

## 5. Run Application

```bash
# From backend/ directory with activated venv
uvicorn taskmaster_api.app:app --host 0.0.0.0 --port 8000 --reload
```

`--reload` automatically restarts server on code changes (development only).

---

## 6. Testing

### Health check

```bash
# API health
curl http://localhost:8000/health

# DB connection
curl http://localhost:8000/db-health
```

### CRUD operations

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

---

## API Documentation

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

---

## Development

### Install dev dependencies

```bash
uv pip install -e ".[dev]"
```

### Run tests

```bash
pytest
```

### Update dependencies

```bash
# 1. Edit pyproject.toml
# 2. Regenerate lock file
uv pip freeze > requirements.lock
# 3. Install updated deps
uv pip install -r requirements.lock
```

---

## Cleanup

```bash
# Stop and remove PostgreSQL container
docker stop postgres-dev
docker rm postgres-dev

# Deactivate venv
deactivate
```

---

## Project Structure

```
backend/
├── taskmaster_api/
│   ├── app.py          # FastAPI application
│   ├── models.py       # Pydantic models
│   ├── database.py     # Database connection
│   └── crud.py         # CRUD operations
├── init.sql            # DB schema + test data
├── Dockerfile          # Container build
├── docker-compose.yml  # Full stack setup
├── pyproject.toml      # Dependencies
└── requirements.lock   # Locked versions
```

---

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://taskmaster:taskmaster123@localhost:5432/taskmaster_db` |
