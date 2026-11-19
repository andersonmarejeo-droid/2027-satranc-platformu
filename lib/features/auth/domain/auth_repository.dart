class PlayerIdentity {
  const PlayerIdentity({required this.id, required this.displayName});
  final String id, displayName;
}

abstract interface class AuthRepository {
  Stream<PlayerIdentity?> get session;
  Future<void> signIn();
  Future<void> signOut();
}

/// Provider boundary for a short-lived JWT accepted by the Chess Platform API.
/// Implementations may use Firebase Auth, Google Sign-In, or another identity
/// service without exposing that choice to the domain layer.
abstract interface class AuthIdentityProvider {
  Stream<String?> get tokenChanges;
  Future<String?> getAccessToken();
  Future<void> signIn();
  Future<void> signOut();
}
