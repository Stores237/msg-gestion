"""What may be attached, checked on the bytes, not the file name."""

MAX_BYTES = 10 * 1024 * 1024

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
