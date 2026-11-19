import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/small_team_membership_repository.dart';

class FirebaseSmallTeamRepository implements SmallTeamMembershipRepository {
  FirebaseSmallTeamRepository(this.db);
  final FirebaseFirestore db;
  DocumentReference<Map<String, dynamic>> _team(String key) =>
      db.collection('smallTeams').doc(key);
  DocumentReference<Map<String, dynamic>> _member(String key, String uid) =>
      db.collection('smallTeamMembers').doc('${key}_$uid');
  Map<String, (String, String)> _teams(Map<String, dynamic> account) {
    final membership = Map<String, dynamic>.from(account['membership'] as Map);
    return {
      if (membership['classId'] case final String id when id.isNotEmpty)
        'classroom_$id': ('classroom', id),
      for (final id in (membership['groupIds'] as List).cast<String>())
        'group_$id': ('group', id),
    };
  }

  @override
  Future<int> memberCount(String scope, String communityId) async {
    final d = await _team('${scope}_$communityId')
        .get(const GetOptions(source: Source.server));
    return (d.data()?['count'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> saveAccount(String uid, Map<String, dynamic> account) async {
    try {
      await _saveAccount(uid, account);
    } on FirebaseException catch (e) {
      // A competing reservation can reach the rules before the SDK retries its
      // transaction. Resolve that rejection to the same clear capacity message.
      if (e.code == 'permission-denied') {
        for (final entry in _teams(account).entries) {
          try {
            final member = await _member(entry.key, uid)
                .get(const GetOptions(source: Source.server))
                .timeout(const Duration(seconds: 8));
            final count = await memberCount(
              entry.value.$1,
              entry.value.$2,
            ).timeout(const Duration(seconds: 8));
            if (!member.exists && count >= SmallTeamPolicy.maxMembers) {
              throw TeamCapacityFailure(entry.value.$1, entry.value.$2);
            }
          } on TeamCapacityFailure {
            rethrow;
          } catch (_) {
            // Preserve the original denial when the server cannot be checked.
          }
        }
      }
      rethrow;
    }
  }

  Future<void> _saveAccount(String uid, Map<String, dynamic> account) async {
    await db.runTransaction((tx) async {
      final accountRef = db.collection('playerAccounts').doc(uid);
      final old = (await tx.get(accountRef)).data();
      final target = _teams(account);
      final previous = old == null ? <String, (String, String)>{} : _teams(old);
      final affected = {...previous, ...target};
      final changes = <(String, String, String, bool, int)>[];
      for (final entry in affected.entries) {
        final team = (await tx.get(_team(entry.key))).data();
        final member = await tx.get(_member(entry.key, uid));
        final count = (team?['count'] as num?)?.toInt() ?? 0;
        final joining = target.containsKey(entry.key);
        if (joining && member.exists) continue;
        if (!joining && !member.exists) continue;
        if (joining && count >= SmallTeamPolicy.maxMembers) {
          throw TeamCapacityFailure(entry.value.$1, entry.value.$2);
        }
        if (!joining && (team == null || count <= 0)) {
          throw StateError('Invalid team counter');
        }
        changes.add((
          entry.key,
          entry.value.$1,
          entry.value.$2,
          joining,
          count,
        ));
      }
      if (changes.length > SmallTeamPolicy.maxChangesPerTransaction) {
        throw StateError('Too many team changes');
      }
      for (final (key, scope, id, joining, count) in changes) {
        tx.set(_team(key), {
          'scope': scope,
          'communityId': id,
          'count': count + (joining ? 1 : -1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (joining) {
          tx.set(_member(key, uid), {
            'uid': uid,
            'scope': scope,
            'communityId': id,
            'joinedAt': FieldValue.serverTimestamp(),
          });
        } else {
          tx.delete(_member(key, uid));
        }
      }
      tx.set(accountRef, account);
    });
  }

  @override
  Future<void> leaveAll(String uid) async {
    final ref = db.collection('playerAccounts').doc(uid);
    var data = (await ref.get(const GetOptions(source: Source.server))).data();
    if (data == null) return;
    while (true) {
      final m = Map<String, dynamic>.from(data!['membership'] as Map);
      final groups = (m['groupIds'] as List).cast<String>();
      if (m['classId'] == null && groups.isEmpty) break;
      final budget =
          SmallTeamPolicy.maxChangesPerTransaction -
          (m['classId'] == null ? 0 : 1);
      m['classId'] = null;
      m['groupIds'] = groups.skip(budget).toList();
      data = {
        ...data,
        'membership': m,
        'rankingEnabled': false,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await saveAccount(uid, data);
    }
  }
}
