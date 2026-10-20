from django.utils import timezone
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView

from .models import User
from .serializers import LogoutSerializer, MeSerializer, PhoneLookupSerializer, PinLoginSerializer
from .services import check_pin_login

# Every error carries a stable `code` (+ numbers) so the app can word it in
# the member's chosen language (FR/EN); `detail` is the French fallback.
# One message for "no such number" and "account disabled" so the lookup
# can't be used to tell a suspended member from a stranger.
UNKNOWN_PHONE = "Ce numéro n’est pas enregistré. Le secrétaire général vous inscrit lors de l’assise du samedi."


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
        return Response({"first_name": user.first_name, "has_pin": user.has_pin})


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
                {"detail": "Aucun code PIN pour ce compte. Demandez au secrétaire général de l’initialiser.", "code": "no_pin"},
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

        refresh = RefreshToken.for_user(result.user)
        User.objects.filter(pk=user.pk).update(last_login=timezone.now())
        return Response({"access": str(refresh.access_token), "refresh": str(refresh)})


class ThrottledTokenRefreshView(TokenRefreshView):
    throttle_scope = "token_refresh"


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
        return Response(MeSerializer(request.user).data)

