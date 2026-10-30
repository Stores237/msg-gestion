"""Expense requests over the API (owner, 2026-10-30); rules in expenses.py."""

from django.shortcuts import get_object_or_404
from rest_framework import serializers, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import User
from apps.announcements.files import MAX_BYTES, sniff

from . import expenses
from .models import ExpenseDomain, ExpenseMessage, ExpenseRequest
from .services import FinanceRule


def _rule(e):
    return Response({"detail": str(e), "code": e.code}, status=400)


def _file_url(request, f):
    if not f:
        return None
    url = f.url  # signed and short-lived on S3/Supabase
    return request.build_absolute_uri(url) if url.startswith("/") else url


class MessageSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source="author.short_name", default=None, read_only=True)
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = ExpenseMessage
        fields = ["id", "kind", "body", "author_name", "file_name", "content_type", "file_url", "created_at"]

    def get_file_url(self, m) -> str | None:
        return _file_url(self.context["request"], m.file)


class RequestSerializer(serializers.ModelSerializer):
    requester_name = serializers.CharField(source="requester.short_name", read_only=True)
    domain_name = serializers.CharField(source="domain.name", read_only=True)
    lead_by_name = serializers.CharField(source="lead_by.short_name", default=None, read_only=True)
    audit_by_name = serializers.CharField(source="audit_by.short_name", default=None, read_only=True)
    paid_by_name = serializers.CharField(source="paid_by.short_name", default=None, read_only=True)
    tagged_names = serializers.SerializerMethodField()
    actions = serializers.SerializerMethodField()
    replaced_by = serializers.SerializerMethodField()

    class Meta:
        model = ExpenseRequest
        fields = ["id", "title", "description", "amount", "domain", "domain_name", "status", "requester_name",
                  "tagged_names", "lead_by_name", "lead_at", "audit_by_name", "audit_at", "paid_by_name", "paid_at",
                  "paid_amount", "entry", "close_reason", "closed_at", "replaces", "replaced_by", "created_at", "actions"]

    def get_tagged_names(self, r) -> list[str]:
        return [u.short_name for u in r.tagged.all()]

    def get_actions(self, r) -> list[str]:
        return expenses.actions(r, self.context["request"].user)

    def get_replaced_by(self, r) -> int | None:
        return getattr(getattr(r, "replaced_by", None), "pk", None)


class DetailSerializer(RequestSerializer):
    messages = MessageSerializer(many=True, read_only=True)

    class Meta(RequestSerializer.Meta):
        fields = [*RequestSerializer.Meta.fields, "messages"]


class NewRequestSerializer(serializers.Serializer):
    domain = serializers.PrimaryKeyRelatedField(queryset=ExpenseDomain.objects.none())
    title = serializers.CharField(max_length=140)
    description = serializers.CharField(max_length=1000, required=False, allow_blank=True)
    amount = serializers.IntegerField(min_value=1, max_value=100_000_000)
    tagged = serializers.ListField(child=serializers.IntegerField(), required=False, max_length=10)
    replaces = serializers.IntegerField(required=False, allow_null=True)

    def __init__(self, *a, **kw):
        super().__init__(*a, **kw)
        self.fields["domain"].queryset = ExpenseDomain.objects.filter(is_archived=False)


class DomainListView(APIView):
    def get(self, request):
        return Response([{"id": d.pk, "name": d.name, "lead_role": d.lead_role.name if d.lead_role else None}
                         for d in expenses.active_domains()])


class RequestListView(APIView):
    """GET ?box=todo (waiting for me) | mine | all; POST a new request.
    Every member of the group may ask."""

    def get(self, request):
        box = request.query_params.get("box", "todo")
        qs = expenses.visible_to(request.user).prefetch_related("tagged")
        if box == "mine":
            qs = qs.filter(requester=request.user)
        rows = list(qs[:200])
        if box == "todo":
            rows = [r for r in rows if set(expenses.actions(r, request.user)) & {"decide", "audit", "pay"}]
        return Response(RequestSerializer(rows, many=True, context={"request": request}).data)

    def post(self, request):
        s = NewRequestSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        d = s.validated_data
        tagged = list(User.objects.members().filter(pk__in=d.get("tagged") or [], is_active=True))
        replaces = None
        if d.get("replaces"):
            replaces = ExpenseRequest.objects.filter(pk=d["replaces"]).first()
            if replaces is None:
                return Response({"detail": "Demande introuvable.", "code": "bad_replaces"}, status=400)
        try:
            req = expenses.submit(by=request.user, domain=d["domain"], title=d["title"], amount=d["amount"],
                                  description=d.get("description", ""), tagged=tagged, replaces=replaces, request=request)
        except FinanceRule as e:
            return _rule(e)
        return Response(DetailSerializer(req, context={"request": request}).data, status=status.HTTP_201_CREATED)


def _get(request, pk):
    req = get_object_or_404(ExpenseRequest.objects.select_related("domain", "requester"), pk=pk)
    if not expenses.can_see(req, request.user):
        return None
    return req


NOT_YOURS = Response({"detail": "Cette demande ne vous concerne pas.", "code": "not_involved"}, status=404)


class RequestDetailView(APIView):
    def get(self, request, pk):
        req = _get(request, pk)
        if req is None:
            return NOT_YOURS
        return Response(DetailSerializer(req, context={"request": request}).data)


class RequestStepView(APIView):
    """POST decide | review {approve, note}; cancel {reason}."""

    step = None

    def post(self, request, pk):
        req = _get(request, pk)
        if req is None:
            return NOT_YOURS
        approve, note = bool(request.data.get("approve")), str(request.data.get("note") or request.data.get("reason") or "")
        try:
            if self.step == "decide":
                expenses.decide(req, by=request.user, approve=approve, note=note, request=request)
            elif self.step == "review":
                expenses.review(req, by=request.user, approve=approve, note=note, request=request)
            else:
                expenses.cancel(req, by=request.user, reason=note, request=request)
        except FinanceRule as e:
            return _rule(e)
        return Response(DetailSerializer(req, context={"request": request}).data)


def _upload(request, *, required):
    """(file, content type) or a refusal Response."""
    f = request.FILES.get("file")
    if f is None:
        if required:
            return None, Response({"detail": "Joignez la capture de la transaction.", "code": "proof_required"}, status=400)
        return None, None
    if f.size > MAX_BYTES:
        return None, Response({"detail": "Fichier trop lourd (10 Mo maximum).", "code": "file_too_large"}, status=400)
    ct = sniff(f)
    if ct is None:
        return None, Response({"detail": "Joignez une image (JPEG, PNG) ou un PDF.", "code": "file_type"}, status=400)
    return (f, ct), None


class RequestPayView(APIView):
    """POST multipart: amount, file (the transaction's screenshot), note."""

    def post(self, request, pk):
        req = _get(request, pk)
        if req is None:
            return NOT_YOURS
        try:
            amount = int(request.data.get("amount") or 0)
        except (TypeError, ValueError):
            amount = 0
        got, refusal = _upload(request, required=True)
        if refusal is not None:
            return refusal
        try:
            expenses.pay(req, by=request.user, amount=amount, proof=got[0], content_type=got[1],
                         note=str(request.data.get("note") or ""), request=request)
        except FinanceRule as e:
            return _rule(e)
        return Response(DetailSerializer(req, context={"request": request}).data)


class RequestMessageView(APIView):
    """POST multipart: body and/or file — a comment in the thread."""

    def post(self, request, pk):
        req = _get(request, pk)
        if req is None:
            return NOT_YOURS
        got, refusal = _upload(request, required=False)
        if refusal is not None:
            return refusal
        try:
            expenses.comment(req, by=request.user, body=str(request.data.get("body") or ""),
                             upload=got[0] if got else None, content_type=got[1] if got else "", request=request)
        except FinanceRule as e:
            return _rule(e)
        return Response(DetailSerializer(req, context={"request": request}).data, status=status.HTTP_201_CREATED)
