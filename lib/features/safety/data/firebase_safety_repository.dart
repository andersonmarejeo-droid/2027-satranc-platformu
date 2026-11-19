import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/safety_repository.dart';

/// Firestore adapter for the small, explicit safety actions exposed by match
/// screens. Reports are append-only for players; only the moderation backend
/// may read their queue.
class FirebaseSafetyRepository implements SafetyRepository {
  FirebaseSafetyRepository(this.auth, this.db);

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final _random = Random.secure();

  Future<String> _uid() async {
    final current = auth.currentUser;
    if (current != null) return current.uid;
    return (await auth.signInAnonymously()).user!.uid;
  }

  String _id() => List.generate(
    20,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  @override
  Future<void> blockPlayer(String playerId) async {
    final uid = await _uid();
    if (playerId.isEmpty || playerId == uid) {
      throw ArgumentError('Geçersiz oyuncu.');
    }
    await db.collection('blockedPlayers').doc('${uid}_$playerId').set({
      'owner': uid,
      'blockedPlayer': playerId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> reportPlayer({
    required String playerId,
    required String reason,
    String? matchId,
  }) async {
    final uid = await _uid();
    if (playerId.isEmpty || playerId == uid || reason.length > 80) {
      throw ArgumentError('Bildirim alanları geçersiz.');
    }
    await db.collection('safetyReports').doc(_id()).set({
      'reporter': uid,
      'reportedPlayer': playerId,
      'reason': reason.trim(),
      'matchId': matchId?.trim() ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'open',
    });
  }
}
