from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from django.views.generic import RedirectView
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

from apps.core.views import healthz, run_task

urlpatterns = [
    path("", RedirectView.as_view(pattern_name="backoffice:dashboard", permanent=False)),
    path("bo/", include("apps.backoffice.urls")),
    path("admin/", admin.site.urls),
    path("healthz/", healthz, name="healthz"),
    path("internal/tasks/<str:name>/", run_task, name="internal-task"),
    path("api/", include("apps.accounts.urls")),
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
