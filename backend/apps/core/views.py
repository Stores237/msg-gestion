import hmac

from django.conf import settings
from django.core.management import call_command
from django.db import connection
from django.http import Http404, JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST

# Management commands that cron-job.org may trigger on staging. Each one
# is also a Render Cron Job service for production (render.yaml).
TASKS = {"reminders": "send_reminders", "soon-reminders": "send_soon_reminders"}


def healthz(request):
    """Render's health check. Touches the database so a broken
    DATABASE_URL shows up as an unhealthy deploy, not a healthy-looking
    service that 500s on every real request."""
    from config.version import VERSION, commit

    with connection.cursor() as cur:
        cur.execute("SELECT 1")
    # The version and commit say which deploy answers (2026-10-27: a deploy
    # that never started left the previous version live, unnoticed).
    return JsonResponse({"status": "ok", "version": VERSION, "commit": commit()})


@csrf_exempt
@require_POST
def run_task(request, name):
    """Staging-only scheduler stand-in (playbook §4). 404 unless a token
    is configured, so production — which never sets one — has no such
    endpoint at all."""
    token = settings.TASK_TRIGGER_TOKEN
    supplied = request.headers.get("X-Task-Token", "")
    if not token or name not in TASKS or not hmac.compare_digest(token, supplied):
        raise Http404
    call_command(TASKS[name])
    return JsonResponse({"status": "done", "task": name})
