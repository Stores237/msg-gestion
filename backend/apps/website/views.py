"""The public site (owner, 2026-11-05): Huddle's page and its download.

No sign-in. The download button follows the link set in back-office →
Plateforme, so a new build only needs a new link there, not a deploy."""

from django.http import HttpResponseRedirect
from django.shortcuts import redirect, render
from django.views.decorators.cache import cache_control
from django.views.decorators.http import require_safe

from apps.core.models import PlatformSettings


@require_safe
@cache_control(public=True, max_age=300)
def home(request):
    return render(request, "website/index.html", {"p": PlatformSettings.get()})


@require_safe
@cache_control(public=True, max_age=60)
def download(request):
    return render(request, "website/download.html", {"p": PlatformSettings.get()})


@require_safe
@cache_control(no_store=True)
def apk(request):
    """Always the link of the day, never a cached old one."""
    url = PlatformSettings.get().app_download_url
    if not url.startswith("https://"):
        return redirect("website:download")
    return HttpResponseRedirect(url)
