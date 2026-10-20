import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'auth_session.dart';
import 'repositories/announcements_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/events_repository.dart';
import 'repositories/finances_repository.dart';
import 'repositories/planning_repository.dart';
import 'repositories/http/http_announcements_repository.dart';
import 'repositories/http/http_auth_repository.dart';
import 'repositories/http/http_events_repository.dart';
import 'repositories/http/http_finances_repository.dart';
import 'repositories/http/http_planning_repository.dart';
import 'repositories/http/http_members_repository.dart';
import 'repositories/http/http_profile_repository.dart';
import 'repositories/members_repository.dart';
import 'repositories/profile_repository.dart';

/// Screens depend on repository interfaces, never on [ApiClient]; tests
/// swap in fakes with [debugSetInstance].
class RepositoryLocator {
  RepositoryLocator({
    AuthSession? authSession,
    ApiClient? apiClient,
    AuthRepository? auth,
    ProfileRepository? profile,
    MembersRepository? members,
    EventsRepository? events,
    AnnouncementsRepository? announcements,
    FinancesRepository? finances,
    PlanningRepository? planning,
    NotificationsRepository? notifications,
  }) : authSession = authSession ?? AuthSession.instance,
       apiClient =
           apiClient ??
           ApiClient(authSession: authSession ?? AuthSession.instance) {
    this.auth = auth ?? HttpAuthRepository(this.apiClient);
    this.profile = profile ?? HttpProfileRepository(this.apiClient);
    this.members = members ?? HttpMembersRepository(this.apiClient);
    this.events = events ?? HttpEventsRepository(this.apiClient);
    this.announcements =
        announcements ?? HttpAnnouncementsRepository(this.apiClient);
    this.finances = finances ?? HttpFinancesRepository(this.apiClient);
    this.planning = planning ?? HttpPlanningRepository(this.apiClient);
    this.notifications =
        notifications ?? HttpNotificationsRepository(this.apiClient);
  }

  static RepositoryLocator instance = RepositoryLocator();

  @visibleForTesting
  static void debugSetInstance(RepositoryLocator locator) => instance = locator;

  final AuthSession authSession;
  final ApiClient apiClient;

  late final AuthRepository auth;
  late final ProfileRepository profile;
  late final MembersRepository members;
  late final EventsRepository events;
  late final AnnouncementsRepository announcements;
  late final FinancesRepository finances;
  late final PlanningRepository planning;
  late final NotificationsRepository notifications;
}
