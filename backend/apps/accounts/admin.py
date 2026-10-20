from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import Role, RoleAssignment, RolePermission, User


class AssignmentInline(admin.TabularInline):
    model = RoleAssignment
    fk_name = "user"
    extra = 0
    fields = ("role", "starts_on", "ends_on", "reason", "revoked_at")
    readonly_fields = ("revoked_at",)


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Technical-team view. Day-to-day role changes go through the
    back-office, which enforces the separation-of-duties and two-super-
    admin rules and writes the audit log; edits here bypass both."""

    ordering = ("last_name", "first_name")
    list_display = ("full_name", "phone", "status", "is_diaspora", "last_login")
    list_filter = ("status", "is_diaspora", "is_staff")
    search_fields = ("last_name", "first_name", "phone")
    readonly_fields = ("pin", "pin_failed_attempts", "pin_locked_until", "last_login", "created_at")
    fieldsets = (
        (None, {"fields": ("phone", "password")}),
        ("Identité", {"fields": ("last_name", "first_name", "birth_date", "joined_on", "status", "is_diaspora", "city", "photo")}),
        ("Parent ou tuteur", {"fields": ("parent_name", "parent_relation", "parent_phone")}),
        ("Application", {"fields": ("pin", "pin_failed_attempts", "pin_locked_until", "last_login", "created_at")}),
        ("Admin Django", {"fields": ("is_active", "is_staff", "is_superuser")}),
    )
    add_fieldsets = ((None, {"classes": ("wide",), "fields": ("phone", "last_name", "first_name", "password1", "password2")}),)
    inlines = [AssignmentInline]


class PermissionInline(admin.TabularInline):
    model = RolePermission
    extra = 0


@admin.register(Role)
class RoleAdmin(admin.ModelAdmin):
    list_display = ("name", "slug", "kind", "mandate_months", "is_archived")
    inlines = [PermissionInline]
