#! /usr/bin/bash

APP_PORT=${PORT:-8000}  # :- is to define the default value if not found in the variable PORT

cd /app/

/opt/venv/bin/gunicorn --worker-tmp-dir /dev/shm backend.asgi:application -k uvicorn.workers.UvicornWorker --bind "0.0.0.0:${APP_PORT}"
