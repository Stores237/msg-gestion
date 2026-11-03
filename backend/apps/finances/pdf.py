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
CATS = {"inscription": "Inscriptions", "amende": "Amendes", "aide_don": "Aides et dons", "solidarite": "Contributions de solidarité", "depense": "Dépenses",
        "reseau": "Quotes-parts du réseau", "autre": "Autre"}


def money(n):
    return f"{n:,}".replace(",", " ") + " FCFA"


def _doc(title, story_builder, period=""):
    buf = io.BytesIO()
    st = Settings.get()
    styles = getSampleStyleSheet()
    doc = SimpleDocTemplate(buf, pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm, topMargin=16 * mm, bottomMargin=16 * mm, title=title)
    story = [
        Paragraph(f"<font color='#0E9F8F'><b>Huddle</b></font> · {st.name}", styles["Normal"]),
        Paragraph(st.parish, styles["Normal"]),
        Spacer(1, 8 * mm),
        Paragraph(f"<b>{title}</b>", styles["Title"]),
        *([Paragraph(f"Période : {period}", styles["Normal"]), Spacer(1, 2 * mm)] if period else []),
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
        if r.get("network"):
            n = r["network"]
            net = [["Quotes-parts du réseau", "Groupe", "Montant"]]
            net += [[f"Versée · {x['title']}", x["group"], money(x["amount"])] for x in n["paid"]]
            net += [[f"Reçue · {x['title']}", x["group"], money(x["amount"])] for x in n["received"]]
            if len(net) == 1:
                net.append(["Aucune sur le trimestre", "", ""])
            net += [["Restant à verser au groupe au-dessus", "", money(n["owed_open"])],
                    ["Restant à recevoir des groupes rattachés", "", money(n["asked_open"])]]
            out += [Spacer(1, 6 * mm), _table(net, [80 * mm, 50 * mm, 30 * mm], (2,))]
        return out + [Spacer(1, 6 * mm), Paragraph(status, styles["Normal"])]

    return _doc(f"Rapport T{r['quarter']} {r['year']}", build)


def cashbook_pdf(entries, period="", opening=None, closing=None):
    def build(styles):
        out = []
        if opening is not None:
            out += [_table([["Solde validé", "Montant"], ["Au début de la période", money(opening)],
                            ["À la fin de la période", money(closing)]], [110 * mm, 50 * mm], (1,)), Spacer(1, 6 * mm)]
        rows = [["Date", "Libellé", "Membre", "Saisi / validé", "Montant"]]
        for e in entries:
            who = e.created_by.short_name + (f" / {e.validated_by.short_name}" if e.validated_by else " / à valider")
            rows.append([f"{e.date:%d/%m/%Y}", Paragraph(f"{CATS.get(e.category, e.category)} · {e.label}", styles["BodyText"]),
                         e.member.short_name if e.member else "", who, ("+ " if e.direction == "in" else "− ") + money(e.amount)])
        if len(rows) == 1:
            return out + [Paragraph("Aucune opération sur la période.", styles["Normal"])]
        return out + [_table(rows, [22 * mm, 62 * mm, 30 * mm, 34 * mm, 28 * mm], (4,))]

    return _doc("Livre de caisse", build, period)


STATUS = {"validated": "validé", "pending": "à valider", "to_confirm": "à finaliser"}


def statement_pdf(rows, totals, period=""):
    """Bilan général: one line per member."""
    def build(styles):
        table = [["Membre", "Dû", "Versé (validé)", "À valider", "Reste à payer"]]
        for r in rows:
            table.append([Paragraph(r["full_name"], styles["BodyText"]), money(r["owed"]), money(r["paid"]),
                          money(r["pending"]) if r["pending"] else "", money(r["remaining"]) if r["remaining"] else "soldé"])
        table.append(["Total", money(totals["owed"]), money(totals["paid"]), money(totals["pending"]), money(totals["remaining"])])
        t = _table(table, [58 * mm, 28 * mm, 30 * mm, 28 * mm, 30 * mm], (1, 2, 3, 4))
        t.setStyle(TableStyle([("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"), ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#E8F2EB"))]))
        return [Paragraph(f"{len(rows)} membres · « Versé » ne compte que les paiements validés par le commissaire aux comptes.",
                          styles["Normal"]), Spacer(1, 4 * mm), t]

    return _doc("Bilan financier des membres", build, period)


def member_statement_pdf(st):
    """Bilan of one member: totals, debts, payments."""
    def build(styles):
        summary = [["Synthèse", "Montant"], ["Total dû", money(st["owed"])], ["Versé (validé)", money(st["paid"])],
                   ["En attente de validation", money(st["pending"])], ["Reste à payer", money(st["remaining"])]]
        out = [Paragraph(f"<b>{st['full_name']}</b> · {st['phone']}", styles["Normal"]), Spacer(1, 4 * mm),
               _table(summary, [110 * mm, 50 * mm], (1,)), Spacer(1, 6 * mm), Paragraph("<b>Dettes</b>", styles["Heading3"])]
        if st["dues"]:
            dues = [["Nature", "Libellé", "Montant", "Payé", "Reste"]]
            for d in st["dues"]:
                dues.append([d["kind_label"], Paragraph(d["label"], styles["BodyText"]), money(d["amount"]), money(d["paid"]),
                             money(d["remaining"]) if d["remaining"] else "soldé"])
            out.append(_table(dues, [36 * mm, 56 * mm, 26 * mm, 26 * mm, 26 * mm], (2, 3, 4)))
        else:
            out.append(Paragraph("Aucune dette sur la période." if st.get("period") else "Aucune dette.", styles["Normal"]))
        out += [Spacer(1, 6 * mm), Paragraph("<b>Opérations à son nom</b>", styles["Heading3"])]
        if st["entries"]:
            lines = [["Date", "Libellé", "Saisi / validé", "Montant"]]
            for e in st["entries"]:
                who = e["created_by"] + (f" / {e['validated_by']}" if e["validated_by"] else " / à valider")
                lines.append([f"{e['date']:%d/%m/%Y}", Paragraph(f"{e['category_label']} · {e['label']}", styles["BodyText"]), who,
                              ("+ " if e["direction"] == "in" else "− ") + money(e["amount"])])
            out.append(_table(lines, [24 * mm, 70 * mm, 46 * mm, 30 * mm], (3,)))
        else:
            out.append(Paragraph("Aucune opération.", styles["Normal"]))
        return out

    return _doc("Bilan financier individuel", build, st.get("period", ""))


def publish(pdf_bytes, prefix):
    name = default_storage.save(f"exports/{prefix}-{secrets.token_urlsafe(12)}.pdf", ContentFile(pdf_bytes))
    return default_storage.url(name)
