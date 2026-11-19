import '../../game/domain/time_control.dart';
import '../../game/domain/online_match_timing.dart';

class ChallengeInvite {
  const ChallengeInvite({
    required this.id,
    required this.timeControl,
    required this.expiresAt,
    this.publicUrl,
    this.turnLimitSeconds = 0,
  });
  final String id;
  final TimeControl timeControl;
  final DateTime expiresAt;
  final int turnLimitSeconds;
  String get turnRule =>
      turnLimitSeconds == OnlineMatchTiming.defaultTurnLimitSeconds
      ? '\n${OnlineMatchTiming.ruleDescription}'
      : '';

  /// HTTPS link returned by the challenge server, absent for local demo invites.
  final Uri? publicUrl;

  bool get isLocalDemo => publicUrl == null;
  Uri get shareLink => publicUrl ?? demoLink;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Uri get demoLink => Uri(scheme: 'chessplatform', path: '/challenge/$id');
  String get shareText => isLocalDemo
      ? 'Satrançta bir hamleye var mısın? ${timeControl.description}\n$shareLink\nBu bir deneme davetidir; çevrim içi maç henüz etkin değil. Davet yalnızca oluşturulduğu kurulumda açılır.'
      : 'Satrançta bir hamleye var mısın? ${timeControl.description}$turnRule\n$shareLink\nDavet, süre sonuna kadar bağlantıyı açan oyuncular tarafından kullanılabilir.';
  Map<String, Object?> toJson() => {
    'id': id,
    'minutes': timeControl.minutes,
    'increment': timeControl.incrementSeconds,
    'turnLimitSeconds': turnLimitSeconds,
    'expiresAt': expiresAt.toIso8601String(),
    if (publicUrl != null) 'publicUrl': publicUrl.toString(),
  };
  factory ChallengeInvite.fromJson(Map<String, dynamic> json) =>
      ChallengeInvite(
        id: json['id'] as String,
        timeControl: TimeControl(
          json['minutes'] as int,
          json['increment'] as int,
        ),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        turnLimitSeconds: json['turnLimitSeconds'] as int? ?? 0,
        publicUrl: json['publicUrl'] == null
            ? null
            : Uri.parse(json['publicUrl'] as String),
      );
}
