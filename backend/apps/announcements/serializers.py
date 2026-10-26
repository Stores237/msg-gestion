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


class AnnouncementSerializer(serializers.ModelSerializer):
    event = EventField(required=False, allow_null=True)
    event_title = serializers.CharField(source="event.title", read_only=True, default=None)
    event_starts_at = serializers.DateTimeField(source="event.starts_at", read_only=True, default=None)
    author_name = serializers.SerializerMethodField()
    author_role = serializers.SerializerMethodField()
    unread = serializers.SerializerMethodField()
    reads = serializers.SerializerMethodField()
    attachments = AttachmentSerializer(many=True, read_only=True)

    class Meta:
        model = Announcement
        fields = ["id", "kind", "title", "body", "event", "event_title", "event_starts_at", "pinned", "author_name", "author_role", "created_at", "unread", "reads", "attachments"]
        read_only_fields = ["created_at"]

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
        if viewer is None or not (a.author_id == viewer.pk or viewer.can("announcements.posts", "change")):
            return None
        return {"read": getattr(a, "read_count", a.reads.count()), "total": self.context.get("audience", 0)}

    def validate(self, data):
        kind = data.get("kind", getattr(self.instance, "kind", Announcement.Kind.ANNOUNCEMENT))
        if kind == Announcement.Kind.CONVOCATION and not data.get("event", getattr(self.instance, "event", None)):
            raise serializers.ValidationError({"event": serializers.ErrorDetail("Une convocation doit être liée à un événement.", code="event_required")})
        return data
