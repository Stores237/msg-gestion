from django.contrib import admin

from .models import Announcement


@admin.register(Announcement)
class AnnouncementAdmin(admin.ModelAdmin):
    list_display = ("title", "kind", "pinned", "author", "created_at")
    list_filter = ("kind", "pinned")
