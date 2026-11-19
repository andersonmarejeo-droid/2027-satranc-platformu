import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../game/domain/time_control.dart';
import '../domain/challenge_invite.dart';
import '../domain/challenge_repository.dart';

class LocalChallengeRepository implements ChallengeRepository {
  LocalChallengeRepository(this.preferences);
  final SharedPreferencesAsync preferences;

  @override
  bool get isLocalDemo => true;

  @override
  Future<ChallengeInvite> create(TimeControl timeControl) async {
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final invite = ChallengeInvite(
      id: id,
      timeControl: timeControl,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
    final ids = await preferences.getStringList('challenge.ids') ?? [];
    while (ids.length >= 20) {
      await preferences.remove('challenge.${ids.removeAt(0)}');
    }
    await preferences.setString('challenge.$id', jsonEncode(invite.toJson()));
    await preferences.setStringList('challenge.ids', [...ids, id]);
    return invite;
  }

  @override
  Future<ChallengeInvite?> find(String id) async {
    if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(id)) return null;
    final stored = await preferences.getString('challenge.$id');
    if (stored == null) return null;
    try {
      return ChallengeInvite.fromJson(
        jsonDecode(stored) as Map<String, dynamic>,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
