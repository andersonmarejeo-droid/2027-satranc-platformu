import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/board_appearance.dart';

class LocalBoardAppearanceRepository implements BoardAppearanceRepository {
  LocalBoardAppearanceRepository({required this.read, required this.write});
  factory LocalBoardAppearanceRepository.preferences(
    SharedPreferencesAsync prefs,
  ) => LocalBoardAppearanceRepository(
    read: () => prefs.getString('appearance.board.v1'),
    write: (value) => prefs.setString('appearance.board.v1', value),
  );
  final Future<String?> Function() read;
  final Future<void> Function(String) write;

  @override
  Future<BoardAppearance> load() async {
    final stored = await read();
    if (stored == null) return const BoardAppearance();
    try {
      return BoardAppearance.fromJson(
        jsonDecode(stored) as Map<String, dynamic>,
      );
    } on FormatException {
      return const BoardAppearance();
    } on TypeError {
      return const BoardAppearance();
    }
  }

  @override
  Future<void> save(BoardAppearance appearance) =>
      write(jsonEncode(appearance.toJson()));
}
