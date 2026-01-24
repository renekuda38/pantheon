FROM python:3.12-slim AS base

WORKDIR /app

RUN pip install uv

COPY requirements.lock pyproject.toml ./

RUN uv pip install --system -r requirements.lock

COPY taskmaster_api/ ./taskmaster_api

RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

EXPOSE 8000

CMD ["uvicorn", "taskmaster_api.app:app", "--host", "0.0.0.0", "--port", "8000"]