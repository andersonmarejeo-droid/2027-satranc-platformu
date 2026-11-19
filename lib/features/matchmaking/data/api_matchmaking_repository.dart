import 'dart:async';

import '../../../core/networking/api_client.dart';
import '../../game/domain/time_control.dart';
import '../domain/matchmaking_repository.dart';

/// REST polling adapter for the authenticated ticket lifecycle.
/// A live WebSocket stream can replace polling without changing the domain API.
class ApiMatchmakingRepository implements MatchmakingRepository {
  const ApiMatchmakingRepository(
    this._api, {
    this.pollInterval = const Duration(seconds: 2),
  });

  final ApiClient _api;
  final Duration pollInterval;
  static final _validTicketId = RegExp(r'^[A-Za-z0-9._~-]{1,80}$');

  @override
  Future<MatchTicket> join(TimeControl timeControl) async {
    final response = await _api.post('/v1/matchmaking', {
      'timeControl': {
        'initialSeconds': timeControl.minutes * 60,
        'incrementSeconds': timeControl.incrementSeconds,
      },
    });
    return _parseTicket(response);
  }

  @override
  Stream<MatchTicket> watch(String ticketId) async* {
    if (!_validTicketId.hasMatch(ticketId)) {
      throw const ApiFailure(
        'Eşleşme bileti geçersiz.',
        kind: ApiFailureKind.configuration,
      );
    }
    while (true) {
      final ticket = await _fetch(ticketId);
      yield ticket;
      if (ticket.status != QueueStatus.searching) return;
      await Future<void>.delayed(pollInterval);
    }
  }

  @override
  Future<void> cancel(String ticketId) async {
    if (!_validTicketId.hasMatch(ticketId)) {
      throw const ApiFailure(
        'Eşleşme bileti geçersiz.',
        kind: ApiFailureKind.configuration,
      );
    }
    await _api.delete('/v1/matchmaking/${Uri.encodeComponent(ticketId)}');
  }

  Future<MatchTicket> _fetch(String ticketId) async => _parseTicket(
    await _api.get('/v1/matchmaking/${Uri.encodeComponent(ticketId)}'),
  );

  MatchTicket _parseTicket(Map<String, Object?> response) {
    try {
      final id = response['id'];
      final rawStatus = response['status'];
      final rawMatchId = response['matchId'];
      if (id is! String ||
          !_validTicketId.hasMatch(id) ||
          rawStatus is! String ||
          (rawMatchId != null && rawMatchId is! String)) {
        throw const FormatException('Invalid ticket fields.');
      }
      final status = switch (rawStatus) {
        'searching' => QueueStatus.searching,
        'matched' => QueueStatus.matched,
        'cancelled' => QueueStatus.cancelled,
        'expired' => QueueStatus.expired,
        _ => throw const FormatException('Unknown ticket status.'),
      };
      if (status == QueueStatus.matched && rawMatchId is! String) {
        throw const FormatException('Matched ticket has no match ID.');
      }
      return MatchTicket(id, status, matchId: rawMatchId as String?);
    } on FormatException {
      throw const ApiFailure(
        'Sunucu geçersiz bir eşleşme yanıtı verdi.',
        kind: ApiFailureKind.invalidResponse,
      );
    }
  }
}
