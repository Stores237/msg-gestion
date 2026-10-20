import secrets

from django.conf import settings
from django.contrib.auth.hashers import check_password, make_password
from django.db import models


class BackupCode(models.Model):
    """One-time back-office login codes (design: "Codes de secours · 8
    codes restants sur 10"). Stored hashed; each works once."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="backup_codes")
    code_hash = models.CharField(max_length=128)
    used_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    COUNT = 10

    @classmethod
    def regenerate(cls, user):
        """Replace all codes; returns the plain codes, shown once."""
        cls.objects.filter(user=user).delete()
        codes = [f"{secrets.randbelow(10**8):08d}" for _ in range(cls.COUNT)]
        cls.objects.bulk_create([cls(user=user, code_hash=make_password(c)) for c in codes])
        return [f"{c[:4]}-{c[4:]}" for c in codes]

    @classmethod
    def consume(cls, user, raw):
        from django.utils import timezone

        raw = "".join(ch for ch in (raw or "") if ch.isdigit())
        if len(raw) != 8:
            return False
        for bc in cls.objects.filter(user=user, used_at__isnull=True):
            if check_password(raw, bc.code_hash):
                bc.used_at = timezone.now()
                bc.save(update_fields=["used_at"])
                return True
        return False

    @classmethod
    def remaining(cls, user):
        return cls.objects.filter(user=user, used_at__isnull=True).count()


class BackofficeSession(models.Model):
    """A back-office login (design: "Sessions actives"): which device, from
    where, last activity. Closing one ends that Django session."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="backoffice_sessions")
    session_key = models.CharField(max_length=64, unique=True)
    device = models.CharField(max_length=200, blank=True)
    ip = models.GenericIPAddressField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    last_seen = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-last_seen"]
