from django.urls import path

from . import views

urlpatterns = [
    path("summary/", views.SummaryView.as_view(), name="fin-summary"),
    path("entries/", views.EntryListView.as_view(), name="fin-entries"),
    path("entries/<int:pk>/", views.EntryDetailView.as_view(), name="fin-entry"),
    path("entries/<int:pk>/validate/", views.EntryValidateView.as_view(), name="fin-entry-validate"),
    path("collections/", views.CollectionListView.as_view(), name="fin-collections"),
    path("collections/<int:pk>/", views.CollectionDetailView.as_view(), name="fin-collection"),
    path("collections/<int:pk>/payments/", views.CollectionPayView.as_view(), name="fin-collection-pay"),
    path("collections/<int:pk>/close/", views.CollectionCloseView.as_view(), name="fin-collection-close"),
    path("fines/", views.FineView.as_view(), name="fin-fines"),
    path("dues/<int:pk>/pay/", views.DuePayView.as_view(), name="fin-due-pay"),
    path("mine/", views.MineView.as_view(), name="fin-mine"),
    path("report/", views.ReportView.as_view(), name="fin-report"),
    path("report/validate/", views.ReportValidateView.as_view(), name="fin-report-validate"),
]
