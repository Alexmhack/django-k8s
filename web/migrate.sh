#! /usr/bin/bash

cd /app/

/opt/venv/bin/python manage.py createsuperuser --email test@django.com --username test --no-input || true

/opt/venv/bin/python manage.py migrate --no-input  # || true -> this after the bash script tells that if command fails then bash script won't fail
