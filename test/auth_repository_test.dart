import 'dart:async';

import 'package:chess_platform/core/networking/api_client.dart';
import 'package:chess_platform/features/auth/data/api_auth_repository.dart';
import 'package:chess_platform/features/auth/domain/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'resolves provider token changes through the app session endpoint',
    () async {
      final provider = FakeAuthIdentityProvider();
      addTearDown(provider.dispose);
      final api = FakeApiClient({
        'player': {'id': 'player-1', 'displayName': 'Deniz'},
      });
      final repository = ApiAuthRepository(api, provider);
      final session = repository.session.first;

      provider.emit('provider-jwt');

      final player = await session;
      expect(player?.id, 'player-1');
      expect(player?.displayName, 'Deniz');
      expect(api.getPaths, ['/v1/auth/session']);
      expect(provider.lastRequestedToken, 'provider-jwt');
    },
  );

  test(
    'a missing provider token remains signed out without an API request',
    () async {
      final provider = FakeAuthIdentityProvider();
      addTearDown(provider.dispose);
      final api = FakeApiClient(const {});
      final repository = ApiAuthRepository(api, provider);
      final session = repository.session.first;

      provider.emit(null);

      expect(await session, isNull);
      expect(api.getPaths, isEmpty);
    },
  );

  test(
    'sign-in and sign-out are delegated to the provider and server',
    () async {
      final provider = FakeAuthIdentityProvider();
      addTearDown(provider.dispose);
      final api = FakeApiClient(const {});
      final repository = ApiAuthRepository(api, provider);

      await repository.signIn();
      await repository.signOut();

      expect(provider.signInCalls, 1);
      expect(provider.signOutCalls, 1);
      expect(api.deletedPaths, ['/v1/auth/session']);
    },
  );
}

class FakeAuthIdentityProvider implements AuthIdentityProvider {
  final _tokens = StreamController<String?>.broadcast();
  String? lastRequestedToken;
  int signInCalls = 0;
  int signOutCalls = 0;

  @override
  Stream<String?> get tokenChanges => _tokens.stream;

  @override
  Future<String?> getAccessToken() async => lastRequestedToken;

  void emit(String? token) {
    lastRequestedToken = token;
    _tokens.add(token);
  }

  Future<void> dispose() => _tokens.close();

  @override
  Future<void> signIn() async => signInCalls++;

  @override
  Future<void> signOut() async => signOutCalls++;
}

class FakeApiClient implements ApiClient {
  FakeApiClient(this.response);

  final Map<String, Object?> response;
  final getPaths = <String>[];
  final deletedPaths = <String>[];

  @override
  Future<Map<String, Object?>> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    getPaths.add(path);
    return response;
  }

  @override
  Future<Map<String, Object?>> delete(String path) async {
    deletedPaths.add(path);
    return const {};
  }

  @override
  Future<Map<String, Object?>> post(
    String path,
    Map<String, Object?> body, {
    Map<String, String>? headers,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, Object?>> put(String path, Map<String, Object?> body) =>
      throw UnimplementedError();
}
