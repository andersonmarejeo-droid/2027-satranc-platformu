import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/computer_difficulty.dart';
import '../domain/saved_game.dart';
import '../domain/time_control.dart';

enum QuickPlayMode { computer, online, twoPlayers }

class QuickPlayChoice {
  const QuickPlayChoice({
    this.mode = QuickPlayMode.computer,
    this.time = const TimeControl(10, 0),
    this.clockEnabled = false,
    this.difficulty = ComputerDifficulty.easy,
    this.side = PlayerSideChoice.white,
  });
  final QuickPlayMode mode;
  final TimeControl time;
  final bool clockEnabled;
  final ComputerDifficulty difficulty;
  final PlayerSideChoice side;
  String get label => switch (mode) {
    QuickPlayMode.computer => 'Bilgisayar · ${difficulty.label}',
    QuickPlayMode.online => 'Çevrim içi',
    QuickPlayMode.twoPlayers => 'İki kişi',
  };
  String get description =>
      '$label · ${clockEnabled ? time.plainLabel : 'Süresiz'}';
  String get route => mode == QuickPlayMode.online
      ? '/matchmaking?minutes=${time.minutes}&increment=${time.incrementSeconds}&start=1'
      : '/game?minutes=${time.minutes}&increment=${time.incrementSeconds}&clock=${clockEnabled ? 'on' : 'off'}&opponent=${mode == QuickPlayMode.computer ? 'computer' : 'twoPlayers'}&difficulty=${difficulty.name}${mode == QuickPlayMode.computer && side == PlayerSideChoice.black ? '&playerColor=black' : ''}';
  Map<String, Object> toJson() => {
    'durationSelectionVersion': 2,
    'mode': mode.name,
    'minutes': time.minutes,
    'increment': time.incrementSeconds,
    'clock': clockEnabled,
    'difficulty': difficulty.name,
    'side': side.name,
  };
  factory QuickPlayChoice.fromJson(Map<String, dynamic> json) {
    final mode = QuickPlayMode.values.byName(json['mode'] as String);
    final minutes = json['minutes'] as int,
        increment = json['increment'] as int;
    if (minutes < 1 ||
        minutes > TimeControl.maxMinutes ||
        increment < 0 ||
        increment > 60) {
      throw const FormatException('Invalid quick play');
    }
    return QuickPlayChoice(
      mode: mode,
      time: json['durationSelectionVersion'] != 2 && minutes < 10
          ? const TimeControl(10, 0)
          : TimeControl(minutes, increment),
      clockEnabled: mode == QuickPlayMode.online || json['clock'] == true,
      difficulty: ComputerDifficulty.values.byName(
        json['difficulty'] as String,
      ),
      side: PlayerSideChoice.values
              .where((value) => value.name == json['side'])
              .firstOrNull ??
          PlayerSideChoice.white,
    );
  }
}

class QuickPlayController extends ChangeNotifier {
  QuickPlayController({required this.read, required this.write});
  factory QuickPlayController.preferences(SharedPreferencesAsync prefs) =>
      QuickPlayController(
        read: () => prefs.getString('quickPlay.v1'),
        write: (value) => prefs.setString('quickPlay.v1', value),
      );
  final Future<String?> Function() read;
  final Future<void> Function(String) write;
  QuickPlayChoice value = const QuickPlayChoice();
  Future<void> load() async {
    try {
      final raw = await read();
      if (raw != null) {
        value = QuickPlayChoice.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      value = const QuickPlayChoice();
    }
    notifyListeners();
  }

  Future<void> save(QuickPlayChoice next) async {
    await write(jsonEncode(next.toJson()));
    value = next;
    notifyListeners();
  }
}
