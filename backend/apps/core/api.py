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
            "name": st.name, "parish": st.parish, "motto": st.motto, "color": st.color, "color2": st.color2,
            "fees": {"inscription": st.fee_registration, "medaille": st.fee_medal, "maladie": st.fee_illness, "deces": st.fee_death},
            "quick_amounts": st.quick_amounts(), "installments": st.installments,
            # The group's own lists (back-office → Paramètres).
            "activity_types": [{"slug": a.slug, "name": a.name, "needs_lineup": a.needs_lineup,
                                "has_scope": a.has_scope, "needs_chef": a.needs_chef}
                               for a in ActivityType.objects.filter(is_archived=False)],
            "dress_codes": [{"slug": d.slug, "name": d.name, "description": d.description}
                            for d in DressCode.objects.filter(is_archived=False)],
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
            # Lines waiting for this person's agreement (owner, 2026-10-30):
            # not the ones they entered or last changed.
            pending = Entry.objects.filter(status=Entry.Status.PENDING)
            out["to_validate"] = (pending.exclude(edited_by__isnull=True, created_by=u).exclude(edited_by=u).count()
                                  if u.can("finances.cashbook", "validate") else 0)
            out["to_confirm"] = Entry.objects.filter(status=Entry.Status.TO_CONFIRM).count()
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


# --- The group's identity (owner, 2026-11-02): like a Slack workspace, each
# group shows its own name and logo; its président changes them in the app,
# the super admin in the back-office. ---

LOGO_MAX_BYTES = 5 * 1024 * 1024
LOGO_SIDE = 512


def square_logo(upload):
    """The upload as a 512 px square PNG (centre crop); None if unreadable."""
    import io

    from django.core.files.base import ContentFile
    from PIL import Image, ImageOps, UnidentifiedImageError

    try:
        with Image.open(upload) as im:
            im = ImageOps.exif_transpose(im).convert("RGBA")
            im = ImageOps.fit(im, (LOGO_SIDE, LOGO_SIDE), method=Image.Resampling.LANCZOS)
            buf = io.BytesIO()
            im.save(buf, "PNG", optimize=True)
    except (UnidentifiedImageError, OSError):
        return None
    return ContentFile(buf.getvalue())


def save_logo(group, upload, *, by, request):
    """None when saved, else (message, code). Shared with the back-office."""
    import uuid

    from apps.announcements.files import sniff

    from . import audit

    if upload is None:
        return "Aucune image.", "no_file"
    if upload.size > LOGO_MAX_BYTES:
        return "Image trop lourde (5 Mo maximum).", "file_too_large"
    if sniff(upload) not in ("image/jpeg", "image/png"):
        return "JPEG ou PNG uniquement.", "file_type"
    square = square_logo(upload)
    if square is None:
        return "Image illisible.", "file_type"
    if group.logo:
        group.logo.delete(save=False)
    group.logo.save(f"{group.slug}-{uuid.uuid4().hex[:8]}.png", square, save=True)
    audit.record("Logo du groupe modifié", actor=by, obj=group, request=request)
    return None


class GroupProfileView(APIView):
    """GET the current group's identity; PATCH {name, short_name} (the
    group.profile right: the président)."""

    def get(self, request):
        from .identity import group_identity
        from .models import Settings

        return Response(group_identity(Settings.get().group, request))

    def patch(self, request):
        from . import audit
        from .identity import group_identity
        from .models import Settings

        if not request.user.can("group.profile", "change"):
            return Response({"detail": "Réservé au président du groupe.", "code": "forbidden"}, status=403)
        group = Settings.get().group
        changed = {}
        if "name" in request.data:
            name = str(request.data["name"]).strip()[:120]
            if not name:
                return Response({"detail": "Le nom du groupe est obligatoire.", "code": "name_required"}, status=400)
            if name != group.name:
                changed["nom"] = {"avant": group.name, "apres": name}
                group.name = name
        if "short_name" in request.data:
            short = "".join(str(request.data["short_name"]).split())[:8].upper()
            if short != group.short_name:
                changed["sigle"] = {"avant": group.short_name, "apres": short}
                group.short_name = short
        if changed:
            group.save(update_fields=["name", "short_name"])
            audit.record("Nom du groupe modifié", actor=request.user, obj=group, request=request, detail=changed)
        return Response(group_identity(group, request))


class GroupLogoView(APIView):
    """POST multipart `logo` (JPEG/PNG ≤ 5 MB, cropped to a square);
    DELETE goes back to the initials."""

    def _group(self, request):
        from .models import Settings

        if not request.user.can("group.profile", "change"):
            return None
        return Settings.get().group

    def post(self, request):
        from .identity import group_identity

        group = self._group(request)
        if group is None:
            return Response({"detail": "Réservé au président du groupe.", "code": "forbidden"}, status=403)
        problem = save_logo(group, request.FILES.get("logo"), by=request.user, request=request)
        if problem:
            return Response({"detail": problem[0], "code": problem[1]}, status=400)
        return Response(group_identity(group, request))

    def delete(self, request):
        from . import audit
        from .identity import group_identity

        group = self._group(request)
        if group is None:
            return Response({"detail": "Réservé au président du groupe.", "code": "forbidden"}, status=403)
        if group.logo:
            group.logo.delete(save=True)
            audit.record("Logo du groupe retiré", actor=request.user, obj=group, request=request)
        return Response(group_identity(group, request))
