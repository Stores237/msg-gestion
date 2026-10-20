from django.contrib import admin

from .models import AlbRotation, Assignment, Request, Service, ServiceGroup

admin.site.register([ServiceGroup, Service, Assignment, Request, AlbRotation])
