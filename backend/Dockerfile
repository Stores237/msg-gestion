# Docker, not Render's native Python runtime, decided up front (playbook
# §4): the native runtime blocks apt-get entirely, and switching later
# changes the shape of every service block in render.yaml. Nothing needs a
# system package yet; PDF exports (rapport trimestriel, livre de caisse)
# may, and will only need a line here.
FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# collectstatic/migrate/ensure_superuser run at container *start*: the
# real env vars (DATABASE_URL, secrets) only exist once Render runs the
# container, never during `docker build`. All three are idempotent.
# `exec` makes gunicorn PID 1 so it gets Render's SIGTERM directly.
CMD ["sh", "-c", "python manage.py collectstatic --no-input && python manage.py migrate && python manage.py ensure_superuser && exec gunicorn config.wsgi:application --bind 0.0.0.0:$PORT --workers ${WEB_CONCURRENCY:-2} --timeout 60"]
