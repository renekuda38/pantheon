# TaskMaster API

FastAPI task management application with PostgreSQL backend.

## Quick Start (Docker Compose)

Run the full stack (API + PostgreSQL) with a single command:

```bash
cd backend
docker compose up -d --build
```

This automatically:
- Starts PostgreSQL with `init.sql` (creates table + 3 test records)
- Builds and runs the FastAPI application
- Connects both services via Docker network

### Useful Commands

```bash
# Show logs
docker compose logs -f

# Logs for API only
docker compose logs -f api

# Stop stack
docker compose down

# Stop + delete volumes (reset database)
docker compose down -v

# Restart after code changes
docker compose up -d --build
```

## Health Check

```bash
# API health
curl http://localhost:8000/health

# DB connection health
curl http://localhost:8000/db-health
```

## API Endpoints

### Create new task (POST)

```bash
curl -X POST http://localhost:8000/tasks \
  -H "Content-Type: application/json" \
  -d '{"task_name": "New task", "task_desc": "Task description", "accomplish_time": 5}'
```

### List all tasks (GET)

```bash
curl http://localhost:8000/tasks
```

### Get task by ID (GET)

```bash
curl http://localhost:8000/tasks/1
```

### Update task (PUT)

```bash
curl -X PUT http://localhost:8000/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{"done": true}'
```

### Delete task (DELETE)

```bash
curl -X DELETE http://localhost:8000/tasks/1
```

## API Documentation

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Manual Docker Build (without Compose)

If you need to run just the API container standalone:

```bash
# Build
docker build -t taskmaster .

# Run (requires your own PostgreSQL)
docker run -p 8000:8000 \
  -e DATABASE_URL="postgresql://user:pass@host:5432/db" \
  taskmaster
```

## Local Development

For development without Docker Compose (local venv setup), see [docs/app-virtual-env-uv.md](../docs/app-virtual-env-uv.md).
