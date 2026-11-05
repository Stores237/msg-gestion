from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

from apps.core.api import (
    BureauHomeView,
    FaqSuggestionView,
    FaqView,
    GroupLogoView,
    GroupProfileView,
    NetworkGroupView,
    NetworkInvitationView,
    NetworkJoinView,
    NetworkLeaveView,
    NetworkRecipientsView,
    NetworkShareAskView,
    NetworkShareRequestsView,
    NetworkShareRequestView,
    NetworkSharingPreviewView,
    NetworkSharingView,
    NetworkTwinEndView,
    NetworkTwinJoinView,
    NetworkView,
    NotificationListView,
    NotificationReadView,
    PlatformView,
    SettingsView,
)
from apps.core.views import healthz, run_task

urlpatterns = [
    path("", include("apps.website.urls")),
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
    path("api/platform/", PlatformView.as_view(), name="platform"),
    path("api/faq/", FaqView.as_view(), name="faq"),
    path("api/faq/suggestions/", FaqSuggestionView.as_view(), name="faq-suggestions"),
    path("api/group/", GroupProfileView.as_view(), name="group-profile"),
    path("api/group/logo/", GroupLogoView.as_view(), name="group-logo"),
    path("api/network/", NetworkView.as_view(), name="network"),
    path("api/network/invitations/", NetworkInvitationView.as_view(), name="network-invitations"),
    path("api/network/join/", NetworkJoinView.as_view(), name="network-join"),
    path("api/network/leave/", NetworkLeaveView.as_view(), name="network-leave"),
    path("api/network/sharing/", NetworkSharingView.as_view(), name="network-sharing"),
    path("api/network/groups/<int:pk>/", NetworkGroupView.as_view(), name="network-group"),
    path("api/network/groups/<int:pk>/requests/", NetworkShareAskView.as_view(), name="network-share-ask"),
    path("api/network/requests/", NetworkShareRequestsView.as_view(), name="network-share-requests"),
    path("api/network/requests/<int:pk>/", NetworkShareRequestView.as_view(), name="network-share-request"),
    path("api/network/sharing/preview/", NetworkSharingPreviewView.as_view(), name="network-sharing-preview"),
    path("api/network/recipients/", NetworkRecipientsView.as_view(), name="network-recipients"),
    path("api/network/twins/join/", NetworkTwinJoinView.as_view(), name="network-twin-join"),
    path("api/network/twins/<int:pk>/end/", NetworkTwinEndView.as_view(), name="network-twin-end"),
    path("api/home/bureau/", BureauHomeView.as_view(), name="home-bureau"),
    path("api/notifications/", NotificationListView.as_view(), name="notifications"),
    path("api/notifications/read/", NotificationReadView.as_view(), name="notifications-read"),
    path("api/planning/", include("apps.planning.urls")),
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
