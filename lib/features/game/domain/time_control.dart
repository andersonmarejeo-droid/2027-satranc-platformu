class TimeControl {
  const TimeControl(this.minutes, this.incrementSeconds);
  final int minutes;
  final int incrementSeconds;
  static const maxMinutes = 120;
  String get label => '$minutes + $incrementSeconds';
  String get plainLabel => '$minutes dakika';
  String get bonusLabel => incrementSeconds == 0
      ? 'Hamle sonrası ek süre yok'
      : 'Her hamleden sonra $incrementSeconds saniye eklenir';
  String get description =>
      'Her oyuncuya bütün oyun için $minutes dakika. $bonusLabel.';
  // FIDE's categories count the starting time plus 60 move increments.
  String get category => minutes + incrementSeconds <= 10
      ? 'Blitz'
      : minutes + incrementSeconds < 60
      ? 'Rapid'
      : 'Classical';
  static const shorterPresets = [
    TimeControl(1, 0),
    TimeControl(2, 0),
    TimeControl(3, 0),
    TimeControl(5, 0),
  ];
  static const presets = [
    TimeControl(10, 0),
    TimeControl(15, 0),
    TimeControl(30, 0),
    TimeControl(60, 0),
  ];
  static const longerPresets = [TimeControl(90, 0), TimeControl(120, 0)];
  static const tournamentPresets = [
    TimeControl(3, 2),
    TimeControl(15, 10),
    TimeControl(90, 30),
  ];
  static TimeControl fromQuery(Map<String, String> query) {
    final minutes = int.tryParse(query['minutes'] ?? '') ?? 10;
    final increment = int.tryParse(query['increment'] ?? '') ?? 0;
    return TimeControl(minutes.clamp(1, maxMinutes), increment.clamp(0, 60));
  }
}
