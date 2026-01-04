# TaskMaster API

FastAPI task management application with PostgreSQL backend.

## 🚀 Quick Start

### Prerequisites
- Python 3.12+
- uv package manager
- PostgreSQL 15+

### Installation

1. **Clone repository**
```bash
   git clone <your-repo-url>
   cd pantheon/backend
```

2. **Create virtual environment**
```bash
   cd ..  # pantheon root
   uv venv .venv
   source .venv/bin/activate
```

3. **Install dependencies**
```bash
   cd backend
   uv pip install -r requirements.lock
   # or in development (check 🧪 Development section below)
   uv pip install -e ".[dev]"
```

4. **Configure environment**
```bash
   cp .env.example .env
   # Edit .env with your DATABASE_URL
```

5. **Run application**
```bash
   uvicorn taskmaster_api.app:app --host 0.0.0.0 --port 8000 --reload
```

## 🏥 Health Check
```bash
curl http://localhost:8000/health
# Expected: {"status": "ok", "database": "connected"}
```

## 📚 API Documentation

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 🧪 Development

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

## 📁 Project Structure
```
backend/
├── app.py              # FastAPI application
├── models.py           # Pydantic models
├── database.py         # Database connection
├── crud.py             # CRUD operations
├── pyproject.toml      # Dependencies specification
└── requirements.lock   # Locked versions
```

## 🔐 Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@localhost:5432/db` |

