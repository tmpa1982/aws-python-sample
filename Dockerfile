# Use a multi-stage build to keep the final image minimal and secure
FROM python:3.13-slim-bookworm AS builder

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uv/bin/uv

# Set the working directory in the container
WORKDIR /app

# Optimize uv performance
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0

# Copy only the files needed for dependency resolution
COPY pyproject.toml uv.lock README.md ./

# Sync dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    /uv/bin/uv sync --frozen --no-install-project --no-dev

# Copy the rest of the application source code
COPY . .

# Run the final sync to install the project itself
RUN --mount=type=cache,target=/root/.cache/uv \
    /uv/bin/uv sync --frozen --no-dev


# Stage 2: Runtime
FROM python:3.13-slim-bookworm

# Add build argument for git commit hash
ARG GIT_COMMIT_HASH

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/app/.venv/bin:$PATH" \
    APP_VERSION=${GIT_COMMIT_HASH:-UNKNOWN}

WORKDIR /app

# Ensure we have essential runtime tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy the application and virtual environment from the builder
COPY --from=builder /app /app

# Ensure the app runs as a non-privileged user
RUN useradd -m appuser && chown -R appuser /app
USER appuser

# Expose the API port
EXPOSE 8000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/')" || exit 1

# Command to launch the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
