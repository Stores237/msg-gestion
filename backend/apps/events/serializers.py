from rest_framework import serializers

from apps.accounts.models import User

from . import reports
from .models import ActivityType, Attendance, DressCode, Event, EventReport, dress_descriptions, dress_names, kind_names


class EventSerializer(serializers.ModelSerializer):
    my_attendance = serializers.SerializerMethodField()
    kind_name = serializers.SerializerMethodField()
    dress_name = serializers.SerializerMethodField()
    dress_detail = serializers.SerializerMethodField()
    created_by_name = serializers.SerializerMethodField()
    created_by_role = serializers.SerializerMethodField()
    can_edit = serializers.SerializerMethodField()
    ended = serializers.SerializerMethodField()
    can_delete = serializers.SerializerMethodField()
    chef = serializers.PrimaryKeyRelatedField(queryset=User.objects.none(), allow_null=True, required=False)
    chef_name = serializers.SerializerMethodField()
    report_due_at = serializers.SerializerMethodField()
    report_status = serializers.SerializerMethodField()
    can_report = serializers.SerializerMethodField()
    can_read_report = serializers.SerializerMethodField()
    report_read_by = serializers.SerializerMethodField()
    has_lineup = serializers.SerializerMethodField()
    my_duty = serializers.SerializerMethodField()
    from_group = serializers.SerializerMethodField()
    contingent = serializers.SerializerMethodField()

    class Meta:
        model = Event
        fields = ["id", "kind", "kind_name", "kind_other", "scope", "title", "starts_at", "ends_at", "place", "place_detail", "dress", "dress_name", "dress_detail",
                  "notes", "my_attendance", "created_by_name", "created_by_role", "can_edit", "can_delete", "ended",
                  "chef", "chef_name", "report_due_at", "report_status", "can_report", "can_read_report", "report_read_by",
                  "has_lineup", "my_duty", "cascade", "from_group", "contingent"]
        read_only_fields = ["created_by_name", "created_by_role", "can_edit", "can_delete", "ended"]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # The chef is one of this group's active members.
        self.fields["chef"].queryset = User.objects.members().filter(is_active=True, gstatus=User.Status.ACTIVE)

    def get_report_read_by(self, event) -> str | None:
        """Who opened the report first (it is locked from then on)."""
        if not reports.is_read(event):
            return None
        return event.report.read_by.short_name if event.report.read_by else ""

    def get_has_lineup(self, event) -> bool:
        return event.pk in self.context.get("lineups", ())

    def get_my_duty(self, event) -> dict | None:
        """The viewer's post at this event (and chef), if they serve."""
        return self.context.get("duties", {}).get(event.pk)

    def get_chef_name(self, event) -> str | None:
        return event.chef.short_name if event.chef else None

    def get_report_due_at(self, event):
        return event.report_due_at if event.chef_id else None

    def get_report_status(self, event) -> str:
        return reports.status(event)

    def get_can_report(self, event) -> bool:
        v = self.context.get("viewer")
        return bool(v) and not self._foreign(event) and reports.can_submit(v, event)

    def get_can_read_report(self, event) -> bool:
        v = self.context.get("viewer")
        return bool(v) and not self._foreign(event) and reports.status(event) in ("submitted", "late") and reports.can_read(v, event)

    # Whoever added it edits and deletes it (owner, 2026-10-26); people with
    # the calendar's change / delete rights can for any event.
    def _foreign(self, event) -> bool:
        from apps.core.groups import current_group_id

        gid = current_group_id()
        return gid is not None and event.group_id is not None and event.group_id != gid

    def get_from_group(self, event) -> dict | None:
        """The group above that sent it down (build 41), read-only here."""
        from apps.core.groups import current_group_id
        from apps.core.network import origin

        return origin(event, current_group_id(), self.context.get("request")) if self._foreign(event) else None

    def get_contingent(self, event) -> dict | None:
        """Joint planning (build 42). From above: what this group is asked
        and whether the viewer is named. Sent down by this group: totals."""
        from apps.core.groups import current_group_id

        from .models import EventContingent

        if not event.cascade:
            return None
        v = self.context.get("viewer")
        if self._foreign(event):
            c = EventContingent.objects.filter(event=event, group_id=current_group_id()).prefetch_related("members").first()
            if c is None:
                return None
            ids = {u.pk for u in c.members.all()}
            return {"requested": c.requested, "designated": len(ids), "me": bool(v) and v.pk in ids}
        rows = list(EventContingent.objects.filter(event=event).prefetch_related("members"))
        if not rows:
            return None
        return {"requested": sum(c.requested for c in rows), "designated": sum(len(c.members.all()) for c in rows),
                "groups": len(rows), "me": False}

    def get_can_edit(self, event) -> bool:
        v = self.context.get("viewer")
        return bool(v) and not self._foreign(event) and not event.has_ended() and (event.created_by_id == v.pk or v.can("calendar.events", "change"))

    def get_can_delete(self, event) -> bool:
        v = self.context.get("viewer")
        return bool(v) and not self._foreign(event) and not event.has_ended() and (event.created_by_id == v.pk or v.can("calendar.events", "delete"))

    def get_ended(self, event) -> bool:
        return event.has_ended()

    def get_created_by_name(self, event) -> str | None:
        return event.created_by.short_name if event.created_by else None

    def get_created_by_role(self, event) -> str:
        # Saved when created; older events show the author's role now.
        if event.created_by_role or event.created_by is None:
            return event.created_by_role
        return event.created_by.display_role()

    def _names(self, key, load):
        cache = self.context.setdefault("_names", {})
        if key not in cache:
            cache[key] = load()
        return cache[key]

    def _in_origin(self, event, key, load):
        """Names from the event's own group (an event sent down from above
        uses that group's activity types and dress codes)."""
        if not self._foreign(event):
            return self._names(key, load)
        from apps.core.groups import in_group

        cache = self.context.setdefault("_names", {})
        k = (key, event.group_id)
        if k not in cache:
            with in_group(event.group_id):
                cache[k] = load()
        return cache[k]

    def get_kind_name(self, event) -> str:
        return self._in_origin(event, "kinds", kind_names).get(event.kind, event.kind)

    def get_dress_detail(self, event) -> str:
        """What the dress means in this group (Paramètres → Tenues)."""
        return self._in_origin(event, "dress_details", dress_descriptions).get(event.dress, "") if event.dress else ""

    def get_dress_name(self, event) -> str:
        return self._in_origin(event, "dresses", dress_names).get(event.dress, event.dress) if event.dress else ""

    def validate_cascade(self, value):
        if value:
            from apps.core.models import Settings

            if not Settings.get().group.children.filter(is_active=True).exists():
                raise serializers.ValidationError("Aucun groupe n’est rattaché au vôtre.", code="no_groups_below")
        return value

    def validate_kind(self, value):
        # The group's own list (back-office → Paramètres).
        if not ActivityType.objects.filter(slug=value, is_archived=False).exists():
            raise serializers.ValidationError("Type d’activité inconnu dans ce groupe.", code="bad_kind")
        return value

    def validate_dress(self, value):
        if value and not DressCode.objects.filter(slug=value, is_archived=False).exists():
            raise serializers.ValidationError("Tenue inconnue dans ce groupe.", code="bad_dress")
        return value

    def get_my_attendance(self, event) -> str | None:
        return self.context.get("mine", {}).get(event.pk)

    def validate(self, data):
        starts = data.get("starts_at", getattr(self.instance, "starts_at", None))
        ends = data.get("ends_at", getattr(self.instance, "ends_at", None))
        if starts and ends and ends <= starts:
            raise serializers.ValidationError({"ends_at": serializers.ErrorDetail("La fin doit être après le début.", code="ends_before_start")})
        kind = data.get("kind", getattr(self.instance, "kind", None))
        activity = ActivityType.objects.filter(slug=kind).first()
        errors = {}
        # "Autre": the author says what it is.
        other = data.get("kind_other", getattr(self.instance, "kind_other", "")).strip()
        if kind == Event.Kind.OTHER and not other:
            errors["kind_other"] = serializers.ErrorDetail("Précisez le type d’événement.", code="kind_other_required")
        data["kind_other"] = other if kind == Event.Kind.OTHER else ""
        # Intérieur / extérieur for the types that have it (Messe).
        scope = data.get("scope", getattr(self.instance, "scope", ""))
        if activity is not None and activity.has_scope:
            if scope not in (Event.Scope.INSIDE, Event.Scope.OUTSIDE):
                errors["scope"] = serializers.ErrorDetail("Choisissez intérieur ou extérieur.", code="scope_required")
        else:
            data["scope"] = ""
        # A chef de groupe for every type that has one (not meetings).
        chef = data["chef"] if "chef" in data else getattr(self.instance, "chef", None)
        if activity is not None and not activity.needs_chef:
            data["chef"] = None
        elif chef is None and activity is not None:
            errors["chef"] = serializers.ErrorDetail("Désignez le chef de groupe.", code="chef_required")
        if errors:
            raise serializers.ValidationError(errors)
        return data


class EventReportSerializer(serializers.ModelSerializer):
    author_name = serializers.SerializerMethodField()
    file_url = serializers.SerializerMethodField()
    late = serializers.BooleanField(read_only=True)
    read_by_name = serializers.SerializerMethodField()

    class Meta:
        model = EventReport
        fields = ["body", "file_name", "file_url", "author_name", "submitted_at", "late", "read_at", "read_by_name"]

    def get_read_by_name(self, r) -> str | None:
        return r.read_by.short_name if r.read_by else None

    def get_author_name(self, r) -> str | None:
        return r.author.short_name if r.author else None

    def get_file_url(self, r) -> str | None:
        if not r.file:
            return None
        url = r.file.url  # signed on Supabase Storage
        request = self.context.get("request")
        return request.build_absolute_uri(url) if request and url.startswith("/") else url


class MarkSerializer(serializers.Serializer):
    member = serializers.IntegerField()
    status = serializers.ChoiceField(choices=Attendance.Status.choices + [("", "non marqué")])


class AttendanceSheetSerializer(serializers.Serializer):
    marks = MarkSerializer(many=True)


class ExcuseSerializer(serializers.Serializer):
    reason = serializers.CharField(max_length=240, required=False, allow_blank=True, default="")
