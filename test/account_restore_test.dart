import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/features/auth/presentation/account_controller.dart';
import 'package:chess_platform/features/profile/domain/community_membership.dart';

import 'widget_test.dart' show services;

class _AccountUser implements User {
  @override
  String get uid => 'account-fixture';
  @override
  bool get isAnonymous => false;
  @override
  bool get emailVerified => true;
  @override
  String? get email => 'fixture@example.invalid';
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unused fixture member');
}

class _AccountAuth implements FirebaseAuth {
  @override
  User? get currentUser => _AccountUser();
  @override
  Stream<User?> idTokenChanges() => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unused fixture member');
}

// Test-only SDK double: production always uses the real Firebase references.
// ignore: subtype_of_sealed_class
class _AccountSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _AccountSnapshot(this.value);
  final Map<String, dynamic>? value;
  @override
  Map<String, dynamic>? data() => value;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unused fixture member');
}

class _AccountStore {
  bool offline = true;
  int writes = 0;
  final stored = <String, dynamic>{
    'displayName': 'Bulut oyuncusu',
    'membership': CommunityMembership()
        .select(CommunityKind.country, 'tr')
        .select(CommunityKind.city, 'giresun')
        .select(CommunityKind.school, 'gfl')
        .select(CommunityKind.classroom, 'gfl-9a')
        .toJson(),
    'rankingEnabled': true,
  };
}

// ignore: subtype_of_sealed_class
class _AccountDocument implements DocumentReference<Map<String, dynamic>> {
  _AccountDocument(this.store);
  final _AccountStore store;
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    if (store.offline) {
      throw StateError('Fixture offline');
    }
    return _AccountSnapshot(store.stored);
  }

  @override
  Future<void> set(Map<String, dynamic> value, [SetOptions? options]) async {
    store.writes++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unused fixture member');
}

// ignore: subtype_of_sealed_class
class _AccountCollection implements CollectionReference<Map<String, dynamic>> {
  _AccountCollection(this.value);
  final _AccountDocument value;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => value;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unused fixture member');
}

class _AccountDatabase implements FirebaseFirestore {
  final account = _AccountStore();
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _AccountCollection(_AccountDocument(account));
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unused fixture member');
}

void main() {
  test('failed account restore cannot overwrite the remote profile; retry restores school and rank choice', () async {
    final local = services(), db = _AccountDatabase();
    final account = AccountController(
      _AccountAuth(),
      db,
      local.profile,
      local.membership,
    );
    addTearDown(account.dispose);
    await expectLater(account.restoreOrBackup(), throwsStateError);
    expect(account.restorePending, isTrue);
    expect(local.profile.profile!.displayName, 'Misafir oyuncu');
    await local.profile.saveDisplayName('Yerel seçim');
    await expectLater(account.backup(), throwsStateError);
    expect(db.account.writes, 0);
    db.account.offline = false;
    await account.retryRestore();
    expect(account.error, isNull);
    expect(account.restorePending, isFalse);
    expect(local.profile.profile!.displayName, 'Bulut oyuncusu');
    expect(local.membership.value.classId, 'gfl-9a');
    expect(account.rankingEnabled, isTrue);
    await account.backup();
    expect(db.account.writes, 1);
  });
  test(
    'ranking cleanup state is restored and blocks turning ranking back on',
    () async {
      final local = services(), db = _AccountDatabase();
      db.account.offline = false;
      db.account.stored['rankingEnabled'] = false;
      db.account.stored['rankingCleanupPending'] = true;
      final account = AccountController(
        _AccountAuth(),
        db,
        local.profile,
        local.membership,
      );
      addTearDown(account.dispose);
      await account.restoreOrBackup();
      expect(account.removalPending, isTrue);
      await account.setRanking(true);
      expect(account.rankingEnabled, isFalse);
      expect(account.error, contains('temizliğini tamamla'));
      expect(db.account.writes, 0);
    },
  );
}
