from config.version import VERSION, commit


def version(request):
    """Every back-office page shows the developer's signature with the
    version and the deployed commit (_powered.html)."""
    return {"app_version": VERSION, "app_commit": commit()}
