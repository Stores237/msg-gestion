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

# collectstatic/migrate/ensure_superuser run at container *start* (start.sh):
# the real env vars (DATABASE_URL, secrets) only exist once Render runs the
# container, never during `docker build`. All three are idempotent.
# start.sh `exec`s gunicorn so it is PID 1 and gets Render's SIGTERM directly.
CMD ["sh", "start.sh"]
