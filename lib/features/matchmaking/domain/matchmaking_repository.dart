import '../../game/domain/time_control.dart';

enum QueueStatus { idle, searching, matched, cancelled, expired }

class MatchTicket {
  const MatchTicket(this.id, this.status, {this.matchId});
  final String id;
  final QueueStatus status;
  final String? matchId;
}

abstract interface class MatchmakingRepository {
  Stream<MatchTicket> watch(String ticketId);
  Future<MatchTicket> join(TimeControl timeControl);
  Future<void> cancel(String ticketId);
}
