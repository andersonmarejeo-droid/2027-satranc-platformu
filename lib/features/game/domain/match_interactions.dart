import 'match_snapshot.dart';

enum QuickMessageCode {
  congratulations('Tebrikler!'),
  wellPlayed('İyi oynadın!'),
  goodGame('Güzel oyundu.'),
  thanks('Teşekkürler!');

  const QuickMessageCode(this.label);
  final String label;
}

class MatchQuickMessage {
  const MatchQuickMessage({
    required this.senderId,
    required this.code,
    required this.sentAt,
  });
  final String senderId;
  final QuickMessageCode code;
  final DateTime sentAt;
}

class MatchInteractions {
  const MatchInteractions({
    this.drawOfferedBy,
    this.drawOfferPly,
    this.drawAccepted = false,
    this.resignedBy,
    this.rematchOfferedBy,
    this.rematchInviteId,
    this.rematchMatchId,
    this.messages = const [],
  });
  final String? drawOfferedBy;
  final int? drawOfferPly;
  final bool drawAccepted;
  final String? resignedBy;
  final String? rematchOfferedBy;
  final String? rematchInviteId;
  final String? rematchMatchId;
  final List<MatchQuickMessage> messages;
}

/// Participant-only actions. Message content is a fixed, translated enum.
abstract interface class MatchSocialRepository {
  String? get playerId;
  Future<MatchSnapshot> offerDraw(String matchId);
  Future<MatchSnapshot> respondToDraw(String matchId, {required bool accept});
  Future<MatchSnapshot> resign(String matchId);
  Future<MatchSnapshot> requestRematch(String matchId);
  Future<String> acceptRematch(String matchId);
  Future<MatchSnapshot> sendQuickMessage(String matchId, QuickMessageCode code);
}
