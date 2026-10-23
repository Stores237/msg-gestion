from django import template
from django.utils.html import format_html
from django.utils.safestring import mark_safe

from apps.accounts.phone import format_phone

register = template.Library()


@register.filter
def phone(value):
    return format_phone(value or "")

ROLE_BADGE_CLASS = {"bureau": "bureau", "systeme": "sys", "temporaire": "temp", "standard": ""}
STATUS_DOT = {"actif": "ok", "conge": "warn", "classe": "off", "suspendu": "off", "archive": "off"}


@register.simple_tag
def icon(name, size=18):
    # Replaced by an inline <svg> by lucide.createIcons() (base.html).
    return format_html('<i data-lucide="{}" width="{}" height="{}" aria-hidden="true"></i>', name, size, size)


@register.simple_tag
def avatar(user, size=36):
    initials = "".join(w[0] for w in user.full_name.split()[:2]).upper()
    return format_html(
        '<span class="avatar" style="width:{0}px;height:{0}px;font-size:{1}px">{2}</span>', size, round(size * 0.36), initials
    )


@register.simple_tag
def role_badge(role, ends_on=None, starts_on=None):
    cls = ROLE_BADGE_CLASS.get(role.kind, "")
    one_day = ends_on is not None and ends_on == starts_on
    until = None
    if one_day:
        until = f"du jour {ends_on:%d/%m}"
    elif ends_on:
        until = f"fin {ends_on:%d/%m/%Y}" if role.kind == "bureau" else f"jusqu’au {ends_on:%d/%m}"
    extra = format_html('<span style="font-weight:600;opacity:.85">· {}</span>', until) if until else ""
    timer = mark_safe('<i data-lucide="timer" width="12" height="12"></i>') if role.kind == "temporaire" or one_day else ""
    return format_html('<span class="rb {}"><i></i>{}{}{}</span>', cls, role.name, extra, timer)


@register.simple_tag
def status(user):
    return format_html('<span class="status {}"><i></i>{}</span>', STATUS_DOT.get(user.status, "off"), user.get_status_display())
