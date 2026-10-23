"""The current group.

MSG is one platform serving several groups (owner, 2026-10-23). Every
request works inside one group: the app names it in the `X-Group` header
(apps.accounts.authentication), the back-office keeps it in the session
(apps.backoffice.access). It is held in a context variable for the duration
of the request, and every group-owned model's default manager filters on it
(GroupScopedManager), so a query can't reach another group's data by
forgetting a filter. `Model.all_groups` is the explicit way across groups
(platform jobs, the super admin's overviews).
"""

from contextlib import contextmanager
from contextvars import ContextVar

from django.db import models
from django.db.models import Q

_current = ContextVar("msg_current_group", default=None)


class NoGroupContext(Exception):
    """Creating group-owned data with several groups and none chosen."""


def current_group_id():
    return _current.get()


def set_current_group(group_id):
    return _current.set(group_id)


def reset_current_group(token=None):
    if token is not None:
        _current.reset(token)
    else:
        _current.set(None)


@contextmanager
def in_group(group):
    """with in_group(g): … — scripts, jobs and tests."""
    token = _current.set(group.pk if hasattr(group, "pk") else group)
    try:
        yield
    finally:
        _current.reset(token)


def default_group_id():
    """The `group` default of every group-owned model: the current group, or
    the only one when there is just one. With several groups and none
    chosen, refuse rather than guess."""
    gid = _current.get()
    if gid is not None:
        return gid
    from .models import Group

    ids = list(Group.objects.values_list("pk", flat=True)[:2])
    if len(ids) == 1:
        return ids[0]
    if not ids:
        return Group.objects.create(name="Groupe", slug="groupe").pk
    raise NoGroupContext("Plusieurs groupes : précisez le groupe.")


class GroupScopedManager(models.Manager):
    """Filters on the current group when one is set. `path` reaches the
    group from the model (e.g. "event__group"); `with_platform` also keeps
    rows that belong to no group (platform roles such as super admin).

    Both are class attributes because Django rebuilds related managers from
    the class alone; build one with scoped()."""

    path = "group"
    with_platform = False

    def get_queryset(self):
        qs = super().get_queryset()
        gid = _current.get()
        if gid is None:
            return qs
        cond = Q(**{self.path: gid})
        if self.with_platform:
            cond |= Q(**{f"{self.path}__isnull": True})
        return qs.filter(cond)


def scoped(path="group", with_platform=False, queryset=None):
    """A group-scoped manager: objects = scoped("event__group")."""
    base = GroupScopedManager.from_queryset(queryset) if queryset else GroupScopedManager
    name = "Scoped_" + path.replace("__", "_") + ("_platform" if with_platform else "")
    return type(name, (base,), {"path": path, "with_platform": with_platform, "__module__": __name__})()


class ClearGroupMiddleware:
    """Never let one request's group leak into the next on the same thread."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        reset_current_group()
        try:
            return self.get_response(request)
        finally:
            reset_current_group()
