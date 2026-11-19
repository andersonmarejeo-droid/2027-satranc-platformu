class ClockSnapshot {
  const ClockSnapshot({
    required this.whiteMilliseconds,
    required this.blackMilliseconds,
    required this.activeWhite,
  });
  final int whiteMilliseconds, blackMilliseconds;
  final bool activeWhite;

  Map<String, Object> toJson() => {
    'whiteMilliseconds': whiteMilliseconds,
    'blackMilliseconds': blackMilliseconds,
    'activeWhite': activeWhite,
  };

  factory ClockSnapshot.fromJson(Map<String, dynamic> json) {
    final white = json['whiteMilliseconds'] as int;
    final black = json['blackMilliseconds'] as int;
    if (white < 0 || black < 0 || white > 1000000000 || black > 1000000000) {
      throw const FormatException('Invalid clock duration');
    }
    return ClockSnapshot(
      whiteMilliseconds: white,
      blackMilliseconds: black,
      activeWhite: json['activeWhite'] as bool,
    );
  }
}

class ClockState {
  ClockState({
    required this.position,
    required this.flagged,
    required this.endedByRules,
    required List<ClockSnapshot> undo,
  }) : undo = List.unmodifiable(undo);
  final ClockSnapshot position;
  final bool flagged, endedByRules;
  final List<ClockSnapshot> undo;

  Map<String, Object> toJson() => {
    'position': position.toJson(),
    'flagged': flagged,
    'endedByRules': endedByRules,
    'undo': undo.map((snapshot) => snapshot.toJson()).toList(),
  };

  factory ClockState.fromJson(Map<String, dynamic> json) {
    final snapshots = json['undo'] as List;
    if (snapshots.length > 2048) {
      throw const FormatException('Invalid clock history');
    }
    final position = ClockSnapshot.fromJson(
      json['position'] as Map<String, dynamic>,
    );
    final flagged = json['flagged'] as bool;
    final endedByRules = json['endedByRules'] as bool;
    if (flagged &&
        (endedByRules ||
            (position.activeWhite
                    ? position.whiteMilliseconds
                    : position.blackMilliseconds) !=
                0)) {
      throw const FormatException('Invalid expired clock');
    }
    return ClockState(
      position: position,
      flagged: flagged,
      endedByRules: endedByRules,
      undo: snapshots
          .map((value) => ClockSnapshot.fromJson(value as Map<String, dynamic>))
          .toList(),
    );
  }
}
