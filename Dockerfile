# Use a multi-stage build to keep the final image minimal and secure
# Use a Python-preinstalled uv image for better reliability
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder

# Set the working directory in the container
WORKDIR /app

# Optimize uv performance
# - UV_COMPILE_BYTECODE: Compiles .py to .pyc for faster startup
# - UV_LINK_MODE: Use 'copy' instead of 'hardlink' for better compatibility in Docker
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

# Copy only the files needed for dependency resolution
COPY pyproject.toml uv.lock README.md ./

# Install dependencies and the specific Python version (reads from pyproject.toml)
# --frozen: ensures the lockfile is respected and not updated
# --no-dev: excludes development dependencies like pytest or ruff
# --no-install-project: skips installing the current project to speed up caching
RUN uv sync --frozen --no-install-project --no-dev

# Copy the rest of the application source code
COPY . .

# Run the final sync to install the project itself
RUN uv sync --frozen --no-dev


# Stage 2: Runtime
# Using debian-slim for a lean but compatible runtime environment
FROM debian:bookworm-slim

# Set environment variables for Python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/app/.venv/bin:$PATH"

WORKDIR /app

# Install minimal runtime dependencies if needed
# (Python 3.14 binaries managed by uv are mostly self-contained)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy the application and pre-configured virtual environment from the builder
COPY --from=builder /app /app

# Ensure the app runs as a non-privileged user for better security
RUN useradd -m appuser && chown -R appuser /app
USER appuser

# Expose the API port
EXPOSE 8000

# Healthcheck to ensure the container is healthy
# We use a simple python script to check the endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/')" || exit 1

# Command to launch the application using uvicorn
# --host 0.0.0.0 is essential for accessibility outside the container
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
