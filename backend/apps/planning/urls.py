from django.urls import path

from . import views

urlpatterns = [
    path("week/", views.WeekView.as_view(), name="planning-week"),
    path("services/", views.ServiceCreateView.as_view(), name="planning-service-create"),
    path("services/<int:pk>/slot/", views.SlotView.as_view(), name="planning-slot"),
    path("services/<int:pk>/candidates/", views.CandidatesView.as_view(), name="planning-candidates"),
    path("services/<int:pk>/assign-group/", views.AssignGroupView.as_view(), name="planning-assign-group"),
    path("publish/", views.PublishView.as_view(), name="planning-publish"),
    path("groups/", views.GroupsView.as_view(), name="planning-groups"),
    path("mine/", views.MineView.as_view(), name="planning-mine"),
    path("assignments/<int:pk>/confirm/", views.ConfirmView.as_view(), name="planning-confirm"),
    path("assignments/<int:pk>/swap/", views.SwapView.as_view(), name="planning-swap"),
    path("assignments/<int:pk>/swap-candidates/", views.SwapCandidatesView.as_view(), name="planning-swap-candidates"),
    path("requests/", views.RequestsView.as_view(), name="planning-requests"),
    path("requests/<int:pk>/answer/", views.AnswerView.as_view(), name="planning-answer"),
    path("requests/<int:pk>/decide/", views.DecideView.as_view(), name="planning-decide"),
    path("requests/<int:pk>/candidates/", views.ReplacementCandidatesView.as_view(), name="planning-replacements"),
    path("albs/", views.AlbsView.as_view(), name="planning-albs"),
    path("albs/<int:pk>/advance/", views.AlbAdvanceView.as_view(), name="planning-alb-advance"),
]
