from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import extend_schema_field
from rest_framework import serializers

from .phone import InvalidPhone, normalize_phone


class PhoneField(serializers.CharField):
    def to_internal_value(self, data):
        try:
            return normalize_phone(super().to_internal_value(data))
        except InvalidPhone as exc:
            raise serializers.ValidationError(str(exc)) from exc


class PhoneLookupSerializer(serializers.Serializer):
    phone = PhoneField()


class PinLoginSerializer(serializers.Serializer):
    phone = PhoneField()
    pin = serializers.RegexField(r"^\d{4}$", error_messages={"invalid": "Le code PIN compte 4 chiffres."})


class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField()


class AssignmentSerializer(serializers.Serializer):
    slug = serializers.CharField(source="role.slug")
    name = serializers.CharField(source="role.name")
    kind = serializers.CharField(source="role.kind")
    starts_on = serializers.DateField()
    ends_on = serializers.DateField()


class MeSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    phone = serializers.CharField()
    first_name = serializers.CharField()
    last_name = serializers.CharField()
    full_name = serializers.CharField()
    status = serializers.CharField()
    is_diaspora = serializers.BooleanField()
    age = serializers.IntegerField(allow_null=True)
    pin_must_change = serializers.BooleanField()
    roles = serializers.SerializerMethodField()
    permissions = serializers.SerializerMethodField()
    tabs = serializers.SerializerMethodField()

    @extend_schema_field(AssignmentSerializer(many=True))
    def get_roles(self, user):
        return AssignmentSerializer(user.active_assignments(), many=True).data

    @extend_schema_field(OpenApiTypes.OBJECT)
    def get_permissions(self, user) -> dict:
        out = {}
        for res, act in sorted(user.permission_set()):
            out.setdefault(res, []).append(act)
        return out

    @extend_schema_field(serializers.ListField(child=serializers.CharField()))
    def get_tabs(self, user):
        return user.tabs()
