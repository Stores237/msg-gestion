"""PDF exports (design: "Exporter en PDF" on the cash book and the report).

Built with reportlab, stored in the media bucket under exports/ with a
random name, and handed back as a short-lived signed link."""

import io
import secrets

from django.core.files.base import ContentFile
from django.core.files.storage import default_storage
from django.utils import timezone
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from apps.core.models import Settings

GREEN = colors.HexColor("#2E7D46")
CATS = {"inscription": "Inscriptions", "amende": "Amendes", "aide_don": "Aides et dons", "solidarite": "Contributions de solidarité", "depense": "Dépenses"}


def money(n):
    return f"{n:,}".replace(",", " ") + " FCFA"


def _doc(title, story_builder):
    buf = io.BytesIO()
    st = Settings.get()
    styles = getSampleStyleSheet()
    doc = SimpleDocTemplate(buf, pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm, topMargin=16 * mm, bottomMargin=16 * mm, title=title)
    story = [
        Paragraph(f"<font color='#2E7D46'><b>MSG</b></font> · {st.name}", styles["Normal"]),
        Paragraph(st.parish, styles["Normal"]),
        Spacer(1, 8 * mm),
        Paragraph(f"<b>{title}</b>", styles["Title"]),
        Spacer(1, 4 * mm),
    ]
    story += story_builder(styles)
    story += [Spacer(1, 8 * mm), Paragraph(f"Généré le {timezone.localtime():%d/%m/%Y à %H:%M}", styles["Italic"])]
    doc.build(story)
    return buf.getvalue()


def _table(rows, widths, right_cols=()):
    t = Table(rows, colWidths=widths, repeatRows=1)
    style = [
        ("BACKGROUND", (0, 0), (-1, 0), GREEN),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 9),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F6F3EE")]),
        ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#E3DDD2")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ]
    for c in right_cols:
        style.append(("ALIGN", (c, 0), (c, -1), "RIGHT"))
    t.setStyle(TableStyle(style))
    return t


def report_pdf(r):
    def build(styles):
        rows = [["Synthèse", "Montant"],
                [f"Solde d’ouverture ({r['start']:%d/%m/%Y})", money(r["opening"])],
                ["Entrées", money(r["in"])], ["Sorties", money(r["out"])],
                ["Solde de clôture", money(r["closing"])]]
        cats = [["Entrées par catégorie", "Montant"]] + [[CATS.get(k, k), money(v)] for k, v in r["in_by_category"].items()]
        out = [_table(rows, [110 * mm, 50 * mm], (1,)), Spacer(1, 6 * mm), _table(cats, [110 * mm, 50 * mm], (1,))]
        status = (f"Validé par {r['validated_by']} le {timezone.localtime(r['validated_at']):%d/%m/%Y}" if r["validated_by"]
                  else f"Non validé · {r['pending']} opération(s) à vérifier")
        return out + [Spacer(1, 6 * mm), Paragraph(status, styles["Normal"])]

    return _doc(f"Rapport T{r['quarter']} {r['year']}", build)


def cashbook_pdf(entries):
    def build(styles):
        rows = [["Date", "Libellé", "Membre", "Saisi / validé", "Montant"]]
        for e in entries:
            who = e.created_by.short_name + (f" / {e.validated_by.short_name}" if e.validated_by else " / à valider")
            rows.append([f"{e.date:%d/%m/%Y}", Paragraph(f"{CATS.get(e.category, e.category)} · {e.label}", styles["BodyText"]),
                         e.member.short_name if e.member else "", who, ("+ " if e.direction == "in" else "− ") + money(e.amount)])
        return [_table(rows, [22 * mm, 62 * mm, 30 * mm, 34 * mm, 28 * mm], (4,))]

    return _doc("Livre de caisse", build)


def publish(pdf_bytes, prefix):
    name = default_storage.save(f"exports/{prefix}-{secrets.token_urlsafe(12)}.pdf", ContentFile(pdf_bytes))
    return default_storage.url(name)
