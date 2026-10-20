from django.contrib import admin

from .models import Collection, Due, Entry, QuarterReport


@admin.register(Entry)
class EntryAdmin(admin.ModelAdmin):
    list_display = ("date", "direction", "amount", "category", "label", "status", "created_by", "validated_by")
    list_filter = ("status", "direction", "category")

    def has_change_permission(self, request, obj=None):
        return obj is None or obj.status != Entry.Status.VALIDATED


admin.site.register([Collection, Due, QuarterReport])
