import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/app/app_services.dart';
import 'package:chess_platform/core/networking/api_transport.dart';
import 'package:chess_platform/features/auth/data/firebase_email_registration.dart';
import 'package:chess_platform/features/auth/presentation/account_controller.dart';
import 'package:chess_platform/features/auth/presentation/account_screen.dart';
import 'package:chess_platform/features/groups/domain/small_team_membership_repository.dart';

import 'widget_test.dart' show services;

const _password = 'FixturePassword123!';

class _User implements User {
  bool anonymous = true, mailFails = false;
  int mails = 0, forcedRefreshes = 0;
  @override
  String get uid => 'original-guest';
  @override
  bool get isAnonymous => anonymous;
  @override
  bool get emailVerified => false;
  @override
  String? get email => anonymous ? null : 'fixture@example.invalid';
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    if (forceRefresh) forcedRefreshes++;
    return 'fixture-id-token';
  }

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? settings]) async {
    mails++;
    if (mailFails) throw FirebaseAuthException(code: 'network-request-failed');
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw StateError('Unused fixture member');
}

class _Credential implements UserCredential {
  _Credential(this.user);
  @override
  final User user;
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw StateError('Unused fixture member');
}

class _Auth implements FirebaseAuth {
  final user = _User();
  int signIns = 0;
  String? language, signedInEmail, failure;
  @override
  User? get currentUser => user;
  @override
  Stream<User?> idTokenChanges() => const Stream.empty();
  @override
  Future<void> setLanguageCode(String? value) async {
    language = value;
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signIns++;
    if (failure != null) throw FirebaseAuthException(code: failure!);
    signedInEmail = email;
    user.anonymous = false;
    return _Credential(user);
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw StateError('Unused fixture member');
}

class _Transport implements ApiTransport {
  _Transport({
    this.status = 200,
    this.response = '{"localId":"original-guest"}',
  });
  final int status;
  final String response;
  int calls = 0;
  Uri? uri;
  Map<String, dynamic>? request;
  @override
  Future<ApiTransportResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    expect(method, 'POST');
    expect(headers['Content-Type'], 'application/json');
    calls++;
    this.uri = uri;
    request = jsonDecode(body!) as Map<String, dynamic>;
    return ApiTransportResponse(statusCode: status, body: response);
  }

  @override
  void close() {}
}

class _Store {
  bool offline = false;
  int writes = 0;
  Map<String, dynamic>? data;
}

// Test-only doubles for the Firebase SDK; production uses genuine references.
// ignore: subtype_of_sealed_class
class _Document implements DocumentReference<Map<String, dynamic>> {
  _Document(this.store);
  final _Store store;
  @override
  Future<void> set(Map<String, dynamic> value, [SetOptions? options]) async {
    store.writes++;
    if (store.offline) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    }
    store.data = value;
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw StateError('Unused fixture member');
}

// ignore: subtype_of_sealed_class
class _Collection implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.store);
  final _Store store;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    expect(path, 'original-guest');
    return _Document(store);
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw StateError('Unused fixture member');
}

class _Database implements FirebaseFirestore {
  final store = _Store();
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    expect(path, 'playerAccounts');
    return _Collection(store);
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw StateError('Unused fixture member');
}

class _FullTeam implements SmallTeamMembershipRepository {
  @override
  Future<void> saveAccount(String uid, Map<String, dynamic> data) async =>
      throw const TeamCapacityFailure('classroom', 'fixture-class');
  @override
  Future<int> memberCount(String scope, String communityId) async => 20;
  @override
  Future<void> leaveAll(String uid) async {}
}

AccountController _controller(
  _Auth auth,
  _Database db, {
  SmallTeamMembershipRepository? teams,
  Future<void> Function(String, String)? registration,
}) {
  final local = services();
  final account = AccountController(
    auth,
    db,
    local.profile,
    local.membership,
    teams: teams,
    registerEmail:
        registration ??
        (email, password) async {
          auth.user.anonymous = false;
        },
  );
  addTearDown(account.dispose);
  return account;
}

void main() {
  test('ID-token signUp keeps guest identity and signs in to obtain a permanent session', () async {
    final auth = _Auth(), http = _Transport();
    await FirebaseEmailRegistration(
      auth,
      transport: http,
      apiKey: 'fixture-key',
    ).link(' fixture@example.invalid ', _password);
    expect(http.uri!.host, 'identitytoolkit.googleapis.com');
    expect(http.uri!.path, '/v1/accounts:signUp');
    expect(http.request, {
      'idToken': 'fixture-id-token',
      'email': 'fixture@example.invalid',
      'password': _password,
      'returnSecureToken': true,
    });
    expect(auth.signIns, 1);
    expect(auth.signedInEmail, 'fixture@example.invalid');
    expect(auth.currentUser!.uid, 'original-guest');
    expect(auth.currentUser!.isAnonymous, isFalse);
    expect(auth.user.forcedRefreshes, 1);
  });
  test('mismatching signup UID is rejected before a session change', () async {
    final auth = _Auth();
    await expectLater(
      FirebaseEmailRegistration(
        auth,
        transport: _Transport(response: '{"localId":"different-user"}'),
        apiKey: 'fixture-key',
      ).link('fixture@example.invalid', _password),
      throwsA(
        isA<FirebaseAuthException>().having(
          (e) => e.code,
          'code',
          'user-mismatch',
        ),
      ),
    );
    expect(auth.signIns, 0);
    expect(auth.user.anonymous, isTrue);
  });
  for (final pair in {
    'EMAIL_EXISTS': 'email-already-in-use',
    'PASSWORD_DOES_NOT_MEET_REQUIREMENTS': 'weak-password',
    'OPERATION_NOT_ALLOWED': 'operation-not-allowed',
    'TOO_MANY_ATTEMPTS_TRY_LATER': 'too-many-requests',
  }.entries) {
    test(
      'server registration ${pair.key} has a specific error and does not change session',
      () async {
        final auth = _Auth();
        final http = _Transport(
          status: 400,
          response: jsonEncode({
            'error': {'message': pair.key},
          }),
        );
        await expectLater(
          FirebaseEmailRegistration(
            auth,
            transport: http,
            apiKey: 'fixture-key',
          ).link('fixture@example.invalid', _password),
          throwsA(
            isA<FirebaseAuthException>().having(
              (e) => e.code,
              'code',
              pair.value,
            ),
          ),
        );
        expect(auth.signIns, 0);
        expect(auth.user.anonymous, isTrue);
      },
    );
  }
  test('accepted registration with failed sign-in reports recovery rather than retrying account creation', () async {
    final auth = _Auth()..failure = 'network-request-failed';
    await expectLater(
      FirebaseEmailRegistration(
        auth,
        transport: _Transport(),
        apiKey: 'fixture-key',
      ).link('fixture@example.invalid', _password),
      throwsA(
        isA<FirebaseAuthException>().having(
          (e) => e.code,
          'code',
          'registration-sync-required',
        ),
      ),
    );
    final account = _controller(
      auth,
      _Database(),
      registration: (e, p) async {
        throw FirebaseAuthException(code: 'registration-sync-required');
      },
    );
    await account.register('fixture@example.invalid', _password);
    expect(account.error, contains('Kaydın oluşturuldu'));
    expect(account.error, contains('Giriş yap'));
  });
  test('profile backup failure cannot prevent the verification request; retry saves original profile', () async {
    final auth = _Auth(), db = _Database()..store.offline = true;
    final account = _controller(auth, db);
    await account.register('fixture@example.invalid', _password);
    expect(account.permanent, isTrue);
    expect(account.error, isNull);
    expect(auth.language, 'tr');
    expect(auth.user.mails, 1);
    expect(account.verificationFailed, isFalse);
    expect(account.backupNotice, contains('Profil yedeğin bekliyor'));
    db.store.offline = false;
    await account.backup();
    expect(account.backupNotice, isNull);
    expect(account.lastBackup, isNotNull);
    expect(db.store.data!['rankingEnabled'], isFalse);
  });
  test(
    'a full classroom does not undo registration or suppress verification',
    () async {
      final auth = _Auth();
      final full = _controller(auth, _Database(), teams: _FullTeam());
      await full.register('fixture@example.invalid', _password);
      expect(full.permanent, isTrue);
      expect(full.error, isNull);
      expect(auth.user.mails, 1);
      expect(full.backupNotice, contains('20 üyeyle dolu'));
    },
  );
  test('email request failure leaves account and backup ready; resend succeeds and is rate limited', () async {
    final auth = _Auth()..user.mailFails = true, db = _Database();
    final account = _controller(auth, db);
    await account.register('fixture@example.invalid', _password);
    expect(account.error, isNull);
    expect(account.permanent, isTrue);
    expect(account.lastBackup, isNotNull);
    expect(account.verificationFailed, isTrue);
    expect(account.verificationNotice, contains('Yeniden gönder'));
    auth.user.mailFails = false;
    await account.resendVerification();
    expect(auth.user.mails, 2);
    expect(account.verificationFailed, isFalse);
    await account.resendVerification();
    expect(auth.user.mails, 2);
    expect(account.verificationNotice, contains('bir dakika bekle'));
  });
  test('invalid email and password below the enforced server minimum never register', () async {
    int registrations = 0;
    final auth = _Auth(), db = _Database();
    final account = _controller(
      auth,
      db,
      registration: (e, p) async {
        registrations++;
      },
    );
    await account.register('invalid', _password);
    expect(account.error, contains('Geçerli bir e-posta'));
    await account.register('fixture@example.invalid', 'abcdefghijk');
    expect(account.error, contains('12 karakter'));
    expect(registrations, 0);
    expect(auth.user.mails, 0);
    expect(db.store.writes, 0);
  });
  test('disabled registration does not falsely blame the internet', () async {
    final account = _controller(
      _Auth(),
      _Database(),
      registration: (e, p) async {
        throw FirebaseAuthException(code: 'operation-not-allowed');
      },
    );
    await account.register('fixture@example.invalid', _password);
    expect(account.error, contains('Kayıt hizmeti'));
    expect(account.error, isNot(contains('İnternet')));
  });
  testWidgets(
    'small phone registration screen renders and saves player license successfully',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final local = services();
      final scoped = AppServices(
        theme: local.theme,
        boardAppearance: local.boardAppearance,
        challenges: local.challenges,
        whatsApp: local.whatsApp,
        profile: local.profile,
        membership: local.membership,
        safetyPreferences: local.safetyPreferences,
        gameHistory: local.gameHistory,
        gameDraft: local.gameDraft,
      );
      await tester.pumpWidget(
        AppScope(
          services: scoped,
          child: const MaterialApp(home: AccountScreen()),
        ),
      );
      expect(find.text('Oyuncu Kaydı'), findsWidgets);
      expect(find.text('Lisans Bilgilerin'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Kaydet ve Lisansımı Oluştur'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), 'Ali Veli');
      await tester.tap(find.widgetWithText(FilledButton, 'Kaydet ve Lisansımı Oluştur'));
      await tester.pumpAndSettle();
      expect(scoped.profile.profile?.displayName, 'Ali Veli');
      expect(find.text('Oyuncu lisansın başarıyla kaydedildi!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
