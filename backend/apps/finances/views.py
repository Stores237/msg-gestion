from django.db.models import Max
from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import extend_schema
from rest_framework import serializers, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import User
from apps.accounts.permissions import require
from apps.core import audit

from . import services
from .models import Collection, Due, Entry

# Every finance error carries a code the app translates.


def _rule_error(e):
    return Response({"detail": str(e), "code": e.code}, status=400)


class MemberField(serializers.PrimaryKeyRelatedField):
    """A member of the current group (looked up per request, not at import)."""

    def get_queryset(self):
        return User.objects.members()


class EntrySerializer(serializers.ModelSerializer):
    member = MemberField(required=False, allow_null=True)
    member_name = serializers.CharField(source="member.full_name", default=None, read_only=True)
    created_by_name = serializers.CharField(source="created_by.short_name", read_only=True)
    validated_by_name = serializers.CharField(source="validated_by.short_name", default=None, read_only=True)
    edited_by_name = serializers.CharField(source="edited_by.short_name", default=None, read_only=True)
    confirmed_by_name = serializers.CharField(source="confirmed_by.short_name", default=None, read_only=True)
    # For the viewer (owner, 2026-10-30): may I approve it, may I correct
    # it, or does it wait for the other one?
    can_approve = serializers.SerializerMethodField()
    can_edit = serializers.SerializerMethodField()
    awaiting_other = serializers.SerializerMethodField()

    class Meta:
        model = Entry
        fields = ["id", "direction", "amount", "category", "label", "member", "member_name", "date", "status", "client_uuid",
                  "created_by_name", "created_at", "validated_by_name", "validated_at", "collection", "due",
                  "edited_by_name", "edited_at", "confirmed_by_name", "confirmed_at",
                  "can_approve", "can_edit", "awaiting_other"]
        read_only_fields = ["status", "created_at", "validated_at", "collection", "due", "edited_at", "confirmed_at"]
        extra_kwargs = {"client_uuid": {"required": False, "allow_null": True, "validators": []}}


    def _viewer(self):
        """(user, may approve at all), worked out once per response."""
        if "_viewer" not in self.context:
            u = getattr(self.context.get("request"), "user", None)
            ok = bool(u and u.is_authenticated)
            self.context["_viewer"] = (u if ok else None, ok and u.can("finances.cashbook", "validate"))
        return self.context["_viewer"]

    def get_can_approve(self, e) -> bool:
        u, approves = self._viewer()
        return approves and e.status == Entry.Status.PENDING and services.agreed_by_id(e) != u.pk

    def get_can_edit(self, e) -> bool:
        _, approves = self._viewer()
        return approves and e.status == Entry.Status.PENDING

    def get_awaiting_other(self, e) -> bool:
        u, _ = self._viewer()
        return bool(u) and e.status == Entry.Status.PENDING and services.agreed_by_id(e) == u.pk


class NewEntrySerializer(EntrySerializer):
    """A new line; `members` (several ticked members) makes one line each
    with the same amount (owner, 2026-10-30)."""

    members = serializers.ListField(child=MemberField(), required=False, allow_empty=False, max_length=500)

    class Meta(EntrySerializer.Meta):
        fields = [*EntrySerializer.Meta.fields, "members"]


class EntryListView(APIView):
    """GET the cash book (?status=pending|validated); POST a new line."""

    def get_permissions(self):
        return [require("finances.cashbook", "create" if self.request.method == "POST" else "view")()]

    @extend_schema(responses=EntrySerializer(many=True))
    def get(self, request):
        qs = Entry.objects.select_related("member", "created_by", "validated_by", "edited_by", "confirmed_by")
        st = request.query_params.get("status")
        if st in Entry.Status.values:
            qs = qs.filter(status=st)
        return Response(EntrySerializer(qs[:200], many=True, context={"request": request}).data)

    @extend_schema(request=NewEntrySerializer, responses=EntrySerializer)
    def post(self, request):
        s = NewEntrySerializer(data=request.data)
        s.is_valid(raise_exception=True)
        data = dict(s.validated_data)
        members = data.pop("members", None)
        if data.get("direction") == Entry.Direction.OUT:
            data["category"] = Entry.Category.EXPENSE
        try:
            services.check_line(data.get("direction"), data.get("category"), data.get("label"),
                                (members or [None])[0] if members else data.get("member"))
        except services.FinanceRule as e:
            return _rule_error(e)
        if not members:
            entry, created = services.record_entry(by=request.user, request=request, **data)
            if created:
                services.tell_approvers([entry], by=request.user)
            return Response(EntrySerializer(entry, context={"request": request}).data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)
        entries = services.record_entries(members, by=request.user, request=request, **data)
        services.tell_approvers(entries, by=request.user)
        return Response({"entries": EntrySerializer(entries, many=True, context={"request": request}).data, "count": len(entries)},
                        status=status.HTTP_201_CREATED)


class EntryDetailView(APIView):
    """DELETE (whoever may delete) or PATCH: the trésorier corrects a line
    before validating it — part of his "validate" right, since the two-hands
    rule never gives him "change" (owner, 2026-10-30)."""

    def get_permissions(self):
        action = {"DELETE": "delete", "PATCH": "validate"}.get(self.request.method, "view")
        return [require("finances.cashbook", action)()]

    @extend_schema(request=EntrySerializer, responses=EntrySerializer)
    def patch(self, request, pk):
        entry = get_object_or_404(Entry.objects.select_related("member", "created_by"), pk=pk)
        s = EntrySerializer(entry, data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        changes = {k: v for k, v in s.validated_data.items() if k in services.EDITABLE}
        try:
            services.edit_entry(entry, changes, by=request.user, request=request)
        except services.FinanceRule as e:
            return _rule_error(e)
        return Response(EntrySerializer(entry, context={"request": request}).data)

    def delete(self, request, pk):
        entry = get_object_or_404(Entry, pk=pk)
        if entry.status == Entry.Status.VALIDATED:
            return Response({"detail": "Une opération validée ne peut plus être modifiée.", "code": "validated_locked"}, status=400)
        if entry.created_by_id != request.user.pk and not request.user.is_super_admin:
            # Owner, 2026-10-30: both enter, so each removes only their own
            # line; the other one corrects it instead (audited).
            audit.record("Refus · suppression de la saisie d’un autre", actor=request.user, obj=entry, request=request,
                         refused=True)
            return Response({"detail": "Seul celui qui a saisi l’opération peut la supprimer ; corrigez-la plutôt.",
                             "code": "not_your_entry"}, status=403)
        audit.record("Opération supprimée", actor=request.user, obj=entry, request=request, detail={"montant": entry.amount})
        entry.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class EntryValidateView(APIView):
    """The trésorier validates a line the commissaire entered (design: "Valider cette
    opération ?"). Name and time are recorded; never one's own entry."""

    permission_classes = [require("finances.cashbook", "validate")]

    def post(self, request, pk):
        entry = get_object_or_404(Entry, pk=pk)
        try:
            services.validate_entry(entry, by=request.user, request=request)
        except services.FinanceRule as e:
            return _rule_error(e)
        return Response(EntrySerializer(entry, context={"request": request}).data)


class EntryValidateManyView(APIView):
    """POST {"ids": [...]}: approve several lines at once (long press in the
    app). Each follows the per-line rule; the others come back in
    `skipped` with the reason."""

    permission_classes = [require("finances.cashbook", "validate")]

    def post(self, request):
        ids = request.data.get("ids")
        if not isinstance(ids, list) or not ids or len(ids) > 500 or not all(isinstance(i, int) for i in ids):
            return Response({"detail": "Choisissez les opérations à valider.", "code": "ids_required"}, status=400)
        done, skipped = services.validate_entries(ids, by=request.user, request=request)
        return Response({"validated": done, "skipped": skipped})


class EntryConfirmView(APIView):
    """POST {accept: true} → the commissaire finalises a line the trésorier
    edited and validated; {accept: false, reason} → back to the trésorier."""

    permission_classes = [require("finances.cashbook", "create")]

    def post(self, request, pk):
        entry = get_object_or_404(Entry, pk=pk)
        try:
            if request.data.get("accept"):
                services.confirm_entry(entry, by=request.user, request=request)
            else:
                services.send_back(entry, by=request.user, reason=request.data.get("reason", ""), request=request)
        except services.FinanceRule as e:
            return _rule_error(e)
        return Response(EntrySerializer(entry, context={"request": request}).data)


class SummaryView(APIView):
    permission_classes = [require("finances.cashbook", "view")]

    @extend_schema(responses=OpenApiTypes.OBJECT)
    def get(self, request):
        validated = Entry.objects.filter(status=Entry.Status.VALIDATED)
        return Response({
            "balance": services.balance(validated),
            "balance_with_pending": services.balance(Entry.objects.all()),
            "pending": Entry.objects.filter(status=Entry.Status.PENDING).count(),
            "to_confirm": Entry.objects.filter(status=Entry.Status.TO_CONFIRM).count(),
            "validated_until": validated.aggregate(d=Max("date"))["d"],
        })


# --- Solidarity ----------------------------------------------------------------


class CollectionSerializer(serializers.ModelSerializer):
    tranches = serializers.SerializerMethodField()
    paid_full = serializers.SerializerMethodField()
    members = serializers.SerializerMethodField()
    collected = serializers.SerializerMethodField()

    class Meta:
        model = Collection
        fields = ["id", "kind", "title", "amount_per_member", "installments", "opened_on", "closed_at", "tranches", "paid_full", "members", "collected"]
        read_only_fields = ["opened_on", "closed_at"]

    def get_tranches(self, c) -> list[int]:
        return c.tranches()

    def _rows(self, c):
        cache = self.context.setdefault("_rows", {})
        if c.pk not in cache:
            cache[c.pk] = services.collection_rows(c)
        return cache[c.pk]

    def get_paid_full(self, c) -> int:
        return sum(1 for r in self._rows(c) if r["paid"] >= c.amount_per_member)

    def get_members(self, c) -> int:
        return len(self._rows(c))

    def get_collected(self, c) -> int:
        return sum(r["paid"] for r in self._rows(c))


class CollectionListView(APIView):
    def get_permissions(self):
        return [require("finances.solidarity", "create" if self.request.method == "POST" else "view")()]

    @extend_schema(responses=CollectionSerializer(many=True))
    def get(self, request):
        return Response(CollectionSerializer(Collection.objects.all()[:50], many=True).data)

    @extend_schema(request=CollectionSerializer, responses=CollectionSerializer)
    def post(self, request):
        s = CollectionSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        c = services.open_collection(by=request.user, request=request, **s.validated_data)
        return Response(CollectionSerializer(c).data, status=status.HTTP_201_CREATED)


class CollectionDetailView(APIView):
    permission_classes = [require("finances.solidarity", "view")]

    def get(self, request, pk):
        c = get_object_or_404(Collection, pk=pk)
        body = dict(CollectionSerializer(c).data)
        body["rows"] = services.collection_rows(c)
        return Response(body)


class PaymentSerializer(serializers.Serializer):
    member = serializers.IntegerField()
    amount = serializers.IntegerField(min_value=1)
    client_uuid = serializers.UUIDField(required=False, allow_null=True)


class CollectionPayView(APIView):
    """Record several members' payments in one go (design: "Cocher puis
    enregistrer en une fois")."""

    permission_classes = [require("finances.solidarity", "create")]

    @extend_schema(request=PaymentSerializer(many=True))
    def post(self, request, pk):
        c = get_object_or_404(Collection, pk=pk)
        s = PaymentSerializer(data=request.data.get("payments", []), many=True)
        s.is_valid(raise_exception=True)
        try:
            created = services.pay_collection(c, s.validated_data, by=request.user, request=request)
        except services.FinanceRule as e:
            return _rule_error(e)
        return Response({"recorded": len(created), "rows": services.collection_rows(c)})


class CollectionCloseView(APIView):
    permission_classes = [require("finances.solidarity", "change")]

    def post(self, request, pk):
        c = get_object_or_404(Collection, pk=pk)
        if c.closed_at:
            return Response({"detail": "Déjà clôturée.", "code": "collection_closed"}, status=400)
        c.closed_at = timezone.now()
        c.save(update_fields=["closed_at"])
        unpaid = sum(1 for r in services.collection_rows(c) if r["paid"] < c.amount_per_member)
        audit.record("Collecte clôturée", actor=request.user, obj=c, request=request, detail={"non_payes": unpaid})
        return Response(CollectionSerializer(c).data)


# --- Fines and "my contributions" ----------------------------------------------------


class FineSerializer(serializers.Serializer):
    member = MemberField()
    amount = serializers.IntegerField(min_value=1)
    reason = serializers.CharField(max_length=160)


class FineView(APIView):
    permission_classes = [require("finances.cashbook", "create")]

    @extend_schema(request=FineSerializer)
    def post(self, request):
        s = FineSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        due = Due.objects.create(member=s.validated_data["member"], kind=Due.Kind.FINE, label=s.validated_data["reason"],
                                 amount=s.validated_data["amount"], created_by=request.user)
        audit.record("Amende enregistrée", actor=request.user, obj=due.member, request=request, detail={"montant": due.amount, "motif": due.label})
        return Response({"id": due.id}, status=status.HTTP_201_CREATED)


class DuePayView(APIView):
    """The treasurer records a payment towards a fine or a share."""

    permission_classes = [require("finances.cashbook", "create")]

    def post(self, request, pk):
        due = get_object_or_404(Due, pk=pk, cancelled=False)
        amount = int(request.data.get("amount") or (due.amount - due.paid()))
        if amount <= 0:
            return Response({"detail": "Rien à payer.", "code": "nothing_due"}, status=400)
        category = {Due.Kind.FINE: Entry.Category.FINE, Due.Kind.REGISTRATION: Entry.Category.REGISTRATION}.get(due.kind, Entry.Category.SOLIDARITY)
        entry, _ = services.record_entry(by=request.user, request=request, direction=Entry.Direction.IN, amount=amount, category=category,
                                         label=due.label, member=due.member, due=due, collection=due.collection,
                                         date=timezone.localdate(), client_uuid=request.data.get("client_uuid"))
        return Response(EntrySerializer(entry, context={"request": request}).data, status=status.HTTP_201_CREATED)


class MineView(APIView):
    """What I owe and what I paid — every member, no finance role needed
    (design: Accueil → "Mes contributions")."""

    def get(self, request):
        dues = []
        for d in Due.objects.filter(member=request.user, cancelled=False).select_related("collection"):
            paid = d.paid()
            if d.collection and not d.collection.is_open and paid >= d.amount:
                continue
            dues.append({"id": d.id, "kind": d.kind, "label": d.label, "amount": d.amount, "paid": paid,
                         "remaining": max(d.amount - paid, 0), "open": d.collection.is_open if d.collection else True})
        dues.sort(key=lambda d: (d["remaining"] == 0, d["label"]))
        return Response({"dues": dues, "to_pay": sum(d["remaining"] for d in dues)})


# --- Quarterly report -------------------------------------------------------------------


def _year_quarter(request):
    today = timezone.localdate()
    try:
        year = int(request.query_params.get("year") or request.data.get("year") or today.year)
        quarter = int(request.query_params.get("quarter") or request.data.get("quarter") or (today.month - 1) // 3 + 1)
    except (TypeError, ValueError):
        return None
    return (year, quarter) if 1 <= quarter <= 4 else None


class ReportView(APIView):
    permission_classes = [require("finances.report", "view")]

    def get(self, request):
        yq = _year_quarter(request)
        if yq is None:
            return Response({"detail": "Trimestre invalide.", "code": "bad_quarter"}, status=400)
        return Response(services.report(*yq))


class ReportValidateView(APIView):
    permission_classes = [require("finances.report", "validate")]

    def post(self, request):
        yq = _year_quarter(request)
        if yq is None:
            return Response({"detail": "Trimestre invalide.", "code": "bad_quarter"}, status=400)
        try:
            services.validate_report(*yq, by=request.user, request=request)
        except services.FinanceRule as e:
            return _rule_error(e)
        return Response(services.report(*yq))


def _pdf_response(request, url):
    return Response({"url": request.build_absolute_uri(url) if url.startswith("/") else url})


class ReportPdfView(APIView):
    permission_classes = [require("finances.report", "export")]

    def get(self, request):
        from .pdf import publish, report_pdf

        yq = _year_quarter(request)
        if yq is None:
            return Response({"detail": "Trimestre invalide.", "code": "bad_quarter"}, status=400)
        audit.record("Export PDF du rapport", actor=request.user, request=request, detail={"annee": yq[0], "trimestre": yq[1]})
        return _pdf_response(request, publish(report_pdf(services.report(*yq)), f"rapport-T{yq[1]}-{yq[0]}"))


class CashbookPdfView(APIView):
    permission_classes = [require("finances.cashbook", "export")]

    def get(self, request):
        from .pdf import cashbook_pdf, publish

        entries = list(Entry.objects.select_related("member", "created_by", "validated_by")[:1000])
        audit.record("Export PDF du livre de caisse", actor=request.user, request=request, detail={"lignes": len(entries)})
        return _pdf_response(request, publish(cashbook_pdf(entries), "livre-de-caisse"))


# --- Members' balance statement ("bilan") ---------------------------------------------


class StatementView(APIView):
    """Bilan général: every member's dues and payments."""

    permission_classes = [require("finances.cashbook", "view")]

    @extend_schema(responses=OpenApiTypes.OBJECT)
    def get(self, request):
        rows = services.statement_rows()
        return Response({"rows": rows, "totals": services.statement_totals(rows)})


class MemberStatementView(APIView):
    permission_classes = [require("finances.cashbook", "view")]

    @extend_schema(responses=OpenApiTypes.OBJECT)
    def get(self, request, pk):
        return Response(services.member_statement(get_object_or_404(User.objects.members(), pk=pk)))


class StatementPdfView(APIView):
    permission_classes = [require("finances.cashbook", "export")]

    def get(self, request):
        from .pdf import publish, statement_pdf

        rows = services.statement_rows()
        audit.record("Export PDF du bilan général", actor=request.user, request=request, detail={"membres": len(rows)})
        return _pdf_response(request, publish(statement_pdf(rows, services.statement_totals(rows)), "bilan-general"))


class MemberStatementPdfView(APIView):
    permission_classes = [require("finances.cashbook", "export")]

    def get(self, request, pk):
        from .pdf import member_statement_pdf, publish

        member = get_object_or_404(User.objects.members(), pk=pk)
        audit.record("Export PDF du bilan individuel", actor=request.user, obj=member, request=request)
        return _pdf_response(request, publish(member_statement_pdf(services.member_statement(member)), "bilan-membre"))
