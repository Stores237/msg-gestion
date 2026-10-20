from datetime import date

from rest_framework import serializers

from apps.accounts.models import User
from apps.accounts.phone import format_phone
from apps.accounts.serializers import PhoneField


def _active_roles(user, today):
    """Uses the prefetched assignments (no query per row)."""
    return [
        a.role
        for a in user.assignments.all()
        if a.revoked_at is None and a.starts_on <= today and (a.ends_on is None or a.ends_on >= today)
    ]


class RoleBriefSerializer(serializers.Serializer):
    slug = serializers.CharField()
    name = serializers.CharField()
    kind = serializers.CharField()


class MemberListSerializer(serializers.ModelSerializer):
    roles = serializers.SerializerMethodField()
    age = serializers.IntegerField(read_only=True)
    is_minor = serializers.BooleanField(read_only=True)
    joined_year = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ["id", "last_name", "first_name", "full_name", "status", "is_diaspora", "city", "age", "is_minor", "joined_year", "roles"]

    def get_roles(self, user) -> list[dict]:
        # The implicit "membre" role says nothing in a list of members.
        roles = [r for r in _active_roles(user, self.context["today"]) if r.slug != "membre"]
        return RoleBriefSerializer(roles, many=True).data

    def get_joined_year(self, user) -> int:
        return user.joined_on.year


class MemberDetailSerializer(MemberListSerializer):
    phone = serializers.SerializerMethodField()
    parent = serializers.SerializerMethodField()
    restricted = serializers.SerializerMethodField()

    class Meta(MemberListSerializer.Meta):
        fields = MemberListSerializer.Meta.fields + ["phone", "joined_on", "birth_date", "parent", "restricted"]

    def _hide_minor_contacts(self, user):
        return user.is_minor and not self.context["viewer"].can("members.minor_contacts", "view")

    def get_phone(self, user) -> str | None:
        # A minor's own number is a minor's contact too.
        return None if self._hide_minor_contacts(user) else format_phone(user.phone)

    def get_parent(self, user) -> dict | None:
        if not user.is_minor or self._hide_minor_contacts(user) or not user.parent_phone:
            return None
        return {"name": user.parent_name, "relation": user.parent_relation, "phone": format_phone(user.parent_phone)}

    def get_restricted(self, user) -> list[str]:
        """What exists but this viewer may not see — the app says so and
        names who can, instead of silently leaving a gap (design:
        "Accès réservé")."""
        out = []
        if self._hide_minor_contacts(user):
            out.append("minor_contacts")
        if not self.context["viewer"].can("finances.cashbook", "view"):
            out.append("contributions")
        return out


class MemberCreateSerializer(serializers.Serializer):
    last_name = serializers.CharField(max_length=80)
    first_name = serializers.CharField(max_length=80)
    phone = PhoneField()
    birth_date = serializers.DateField(required=False, allow_null=True)
    joined_on = serializers.DateField(required=False)
    is_diaspora = serializers.BooleanField(default=False)
    city = serializers.CharField(max_length=80, required=False, allow_blank=True, default="")
    parent_name = serializers.CharField(max_length=120, required=False, allow_blank=True, default="")
    parent_relation = serializers.CharField(max_length=40, required=False, allow_blank=True, default="")
    parent_phone = PhoneField(required=False, allow_blank=True, default="")

    def validate_phone(self, value):
        if User.objects.filter(phone=value).exists():
            raise serializers.ValidationError("Ce numéro est déjà celui d’un membre.", code="phone_taken")
        return value

    def validate_birth_date(self, value):
        if value and value > date.today():
            raise serializers.ValidationError("La date de naissance est dans le futur.", code="birth_in_future")
        return value

    def validate(self, data):
        birth = data.get("birth_date")
        if birth:
            today = date.today()
            age = today.year - birth.year - ((today.month, today.day) < (birth.month, birth.day))
            if age < 18 and not data.get("parent_phone"):
                raise serializers.ValidationError(
                    {"parent_phone": serializers.ErrorDetail("Ce champ est obligatoire pour un mineur.", code="parent_required")}
                )
        return data


class BureauEntrySerializer(serializers.Serializer):
    member = MemberListSerializer()
    role = RoleBriefSerializer()
    ends_on = serializers.DateField(allow_null=True)

