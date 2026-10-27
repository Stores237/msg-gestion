from datetime import datetime, time

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


class SettingsView(APIView):
    """What the app needs from Paramètres: official amounts, defaults."""

    def get(self, request):
        from apps.events.models import ActivityType, DressCode

        from .models import Settings

        st = Settings.get()
        return Response({
            "name": st.name, "parish": st.parish, "motto": st.motto, "color": st.color,
            "fees": {"inscription": st.fee_registration, "medaille": st.fee_medal, "maladie": st.fee_illness, "deces": st.fee_death},
            "quick_amounts": st.quick_amounts(), "installments": st.installments,
            # The group's own lists (back-office → Paramètres).
            "activity_types": [{"slug": a.slug, "name": a.name, "needs_lineup": a.needs_lineup,
                                "has_scope": a.has_scope, "needs_chef": a.needs_chef}
                               for a in ActivityType.objects.filter(is_archived=False)],
            "dress_codes": [{"slug": d.slug, "name": d.name} for d in DressCode.objects.filter(is_archived=False)],
        })


class PlatformView(APIView):
    """GET: the partner's contacts and texts for Aide / À propos."""

    def get(self, request):
        from .models import PlatformSettings

        p = PlatformSettings.get()
        return Response({f: getattr(p, f) for f in ("support_phone", "support_whatsapp", "support_email", "website",
                                                     "privacy_text", "terms_text")})


class BureauHomeView(APIView):
    """Accueil for the bureau (design: "Accueil · trésorière" → À suivre):
    only the blocks the viewer's roles allow."""

    def get(self, request):
        from apps.accounts.models import User
        from apps.finances.models import Collection, Entry
        from apps.finances.services import collection_rows
        from apps.planning.models import Service
        from apps.planning.services import week_bounds

        u = request.user
        out = {}
        if u.can("members.profile", "view"):
            out["members_active"] = User.objects.members().filter(gstatus=User.Status.ACTIVE, is_active=True).count()
        if u.can("finances.cashbook", "view"):
            out["to_validate"] = Entry.objects.filter(status=Entry.Status.PENDING).count()
        if u.can("finances.solidarity", "view"):
            items = []
            for c in Collection.objects.filter(closed_at__isnull=True)[:3]:
                rows = collection_rows(c)
                items.append({"id": c.pk, "title": c.title, "members": len(rows),
                              "paid_full": sum(1 for r in rows if r["paid"] >= c.amount_per_member)})
            out["collections"] = items
        if u.can("calendar.planning", "view"):
            start, end = week_bounds(timezone.localdate())
            lo = timezone.make_aware(datetime.combine(start, time.min))
            gaps = []
            for s in Service.objects.filter(event__starts_at__gte=lo, event__starts_at__lt=lo + (end - start)).select_related("event"):
                filled = s.assignments.exclude(status__in=["repl", "absent"]).count()
                if filled < s.size:
                    gaps.append({"title": s.event.title, "starts_at": s.event.starts_at, "missing": s.size - filled})
            out["unfilled"] = gaps
        return Response(out)
