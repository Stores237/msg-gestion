import re

CAMEROON_PREFIX = "+237"


class InvalidPhone(ValueError):
    pass


def normalize_phone(raw):
    """Return an E.164 string.

    Members type their number the way it's printed on the attendance sheet
    ("6 77 45 21 08"), so a 9-digit number starting with 6 or 2 is assumed
    Cameroonian. Diaspora members type their full international number
    ("+33 6 12 45 78 90" or "0033612457890").
    """
    if raw is None:
        raise InvalidPhone("Numéro manquant.")
    digits = re.sub(r"[^\d+]", "", str(raw))
    if digits.startswith("00"):
        digits = "+" + digits[2:]
    if digits.startswith("+"):
        if not re.fullmatch(r"\+\d{8,15}", digits):
            raise InvalidPhone("Numéro international invalide.")
        if digits.startswith(CAMEROON_PREFIX) and not re.fullmatch(r"\+237[26]\d{8}", digits):
            raise InvalidPhone("Format : 6 XX XX XX XX.")
        return digits
    if digits.startswith("237") and len(digits) == 12:
        digits = digits[3:]
    if re.fullmatch(r"[26]\d{8}", digits):
        return CAMEROON_PREFIX + digits
    raise InvalidPhone("Format : 6 XX XX XX XX.")


def mask_phone(e164):
    """"+237677452141" -> "+237 6•• •• •• 41" (design: 2FA screen)."""
    if e164.startswith(CAMEROON_PREFIX) and len(e164) == 13:
        return f"+237 {e164[4]}•• •• •• {e164[-2:]}"
    return e164[:4] + "•" * (len(e164) - 6) + e164[-2:]


def format_phone(e164):
    """"+237677452108" -> "+237 6 77 45 21 08" (how members write it)."""
    if e164.startswith(CAMEROON_PREFIX) and len(e164) == 13:
        n = e164[4:]
        return f"+237 {n[0]} {n[1:3]} {n[3:5]} {n[5:7]} {n[7:9]}"
    return e164
