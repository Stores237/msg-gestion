from rest_framework import serializers

from apps.events.models import Event

from .models import Announcement, Attachment


class AttachmentSerializer(serializers.ModelSerializer):
    url = serializers.SerializerMethodField()

    class Meta:
        model = Attachment
        fields = ["id", "name", "size", "content_type", "url"]

    def get_url(self, a) -> str:
        url = a.file.url  # signed and short-lived on S3/Supabase
        request = self.context.get("request")
        return request.build_absolute_uri(url) if request and url.startswith("/") else url


class EventField(serializers.PrimaryKeyRelatedField):
    """An event of the current group (looked up per request, not at import)."""

    def get_queryset(self):
        return Event.objects.all()


class TaggedField(serializers.PrimaryKeyRelatedField):
    """A member the announcement is for: one of the group's audience."""

    def get_queryset(self):
        from .views import _audience

        return _audience()


class AnnouncementSerializer(serializers.ModelSerializer):
    event = EventField(required=False, allow_null=True)
    event_title = serializers.CharField(source="event.title", read_only=True, default=None)
    event_starts_at = serializers.DateTimeField(source="event.starts_at", read_only=True, default=None)
    author_name = serializers.SerializerMethodField()
    author_role = serializers.SerializerMethodField()
    unread = serializers.SerializerMethodField()
    reads = serializers.SerializerMethodField()
    attachments = AttachmentSerializer(many=True, read_only=True)
    can_edit = serializers.SerializerMethodField()
    can_delete = serializers.SerializerMethodField()
    # Write the ids; read who they are and whether the viewer is one of them.
    tagged = TaggedField(many=True, required=False, write_only=True)
    tagged_members = serializers.SerializerMethodField()
    for_me = serializers.SerializerMethodField()
    from_group = serializers.SerializerMethodField()

    class Meta:
        model = Announcement
        fields = ["id", "kind", "title", "body", "event", "event_title", "event_starts_at", "pinned", "author_name", "author_role", "created_at", "unread", "reads", "attachments",
                  "can_edit", "can_delete", "tagged", "tagged_members", "for_me", "cascade", "from_group"]
        read_only_fields = ["created_at"]

    # The author edits and deletes their own post (owner, 2026-10-26); people
    # who manage announcements can for anyone's.
    def _foreign(self, a) -> bool:
        from apps.core.groups import current_group_id

        return a.group_id is not None and current_group_id() is not None and a.group_id != current_group_id()

    def get_from_group(self, a) -> dict | None:
        """The group above that sent it (build 41); None for this group's own."""
        from apps.core.groups import current_group_id
        from apps.core.network import origin

        return origin(a, current_group_id(), self.context.get("request")) if self._foreign(a) else None

    def get_can_edit(self, a) -> bool:
        v = self.context.get("viewer")
        return bool(v) and not self._foreign(a) and (a.author_id == v.pk or v.can("announcements.posts", "change"))

    def get_can_delete(self, a) -> bool:
        v = self.context.get("viewer")
        return bool(v) and not self._foreign(a) and (a.author_id == v.pk or v.can("announcements.posts", "delete"))

    def get_tagged_members(self, a) -> list[dict]:
        return [{"id": u.pk, "name": u.short_name} for u in sorted(a.tagged.all(), key=lambda u: (u.last_name, u.first_name))]

    def get_for_me(self, a) -> bool:
        v = self.context.get("viewer")
        return bool(v) and any(u.pk == v.pk for u in a.tagged.all())

    def validate_tagged(self, value):
        if len(value) > 200:
            raise serializers.ValidationError("200 membres au plus.", code="too_many")
        return value

    def get_author_name(self, a) -> str | None:
        return a.author.short_name if a.author else None

    def get_author_role(self, a) -> str:
        # Saved when posted; older announcements show the author's role now.
        if a.author_role or a.author is None:
            return a.author_role
        return a.author.display_role()

    def get_unread(self, a) -> bool:
        return a.pk not in self.context.get("read_ids", set())

    def get_reads(self, a) -> dict | None:
        """Read count, only for the author or people who manage announcements
        (design: "le compteur de lectures n’apparaît que pour l’expéditeur")."""
        viewer = self.context.get("viewer")
        if viewer is None or self._foreign(a) or not (a.author_id == viewer.pk or viewer.can("announcements.posts", "change")):
            return None
        total = self.context.get("audience", 0)
        if a.cascade:  # + the members of every group below (build 41)
            from apps.accounts.models import User
            from apps.core.groups import in_group

            for g in a.group.descendants():
                with in_group(g):
                    total += User.objects.members().filter(
                        gstatus__in=[User.Status.ACTIVE, User.Status.LEAVE], is_active=True).count()
        return {"read": getattr(a, "read_count", a.reads.count()), "total": total}

    def validate(self, data):
        kind = data.get("kind", getattr(self.instance, "kind", Announcement.Kind.ANNOUNCEMENT))
        if data.get("cascade"):
            from apps.core.models import Settings

            if kind != Announcement.Kind.ANNOUNCEMENT or data.get("tagged"):
                raise serializers.ValidationError({"cascade": serializers.ErrorDetail(
                    "Seule une annonce pour tout le groupe peut aller aux groupes rattachés.", code="cascade_announcement_only")})
            if not Settings.get().group.children.filter(is_active=True).exists():
                raise serializers.ValidationError({"cascade": serializers.ErrorDetail(
                    "Aucun groupe n’est rattaché au vôtre.", code="no_groups_below")})
        if kind == Announcement.Kind.CONVOCATION and not data.get("event", getattr(self.instance, "event", None)):
            raise serializers.ValidationError({"event": serializers.ErrorDetail("Une convocation doit être liée à un événement.", code="event_required")})
        return data
