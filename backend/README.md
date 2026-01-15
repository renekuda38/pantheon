# TaskMaster API

FastAPI task management application with PostgreSQL backend.

## Docker

### Build

```bash
docker build -t taskmaster .
```

### Run

```bash
docker run -p 8000:8000 -e DATABASE_URL="postgresql://user:pass@host:5432/db" taskmaster
```

## Health Check

```bash
curl http://localhost:8000/health
# Expected: {"status": "ok", "database": "connected"}
```

Or use the health check script from the host:

```bash
../scripts/healthcheck_fastapi.sh http://localhost:8000/health
```

## API Documentation

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Local Development

For running without Docker (local venv setup), see [docs/app-virtual-env-uv.md](../docs/app-virtual-env-uv.md).
