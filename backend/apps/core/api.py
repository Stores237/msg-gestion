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
            # Wider group settings (owner, 2026-11-02).
            **{f: getattr(st, f) for f in SETTINGS_FOR_APP},
        })


SETTINGS_FOR_APP = ("currency", "dues_monthly", "dues_day", "max_leave_days", "report_hours", "remind_before_hours",
                    "event_minutes", "language", "contact_phone", "contact_email", "rules_text", "website")


def _group_or_none():
    """The group the app works in (or the only one); None when unclear."""
    from .groups import NoGroupContext, default_group_id

    try:
        return default_group_id()
    except NoGroupContext:
        return None


def _faq_json(e):
    return {"id": e.pk, "question": e.question, "answer": e.answer}


class FaqView(APIView):
    """GET Aide → Questions fréquentes: the platform's common questions and
    the current group's own (owner, 2026-11-02)."""

    def get(self, request):
        from .models import FaqEntry

        gid = _group_or_none()
        return Response({
            "common": [_faq_json(e) for e in FaqEntry.objects.filter(group__isnull=True)],
            "group": [_faq_json(e) for e in FaqEntry.objects.filter(group_id=gid)] if gid else [],
        })


class FaqSuggestionView(APIView):
    """GET my suggestions with their outcome; POST {question, answer} to
    propose a question to the platform team."""

    throttle_scope = "faq_suggest"

    def get_throttles(self):
        return super().get_throttles() if self.request.method == "POST" else []

    def get(self, request):
        from .models import FaqSuggestion

        rows = FaqSuggestion.objects.filter(author=request.user)[:50]
        return Response([{"id": s.pk, "question": s.question, "answer": s.answer, "status": s.status, "note": s.note,
                          "created_at": s.created_at} for s in rows])

    def post(self, request):
        from . import audit
        from .models import FaqSuggestion

        q = str(request.data.get("question", "")).strip()
        a = str(request.data.get("answer", "")).strip()
        if len(q) < 5:
            return Response({"detail": "Écrivez la question.", "code": "question_required"}, status=400)
        if len(q) > 200 or len(a) > 3000:
            return Response({"detail": "Texte trop long.", "code": "too_long"}, status=400)
        gid = _group_or_none()
        if gid is None:
            return Response({"detail": "Choisissez d’abord un groupe.", "code": "no_group"}, status=400)
        s = FaqSuggestion.objects.create(group_id=gid, author=request.user, question=q, answer=a)
        audit.record("Question proposée pour l’aide", actor=request.user, obj=s, request=request)
        return Response({"id": s.pk, "status": s.status}, status=201)


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


class _NetworkBase(APIView):
    """A group's network (owner, 2026-11-03). Everyone in the group sees
    where it stands; the président (group.profile) joins with a code,
    leaves, and, in an umbrella group, issues codes."""

    def _ctx(self, request):
        from .models import Settings

        return Settings.get().group, request.user.can("group.profile", "change")

    def _refuse(self, request, group, action, err):
        from . import audit

        audit.record(action, actor=request.user, obj=group, request=request, sensitive=True, refused=True,
                     detail={"raison": err.message})
        return Response({"detail": err.message, "code": err.code}, status=err.status)

    def _forbidden(self):
        return Response({"detail": "Réservé au président du groupe.", "code": "forbidden"}, status=403)


class NetworkView(_NetworkBase):
    def get(self, request):
        from .network import summary

        group, manage = self._ctx(request)
        return Response(summary(group, request, manage=manage))


class NetworkInvitationView(_NetworkBase):
    """GET ?code= — who invites (before accepting); POST — a new code
    (umbrella only); DELETE ?code= — cancel one."""

    throttle_scope = "network_code"

    def get_throttles(self):
        from .throttling import ClientIPScopedRateThrottle

        return [ClientIPScopedRateThrottle()] if self.request.method == "GET" else super().get_throttles()

    def get(self, request):
        from .identity import group_identity
        from .network import NetworkRule, find_invitation

        group, manage = self._ctx(request)
        if not manage:
            return self._forbidden()
        try:
            inv = find_invitation(request.query_params.get("code"), group)
        except NetworkRule as e:
            return self._refuse(request, group, "Code de rattachement refusé", e)
        u = inv.umbrella
        return Response({**group_identity(u, request), "level": u.level, "level_name": u.level_name,
                         "network": u.network.name, "parents": [g.name for g in u.ancestors()]})

    def post(self, request):
        from .network import NetworkRule, create_invitation

        group, manage = self._ctx(request)
        if not manage:
            return self._forbidden()
        try:
            inv = create_invitation(group, by=request.user, request=request)
        except NetworkRule as e:
            return self._refuse(request, group, "Invitation de rattachement refusée", e)
        return Response({"code": inv.pretty, "expires_at": inv.expires_at.isoformat()}, status=201)

    def delete(self, request):
        from .models import GroupInvitation
        from .network import NetworkRule, clean_code, revoke_invitation

        group, manage = self._ctx(request)
        if not manage:
            return self._forbidden()
        inv = GroupInvitation.objects.filter(umbrella=group, code=clean_code(request.query_params.get("code"))).first()
        if inv is None:
            return Response({"detail": "Invitation introuvable.", "code": "not_found"}, status=404)
        try:
            revoke_invitation(inv, by=request.user, request=request)
        except NetworkRule as e:
            return Response({"detail": e.message, "code": e.code}, status=e.status)
        return Response(status=204)


class NetworkJoinView(_NetworkBase):
    """POST {code} — the président accepts an umbrella's invitation."""

    throttle_scope = "network_code"

    def get_throttles(self):
        from .throttling import ClientIPScopedRateThrottle

        return [ClientIPScopedRateThrottle()]

    def post(self, request):
        from .network import NetworkRule, accept_invitation, summary

        group, manage = self._ctx(request)
        if not manage:
            return self._forbidden()
        try:
            accept_invitation(request.data.get("code"), group, by=request.user, request=request)
        except NetworkRule as e:
            return self._refuse(request, group, "Rattachement refusé", e)
        group.refresh_from_db()
        return Response(summary(group, request, manage=True))


class NetworkLeaveView(_NetworkBase):
    """POST {reason} — the président detaches the group from its umbrella."""

    def post(self, request):
        from .network import NetworkRule, detach, summary

        group, manage = self._ctx(request)
        if not manage:
            return self._forbidden()
        try:
            detach(group, by=request.user, reason=request.data.get("reason"), request=request)
        except NetworkRule as e:
            return self._refuse(request, group, "Détachement refusé", e)
        group.refresh_from_db()
        return Response(summary(group, request, manage=True))


class NetworkSharingView(_NetworkBase):
    """GET what the group shares with the groups above it; PUT
    {"members": "summary", …} (the président)."""

    def get(self, request):
        from .sharing import KINDS, settings_of

        group, manage = self._ctx(request)
        return Response({"values": settings_of(group), "can_manage": manage,
                         "options": {k: ["none", *levels] for k, (levels, _) in KINDS.items()}})

    def put(self, request):
        from .sharing import KINDS, SharingRule, save_settings

        group, manage = self._ctx(request)
        if not manage:
            return self._forbidden()
        try:
            values = save_settings(group, request.data if isinstance(request.data, dict) else {}, by=request.user,
                                   request=request)
        except SharingRule as e:
            return Response({"detail": e.message, "code": e.code}, status=e.status)
        return Response({"values": values, "can_manage": True,
                         "options": {k: ["none", *levels] for k, (levels, _) in KINDS.items()}})


class NetworkGroupView(_NetworkBase):
    """GET a group below the current one: what it shares, as far as the
    viewer's role in the current group lets them read it."""

    def get(self, request, pk):
        from .identity import group_identity
        from .sharing import shared_view

        group, _ = self._ctx(request)
        target = next((g for g in group.descendants() if g.pk == pk), None)
        if target is None:
            return Response({"detail": "Ce groupe n’est pas rattaché au vôtre.", "code": "not_below"}, status=404)
        return Response({**group_identity(target, request), "level_name": target.level_name,
                         "parent": target.parent.name if target.parent_id else None,
                         "shared": shared_view(target, request.user)})
