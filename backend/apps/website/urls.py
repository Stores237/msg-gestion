from django.urls import path

from . import views

app_name = "website"

urlpatterns = [
    path("", views.home, name="home"),
    path("telecharger/", views.download, name="download"),
    path("telecharger/apk/", views.apk, name="apk"),
]
