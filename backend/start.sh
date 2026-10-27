#!/bin/sh
# Container start (Render). Each step prints a timestamped marker first, so
# a deploy that stops mid-way shows where in Render's logs (2026-10-27: a
# deploy hung silently before migrate's first line and never opened its port).
set -e
step() { echo "[start $(date -u +%H:%M:%S)] $1"; }

step "collectstatic"
python manage.py collectstatic --no-input
# System checks run in CI and the test suite; skipping them here saves ~20 s
# of boot on Render's small instance.
step "migrate"
python manage.py migrate --skip-checks
step "ensure_superuser"
python manage.py ensure_superuser
step "gunicorn on port $PORT"
exec gunicorn config.wsgi:application --bind 0.0.0.0:$PORT --workers ${WEB_CONCURRENCY:-2} --timeout 60
