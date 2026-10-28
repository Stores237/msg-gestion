"""What may be attached, checked on the bytes, not the file name."""

MAX_BYTES = 10 * 1024 * 1024

# Photos in an announcement (owner, 2026-10-28): one frame for all, a size
# cap, a few per announcement. The app frames and compresses before sending;
# these are checked again here.
PHOTO_MAX_BYTES = 2 * 1024 * 1024
PHOTO_RATIO = (4, 3)  # landscape
PHOTO_RATIO_TOLERANCE = 0.02
PHOTO_MAX_SIDE = 2048
PHOTO_MIN_SIDE = 320
PHOTOS_PER_ANNOUNCEMENT = 4

SIGNATURES = {
    b"%PDF-": "application/pdf",
    b"\xff\xd8\xff": "image/jpeg",
    b"\x89PNG\r\n\x1a\n": "image/png",
}


def sniff(upload):
    head = upload.read(8)
    upload.seek(0)
    for magic, content_type in SIGNATURES.items():
        if head.startswith(magic):
            return content_type
    return None


def photo_problem(upload):
    """None when an image fits the announcement frame; else (code, message)."""
    from PIL import Image, UnidentifiedImageError

    if upload.size > PHOTO_MAX_BYTES:
        return "photo_too_large", "Photo trop lourde (2 Mo maximum)."
    try:
        with Image.open(upload) as im:
            width, height = im.size  # reads the header only
    except (UnidentifiedImageError, OSError):
        return "file_type", "Image illisible."
    finally:
        upload.seek(0)
    w, h = PHOTO_RATIO
    if abs(width / height - w / h) > PHOTO_RATIO_TOLERANCE * (w / h):
        return "photo_frame", f"La photo doit être au format paysage {w}:{h}."
    if max(width, height) > PHOTO_MAX_SIDE or min(width, height) < PHOTO_MIN_SIDE:
        return "photo_size", f"Photo entre {PHOTO_MIN_SIDE} et {PHOTO_MAX_SIDE} pixels de côté."
    return None
