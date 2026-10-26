from rest_framework.throttling import ScopedRateThrottle

from .audit import client_ip


class ClientIPScopedRateThrottle(ScopedRateThrottle):
    """DRF's scoped throttle keyed on `client_ip`. DRF's own get_ident uses
    the whole X-Forwarded-For header, which the client can vary at will."""

    def get_ident(self, request):
        return client_ip(request) or super().get_ident(request)
