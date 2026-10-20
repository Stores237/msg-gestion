from django.utils import timezone
from rest_framework import serializers
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    unread = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = ["id", "kind", "title", "body", "target", "created_at", "unread"]

    def get_unread(self, n) -> bool:
        return n.read_at is None


class NotificationListView(APIView):
    """GET my notifications (latest 100) and the unread count."""

    def get(self, request):
        qs = Notification.objects.filter(user=request.user)
        return Response({"unread": qs.filter(read_at__isnull=True).count(), "results": NotificationSerializer(qs[:100], many=True).data})


class NotificationReadView(APIView):
    """POST {"ids": [...]} or {} for all."""

    def post(self, request):
        qs = Notification.objects.filter(user=request.user, read_at__isnull=True)
        ids = request.data.get("ids")
        if ids:
            qs = qs.filter(pk__in=ids)
        n = qs.update(read_at=timezone.now())
        return Response({"marked": n})
