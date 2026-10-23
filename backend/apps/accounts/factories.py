import itertools
from datetime import date

import factory

from .models import Role, RoleAssignment, User

_numbers = itertools.count(1)


class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = User
        skip_postgeneration_save = True

    phone = factory.LazyFunction(lambda: f"+2376{next(_numbers):08d}")
    last_name = factory.Faker("last_name", locale="fr_FR")
    first_name = factory.Faker("first_name", locale="fr_FR")
    birth_date = date(1995, 5, 5)

    @factory.post_generation
    def pin(obj, create, extracted, **kwargs):
        obj.set_pin(extracted or "1234")
        if create:
            obj.save()

    @factory.post_generation
    def membership(obj, create, extracted, **kwargs):
        """In the (only) group unless told otherwise: membership=False for
        an account in no group, or a Group."""
        if create and extracted is not False:
            from apps.core.groups import default_group_id
            from apps.core.models import Membership

            gid = extracted.pk if extracted not in (None, True) else default_group_id()
            Membership.all_groups.get_or_create(user=obj, group_id=gid)

    @factory.post_generation
    def password(obj, create, extracted, **kwargs):
        if extracted:
            obj.set_password(extracted)
            if create:
                obj.save()


def give_role(user, slug, **kwargs):
    """Seeded roles come from migration 0002 — fetched, never re-created."""
    role = Role.objects.get(slug=slug)
    kwargs.setdefault("reason", "test")
    kwargs.setdefault("starts_on", date(2025, 10, 1))
    return RoleAssignment.objects.create(user=user, role=role, **kwargs)
