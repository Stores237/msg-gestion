"""A group's identity as the app shows it (owner, 2026-11-02, like a Slack
workspace): name, sigle or initials, logo and colours."""


def logo_url(group, request=None):
    if not group.logo:
        return None
    url = group.logo.url  # signed on Supabase Storage
    return request.build_absolute_uri(url) if request is not None and url.startswith("/") else url


def group_identity(group, request=None):
    from .models import Settings

    st = Settings.get(group)
    return {"id": group.pk, "name": group.name, "initials": group.initials, "short_name": group.short_name,
            "logo": logo_url(group, request), "color": st.color, "color2": st.color2,
            # Its place in a network (owner, 2026-11-03), for the group list.
            "level_name": group.level_name, "parent": group.parent.name if group.parent_id else None}
