from rest_framework import serializers

from .models import ActivityType, Attendance, DressCode, Event, dress_names, kind_names


class EventSerializer(serializers.ModelSerializer):
    my_attendance = serializers.SerializerMethodField()
    kind_name = serializers.SerializerMethodField()
    dress_name = serializers.SerializerMethodField()

    class Meta:
        model = Event
        fields = ["id", "kind", "kind_name", "title", "starts_at", "ends_at", "place", "dress", "dress_name", "notes", "my_attendance"]

    def _names(self, key, load):
        cache = self.context.setdefault("_names", {})
        if key not in cache:
            cache[key] = load()
        return cache[key]

    def get_kind_name(self, event) -> str:
        return self._names("kinds", kind_names).get(event.kind, event.kind)

    def get_dress_name(self, event) -> str:
        return self._names("dresses", dress_names).get(event.dress, event.dress) if event.dress else ""

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
        return data


class MarkSerializer(serializers.Serializer):
    member = serializers.IntegerField()
    status = serializers.ChoiceField(choices=Attendance.Status.choices + [("", "non marqué")])


class AttendanceSheetSerializer(serializers.Serializer):
    marks = MarkSerializer(many=True)


class ExcuseSerializer(serializers.Serializer):
    reason = serializers.CharField(max_length=240, required=False, allow_blank=True, default="")
