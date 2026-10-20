import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'auth_session.dart';
import 'repositories/auth_repository.dart';
import 'repositories/http/http_auth_repository.dart';
import 'repositories/http/http_profile_repository.dart';
import 'repositories/profile_repository.dart';

/// Screens depend on repository interfaces, never on [ApiClient]; tests
/// swap in fakes with [debugSetInstance].
class RepositoryLocator {
  RepositoryLocator({AuthSession? authSession, ApiClient? apiClient, AuthRepository? auth, ProfileRepository? profile})
      : authSession = authSession ?? AuthSession.instance,
        apiClient = apiClient ?? ApiClient(authSession: authSession ?? AuthSession.instance) {
    this.auth = auth ?? HttpAuthRepository(this.apiClient);
    this.profile = profile ?? HttpProfileRepository(this.apiClient);
  }

  static RepositoryLocator instance = RepositoryLocator();

  @visibleForTesting
  static void debugSetInstance(RepositoryLocator locator) => instance = locator;

  final AuthSession authSession;
  final ApiClient apiClient;

  late final AuthRepository auth;
  late final ProfileRepository profile;
}
