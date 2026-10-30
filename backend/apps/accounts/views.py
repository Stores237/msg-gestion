from django.conf import settings
from django.utils import timezone
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.serializers import TokenRefreshSerializer
from rest_framework_simplejwt.settings import api_settings
from rest_framework_simplejwt.tokens import RefreshToken, UntypedToken
from rest_framework_simplejwt.views import TokenRefreshView

from apps.core import audit, sms

from .authentication import BACKOFFICE_ONLY, other_device
from .models import User
from .serializers import LogoutSerializer, MeSerializer, PhoneLookupSerializer, PinLoginSerializer
from .services import check_pin_login, open_app_session, pin_problem, session_ended

# Every error carries a stable `code` (+ numbers) so the app can word it in
# the member's chosen language (FR/EN); `detail` is the French fallback.
# One message for "no such number" and "account disabled" so the lookup
# can't be used to tell a suspended member from a stranger.
UNKNOWN_PHONE = "Ce numéro n’est pas enregistré. Demandez au responsable de votre groupe de vous inscrire."


TERMS_REQUIRED = "Acceptez les conditions d’utilisation pour vous connecter."


def _terms_refusal(user, request):
    """None when the member has accepted the current conditions (the login
    checkbox, sent as accept_terms + the version it showed); otherwise the
    428 to answer. A box ticked on a text changed since doesn't count."""
    from apps.core.models import PlatformSettings

    current = PlatformSettings.get().terms_version
    if user.terms_version >= current:
        return None
    if request.data.get("accept_terms") in (True, "true") and str(request.data.get("terms_version")) == str(current):
        return None
    return Response({"detail": TERMS_REQUIRED, "code": "terms_required", "terms_version": current}, status=428)


def _record_terms(user, request):
    from apps.core.models import PlatformSettings

    current = PlatformSettings.get().terms_version
    if user.terms_version >= current:
        return
    user.terms_version = current
    user.terms_accepted_at = timezone.now()
    user.save(update_fields=["terms_version", "terms_accepted_at"])
    audit.record("Conditions d’utilisation acceptées", actor=user, obj=user, request=request, detail={"version": current})


def _login_allowed(user):
    return user is not None and user.is_active and user.status not in (User.Status.SUSPENDED, User.Status.ARCHIVED)


class PhoneLookupView(APIView):
    """Step 1 of the app login: is this number a member, and has it a PIN?

    Returns the first name so the PIN screen can greet the member
    ("Bonjour Ingrid") — a deliberate, throttled disclosure the design asks
    for; see SECURITY.md.
    """

    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_scope = "phone_lookup"

    @extend_schema(request=PhoneLookupSerializer, responses=OpenApiTypes.OBJECT)
    def post(self, request):
        s = PhoneLookupSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        user = User.objects.filter(phone=s.validated_data["phone"]).first()
        if not _login_allowed(user):
            return Response({"detail": UNKNOWN_PHONE, "code": "unknown_member"}, status=status.HTTP_404_NOT_FOUND)
        from apps.core.models import PlatformSettings

        return Response({"first_name": user.first_name, "has_pin": user.has_pin, "terms_version": PlatformSettings.get().terms_version})


class PinLoginView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_scope = "pin_login"

    @extend_schema(request=PinLoginSerializer, responses=OpenApiTypes.OBJECT)
    def post(self, request):
        s = PinLoginSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        user = User.objects.filter(phone=s.validated_data["phone"]).first()
        if not _login_allowed(user):
            return Response({"detail": UNKNOWN_PHONE, "code": "unknown_member"}, status=status.HTTP_404_NOT_FOUND)
        if not user.has_pin:
            return Response(
                {"detail": "Aucun code PIN pour ce compte. Demandez au responsable de votre groupe de l’initialiser.", "code": "no_pin"},
                status=status.HTTP_409_CONFLICT,
            )

        result = check_pin_login(user, s.validated_data["pin"], request=request)
        if result.locked_until is not None and not result.ok:
            minutes = max(1, int((result.locked_until - timezone.now()).total_seconds() // 60) + 1)
            return Response(
                {"detail": f"Compte bloqué après trop d’erreurs. Réessayez dans {minutes} min.", "code": "locked", "minutes": minutes, "locked_until": result.locked_until},
                status=status.HTTP_423_LOCKED,
            )
        if not result.ok:
            left = result.attempts_left
            return Response(
                {"detail": f"Code incorrect. Il vous reste {left} essai{'s' if left > 1 else ''}.", "code": "wrong_pin", "attempts_left": left},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        if user.is_platform_account:
            # Checked after the PIN, so the answer only tells the holder
            # which accounts are super admins.
            audit.record("Refus · super admin dans l’application", actor=user, obj=user, request=request, refused=True)
            return Response({"detail": BACKOFFICE_ONLY, "code": "backoffice_only"}, status=status.HTTP_403_FORBIDDEN)
        # After the PIN, so only the holder learns the terms changed.
        if refused := _terms_refusal(user, request):
            return refused
        _record_terms(user, request)
        refresh = open_app_session(result.user, request=request)
        User.objects.filter(pk=user.pk).update(last_login=timezone.now())
        return Response({"access": str(refresh.access_token), "refresh": str(refresh), "pin_must_change": result.user.pin_must_change})


class SessionTokenRefreshSerializer(TokenRefreshSerializer):
    """A phone signed out by a newer sign-in can't renew its tokens; it is
    told why (`other_device`) rather than a bare "token not valid"."""

    def validate(self, attrs):
        try:
            token = UntypedToken(attrs["refresh"])
        except TokenError:
            token = None  # expired or forged: the usual answer below
        if token is not None:
            user = User.objects.filter(pk=token.get(api_settings.USER_ID_CLAIM)).first()
            if user is not None and session_ended(user, token):
                raise other_device()
        return super().validate(attrs)


class ThrottledTokenRefreshView(TokenRefreshView):
    throttle_scope = "token_refresh"
    serializer_class = SessionTokenRefreshSerializer


class LogoutView(APIView):
    @extend_schema(request=LogoutSerializer, responses={204: None})
    def post(self, request):
        s = LogoutSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        try:
            RefreshToken(s.validated_data["refresh"]).blacklist()
        except TokenError:
            pass  # already invalid: the outcome the caller wanted
        return Response(status=status.HTTP_204_NO_CONTENT)


class MeView(APIView):
    """Who am I, which roles are active today, and which tabs to show."""

    @extend_schema(responses=MeSerializer)
    def get(self, request):
        return Response(MeSerializer(request.user, context={"request": request}).data)



class ChangePinView(APIView):
    """Member changes their own PIN (current PIN required; wrong current
    PINs count towards the lockout like a login)."""

    @extend_schema(request=None, responses={204: None})
    def post(self, request):
        current, new = request.data.get("current_pin", ""), request.data.get("new_pin", "")
        problem = pin_problem(new)
        if problem:
            return Response({"detail": "Choisissez un code moins simple.", "code": problem}, status=400)
        result = check_pin_login(request.user, str(current), request=request)
        if not result.ok:
            if result.locked_until is not None:
                return Response({"detail": "Compte bloqué.", "code": "locked", "minutes": settings.PIN_LOCKOUT_MINUTES}, status=423)
            return Response({"detail": "Code actuel incorrect.", "code": "wrong_pin", "attempts_left": result.attempts_left}, status=401)
        user = result.user
        user.set_pin(new)
        user.save(update_fields=["pin", "pin_failed_attempts", "pin_locked_until", "pin_must_change"])
        audit.record("PIN modifié par le membre", actor=user, obj=user, request=request)
        return Response(status=status.HTTP_204_NO_CONTENT)


class FinanceCodeView(APIView):
    """POST {pin, code}: set or reset the finance code (owner, 2026-10-30).
    The PIN proves it's the member; wrong PINs count like a login."""

    throttle_scope = "pin_login"

    @extend_schema(request=None, responses={204: None})
    def post(self, request):
        from .services import set_finance_code

        code = str(request.data.get("code", ""))
        problem = pin_problem(code)
        if problem:
            return Response({"detail": "Choisissez un code moins simple.", "code": problem}, status=400)
        if request.user.check_pin(code):
            return Response({"detail": "Le code finances doit être différent du PIN.", "code": "same_as_pin"}, status=400)
        result = check_pin_login(request.user, str(request.data.get("pin", "")), request=request)
        if not result.ok:
            if result.locked_until is not None:
                return Response({"detail": "Compte bloqué.", "code": "locked", "minutes": settings.PIN_LOCKOUT_MINUTES}, status=423)
            return Response({"detail": "PIN incorrect.", "code": "wrong_pin", "attempts_left": result.attempts_left}, status=401)
        set_finance_code(result.user, code, request=request)
        return Response(status=status.HTTP_204_NO_CONTENT)


class FinanceCodeSwitchView(APIView):
    """POST {on, code}: ask for the finance code on one's own Finances even
    when the group doesn't require it. Turning it off needs the code, so a
    phone left open can't drop it (owner, 2026-10-30)."""

    throttle_scope = "pin_login"

    @extend_schema(request=None, responses={204: None})
    def post(self, request):
        from .services import check_finance_code

        on = bool(request.data.get("on"))
        user = request.user
        if not user.finance_code:
            return Response({"detail": "Choisissez d’abord votre code finances.", "code": "no_finance_code"}, status=409)
        if not on:
            result = check_finance_code(user, str(request.data.get("code", "")), request=request)
            if not result.ok:
                if result.locked_until is not None:
                    return Response({"detail": "Code finances bloqué.", "code": "locked",
                                     "minutes": settings.PIN_LOCKOUT_MINUTES}, status=423)
                return Response({"detail": "Code finances incorrect.", "code": "wrong_code",
                                 "attempts_left": result.attempts_left}, status=401)
            user = result.user
        user.finance_code_on = on
        user.save(update_fields=["finance_code_on"])
        audit.record("Code finances " + ("activé" if on else "désactivé") + " par le membre", actor=user, obj=user,
                     request=request, sensitive=True)
        return Response(status=status.HTTP_204_NO_CONTENT)


class FinanceCodeCheckView(APIView):
    """POST {code}: 204 when right; 401 with attempts left; 423 locked."""

    throttle_scope = "pin_login"

    @extend_schema(request=None, responses={204: None})
    def post(self, request):
        from .services import check_finance_code

        if not request.user.finance_code:
            return Response({"detail": "Choisissez d’abord votre code finances.", "code": "no_finance_code"}, status=409)
        result = check_finance_code(request.user, str(request.data.get("code", "")), request=request)
        if result.ok:
            return Response(status=status.HTTP_204_NO_CONTENT)
        if result.locked_until is not None:
            return Response({"detail": "Code finances bloqué.", "code": "locked", "minutes": settings.PIN_LOCKOUT_MINUTES}, status=423)
        return Response({"detail": "Code finances incorrect.", "code": "wrong_code", "attempts_left": result.attempts_left},
                        status=401)


class ForgotPinView(APIView):
    """Step 1 of "Code oublié ?": text a one-time code to the member."""

    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_scope = "pin_forgot"

    @extend_schema(request=PhoneLookupSerializer, responses={202: None})
    def post(self, request):
        s = PhoneLookupSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        user = User.objects.filter(phone=s.validated_data["phone"]).first()
        if not _login_allowed(user):
            return Response({"detail": UNKNOWN_PHONE, "code": "unknown_member"}, status=status.HTTP_404_NOT_FOUND)
        try:
            sms.send_code(user.phone)
        except sms.SmsUnavailable:
            # No SMS provider yet (Twilio): say so, the app points to the secretary.
            return Response({"detail": "SMS indisponible. Demandez au responsable de votre groupe.", "code": "sms_unavailable"}, status=503)
        return Response(status=status.HTTP_202_ACCEPTED)


class ForgotPinConfirmView(APIView):
    """Step 2: code + new PIN → new PIN set and the member is logged in."""

    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_scope = "pin_forgot"

    @extend_schema(request=None, responses=OpenApiTypes.OBJECT)
    def post(self, request):
        s = PhoneLookupSerializer(data={"phone": request.data.get("phone")})
        s.is_valid(raise_exception=True)
        new = str(request.data.get("new_pin", ""))
        problem = pin_problem(new)
        if problem:
            return Response({"detail": "Choisissez un code moins simple.", "code": problem}, status=400)
        user = User.objects.filter(phone=s.validated_data["phone"]).first()
        if not _login_allowed(user):
            return Response({"detail": UNKNOWN_PHONE, "code": "unknown_member"}, status=status.HTTP_404_NOT_FOUND)
        if refused := _terms_refusal(user, request):
            return refused  # before the SMS code is used up, so the member can tick and retry
        try:
            ok = sms.check_code(user.phone, str(request.data.get("code", "")))
        except sms.SmsUnavailable:
            return Response({"detail": "SMS indisponible.", "code": "sms_unavailable"}, status=503)
        if not ok:
            return Response({"detail": "Code incorrect ou expiré.", "code": "bad_code"}, status=400)
        user.set_pin(new)
        user.save(update_fields=["pin", "pin_failed_attempts", "pin_locked_until", "pin_must_change"])
        audit.record("PIN réinitialisé par SMS", actor=user, obj=user, request=request)
        _record_terms(user, request)
        refresh = open_app_session(user, request=request)
        return Response({"access": str(refresh.access_token), "refresh": str(refresh)})


class TermsView(APIView):
    """GET, before login: the conditions and privacy texts the login
    checkbox links to, with the version to accept."""

    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_scope = "terms"

    def get(self, request):
        from apps.core.models import PlatformSettings

        p = PlatformSettings.get()
        return Response({"terms_version": p.terms_version, "terms_text": p.terms_text, "privacy_text": p.privacy_text})


class PreferencesView(APIView):
    """PATCH {remind_eve, remind_2h} (design: event → "Rappels")."""

    def patch(self, request):
        user = request.user
        fields = []
        for f in ("remind_eve", "remind_2h"):
            if f in request.data:
                setattr(user, f, bool(request.data[f]))
                fields.append(f)
        if fields:
            user.save(update_fields=fields)
        return Response({"remind_eve": user.remind_eve, "remind_2h": user.remind_2h})
