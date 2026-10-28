from config.version import VERSION, commit


def version(request):
    """Every back-office page shows the developer's signature with the
    version and the deployed commit (_powered.html), and the account menu
    links to the platform's website when one is set (Plateforme · aide)."""
    from apps.core.models import PlatformSettings

    site = ""
    if getattr(request, "user", None) is not None and request.user.is_authenticated:
        site = PlatformSettings.objects.filter(pk=1).values_list("website", flat=True).first() or ""
    return {"app_version": VERSION, "app_commit": commit(), "platform_site": site}
