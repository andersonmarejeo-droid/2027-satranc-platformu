import '../../../core/networking/api_client.dart';
import '../domain/auth_repository.dart';

/// Resolves provider-issued JWT sessions against the app's own API.
///
/// The identity provider proves who signed in; the API remains responsible for
/// mapping that identity to a Chess Platform player.
class ApiAuthRepository implements AuthRepository {
  const ApiAuthRepository(this._api, this._provider);

  final ApiClient _api;
  final AuthIdentityProvider _provider;

  @override
  Stream<PlayerIdentity?> get session =>
      _provider.tokenChanges.asyncMap((token) {
        if (token == null || token.trim().isEmpty) return null;
        return _loadPlayer();
      });

  @override
  Future<void> signIn() => _provider.signIn();

  @override
  Future<void> signOut() async {
    try {
      await _api.delete('/v1/auth/session');
    } finally {
      await _provider.signOut();
    }
  }

  Future<PlayerIdentity> _loadPlayer() async {
    final response = await _api.get('/v1/auth/session');
    final rawPlayer = response['player'];
    if (rawPlayer is! Map) _throwInvalidSession();

    final id = rawPlayer['id'];
    final displayName = rawPlayer['displayName'];
    if (id is! String ||
        id.trim().isEmpty ||
        displayName is! String ||
        displayName.trim().isEmpty) {
      _throwInvalidSession();
    }
    return PlayerIdentity(id: id, displayName: displayName);
  }

  Never _throwInvalidSession() => throw const ApiFailure(
    'Sunucu geçersiz bir oturum yanıtı verdi.',
    kind: ApiFailureKind.invalidResponse,
  );
}
