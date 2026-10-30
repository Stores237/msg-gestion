from django.urls import path

from . import expense_views as xv
from . import views

urlpatterns = [
    path("summary/", views.SummaryView.as_view(), name="fin-summary"),
    path("entries/", views.EntryListView.as_view(), name="fin-entries"),
    path("entries/validate/", views.EntryValidateManyView.as_view(), name="fin-entries-validate"),
    path("entries/<int:pk>/", views.EntryDetailView.as_view(), name="fin-entry"),
    path("entries/<int:pk>/validate/", views.EntryValidateView.as_view(), name="fin-entry-validate"),
    path("entries/<int:pk>/confirm/", views.EntryConfirmView.as_view(), name="fin-entry-confirm"),
    path("collections/", views.CollectionListView.as_view(), name="fin-collections"),
    path("collections/<int:pk>/", views.CollectionDetailView.as_view(), name="fin-collection"),
    path("collections/<int:pk>/payments/", views.CollectionPayView.as_view(), name="fin-collection-pay"),
    path("collections/<int:pk>/close/", views.CollectionCloseView.as_view(), name="fin-collection-close"),
    path("fines/", views.FineView.as_view(), name="fin-fines"),
    path("dues/<int:pk>/pay/", views.DuePayView.as_view(), name="fin-due-pay"),
    path("mine/", views.MineView.as_view(), name="fin-mine"),
    path("report/", views.ReportView.as_view(), name="fin-report"),
    path("report/validate/", views.ReportValidateView.as_view(), name="fin-report-validate"),
    path("report/pdf/", views.ReportPdfView.as_view(), name="fin-report-pdf"),
    path("entries/pdf/", views.CashbookPdfView.as_view(), name="fin-entries-pdf"),
    path("statement/", views.StatementView.as_view(), name="fin-statement"),
    path("statement/pdf/", views.StatementPdfView.as_view(), name="fin-statement-pdf"),
    path("statement/<int:pk>/", views.MemberStatementView.as_view(), name="fin-member-statement"),
    path("statement/<int:pk>/pdf/", views.MemberStatementPdfView.as_view(), name="fin-member-statement-pdf"),
    path("expense-domains/", xv.DomainListView.as_view(), name="fin-expense-domains"),
    path("expenses/", xv.RequestListView.as_view(), name="fin-expenses"),
    path("expenses/<int:pk>/", xv.RequestDetailView.as_view(), name="fin-expense"),
    path("expenses/<int:pk>/decide/", xv.RequestStepView.as_view(step="decide"), name="fin-expense-decide"),
    path("expenses/<int:pk>/review/", xv.RequestStepView.as_view(step="review"), name="fin-expense-review"),
    path("expenses/<int:pk>/cancel/", xv.RequestStepView.as_view(step="cancel"), name="fin-expense-cancel"),
    path("expenses/<int:pk>/pay/", xv.RequestPayView.as_view(), name="fin-expense-pay"),
    path("expenses/<int:pk>/messages/", xv.RequestMessageView.as_view(), name="fin-expense-messages"),
]
