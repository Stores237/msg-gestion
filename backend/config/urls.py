from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from django.views.generic import RedirectView
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

from apps.core.api import BureauHomeView, NotificationListView, NotificationReadView, SettingsView
from apps.core.views import healthz, run_task

urlpatterns = [
    path("", RedirectView.as_view(pattern_name="backoffice:dashboard", permanent=False)),
    path("bo/", include("apps.backoffice.urls")),
    path("admin/", admin.site.urls),
    path("healthz/", healthz, name="healthz"),
    path("internal/tasks/<str:name>/", run_task, name="internal-task"),
    path("api/", include("apps.accounts.urls")),
    path("api/members/", include("apps.members.urls")),
    path("api/events/", include("apps.events.urls")),
    path("api/announcements/", include("apps.announcements.urls")),
    path("api/finances/", include("apps.finances.urls")),
    path("api/settings/", SettingsView.as_view(), name="settings"),
    path("api/home/bureau/", BureauHomeView.as_view(), name="home-bureau"),
    path("api/notifications/", NotificationListView.as_view(), name="notifications"),
    path("api/notifications/read/", NotificationReadView.as_view(), name="notifications-read"),
    path("api/planning/", include("apps.planning.urls")),
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
