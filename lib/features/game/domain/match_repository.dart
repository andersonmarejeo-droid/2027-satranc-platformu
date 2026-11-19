import 'match_snapshot.dart';
import 'match_stream_event.dart';

abstract interface class MatchRepository {
  Future<MatchSnapshot> fetch(String matchId);

  Future<MatchSnapshot> submitMove(
    String matchId, {
    required int expectedPly,
    required String uci,
  });

  Future<MatchStreamTicket> createStreamTicket(String matchId);

  Stream<MatchStreamEvent> watchEvents(
    String matchId, {
    required int afterSequence,
  });
}

/// Marker for repositories whose [MatchRepository.watchEvents] delivers live
/// server snapshots without requiring periodic polling.
abstract interface class RealtimeMatchRepository {}
