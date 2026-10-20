from django.contrib import admin

from .models import Attendance, Event


@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ("title", "kind", "starts_at", "place")
    list_filter = ("kind",)


@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = ("event", "member", "status", "marked_at")
    list_filter = ("status",)
