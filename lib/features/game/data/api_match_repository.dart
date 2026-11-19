import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;

import '../../../core/networking/api_client.dart';
import '../domain/match_repository.dart';
import '../domain/match_snapshot.dart';
import '../domain/match_stream_event.dart';
import 'match_socket.dart';
import 'match_socket_connector.dart';

/// REST adapter for server-authoritative match state and move submission.
class ApiMatchRepository implements MatchRepository {
  ApiMatchRepository(
    this._api, {
    required String baseUrl,
    MatchSocketConnector? socketConnector,
    Random? secureRandom,
  }) : _random = secureRandom ?? Random.secure(),
       _baseUri = _normalizedBaseUri(baseUrl),
       _socketConnector = socketConnector ?? createMatchSocketConnector();

  final ApiClient _api;
  final Random _random;
  final Uri _baseUri;
  final MatchSocketConnector _socketConnector;
  static final _uciPattern = RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$');

  @override
  Future<MatchSnapshot> fetch(String matchId) async => _parseMatch(
    await _api.get('/v1/matches/${Uri.encodeComponent(_matchId(matchId))}'),
  );

  @override
  Future<MatchSnapshot> submitMove(
    String matchId, {
    required int expectedPly,
    required String uci,
  }) async {
    if (expectedPly < 0 || !_uciPattern.hasMatch(uci)) {
      throw const ApiFailure(
        'Hamle bilgisi geçersiz.',
        kind: ApiFailureKind.configuration,
      );
    }
    return _parseMatch(
      await _api.post(
        '/v1/matches/${Uri.encodeComponent(_matchId(matchId))}/moves',
        {'expectedPly': expectedPly, 'uci': uci},
        headers: {'Idempotency-Key': _newIdempotencyKey()},
      ),
    );
  }

  @override
  Future<MatchStreamTicket> createStreamTicket(String matchId) async {
    final response = await _api.post(
      '/v1/matches/${Uri.encodeComponent(_matchId(matchId))}/stream-ticket',
      const <String, Object?>{},
    );
    try {
      final value = response['ticket'];
      final expiresAt = _date(response['expiresAt']);
      if (value is! String || value.length < 32 || value.length > 512) {
        throw const FormatException('Invalid stream ticket.');
      }
      return MatchStreamTicket(value: value, expiresAt: expiresAt);
    } on FormatException {
      throw _invalidResponse();
    }
  }

  @override
  Stream<MatchStreamEvent> watchEvents(
    String matchId, {
    required int afterSequence,
  }) async* {
    final safeMatchId = _matchId(matchId);
    var lastSequence = afterSequence < 0 ? 0 : afterSequence;
    var retrySeconds = 1;
    while (true) {
      MatchSocket? socket;
      try {
        final ticket = await createStreamTicket(safeMatchId);
        socket = await _socketConnector.connect(
          _streamUri(safeMatchId, ticket.value),
        );
        socket.sendText(
          jsonEncode({'type': 'match.sync', 'lastSequence': lastSequence}),
        );
        await for (final frame in socket.messages) {
          final event = _parseEvent(frame, safeMatchId);
          if (event.sequence <= lastSequence) continue;
          lastSequence = event.sequence;
          retrySeconds = 1;
          yield event;
        }
      } on ApiFailure catch (failure) {
        if (!failure.retryable) rethrow;
      } on FormatException {
        rethrow;
      } catch (_) {
        // A dropped socket gets a fresh single-use ticket on the next attempt.
      } finally {
        try {
          await socket?.close();
        } catch (_) {
          // The failed connection is already unusable.
        }
      }
      await Future<void>.delayed(Duration(seconds: retrySeconds));
      retrySeconds = retrySeconds >= 8 ? 16 : retrySeconds * 2;
    }
  }

  Uri _streamUri(String matchId, String ticket) {
    final websocketScheme = _baseUri.scheme == 'https' ? 'wss' : 'ws';
    final matchPath = 'v1/matches/${Uri.encodeComponent(matchId)}/stream';
    return _baseUri
        .resolve(matchPath)
        .replace(scheme: websocketScheme, queryParameters: {'ticket': ticket});
  }

  static Uri _normalizedBaseUri(String value) {
    final uri = Uri.parse(value.trim());
    return uri.replace(
      path: uri.path.endsWith('/') ? uri.path : '${uri.path}/',
    );
  }

  MatchStreamEvent _parseEvent(Object? frame, String expectedMatchId) {
    Object? decoded;
    if (frame is String) {
      decoded = jsonDecode(frame);
    } else if (frame is List<int>) {
      decoded = jsonDecode(utf8.decode(frame));
    } else {
      throw const FormatException('Unsupported match event frame.');
    }
    if (decoded is! Map) {
      throw const FormatException('Expected a match event object.');
    }
    final event = <String, Object?>{
      for (final entry in decoded.entries) entry.key.toString(): entry.value,
    };
    final type = event['type'];
    final matchId = event['matchId'];
    final sequence = event['sequence'];
    final serverTime = event['serverTime'];
    if (type is! String ||
        type.isEmpty ||
        type.length > 64 ||
        matchId is! String ||
        matchId != expectedMatchId ||
        sequence is! int ||
        sequence < 1 ||
        serverTime is! String) {
      throw const FormatException('Invalid match event envelope.');
    }
    return MatchStreamEvent(
      type: type,
      matchId: matchId,
      sequence: sequence,
      serverTime: DateTime.parse(serverTime).toUtc(),
      payload: event,
    );
  }

  String _newIdempotencyKey() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  String _matchId(String value) {
    if (value.trim().isEmpty ||
        value != value.trim() ||
        value.length > 80 ||
        value.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
      throw const ApiFailure(
        'Maç numarası geçersiz.',
        kind: ApiFailureKind.configuration,
      );
    }
    return value;
  }

  MatchSnapshot _parseMatch(Map<String, Object?> value) {
    try {
      final id = value['id'];
      final status = switch (value['status']) {
        'active' => MatchStatus.active,
        'completed' => MatchStatus.completed,
        'abandoned' => MatchStatus.abandoned,
        _ => throw const FormatException('Invalid match status.'),
      };
      final fen = value['fen'];
      final ply = value['ply'];
      final turn = value['turn'];
      final rawPlayers = value['players'];
      final rawClocks = _map(value['clocks']);
      final rawHistory = value['sanHistory'] ?? const <Object?>[];
      final lastMove = value['lastMoveUci'];
      final rawResult = value['result'];
      if (id is! String ||
          id.trim().isEmpty ||
          id.length > 80 ||
          fen is! String ||
          fen.isEmpty ||
          fen.length > 100 ||
          ply is! int ||
          ply < 0 ||
          (turn != 'white' && turn != 'black') ||
          rawPlayers is! List ||
          rawPlayers.length != 2 ||
          rawHistory is! List ||
          rawHistory.any((item) => item is! String || item.length > 12) ||
          (lastMove != null &&
              (lastMove is! String || !_uciPattern.hasMatch(lastMove))) ||
          (rawResult != null &&
              rawResult != 'white' &&
              rawResult != 'black' &&
              rawResult != 'draw')) {
        throw const FormatException('Invalid match fields.');
      }
      final players = rawPlayers.map(_player).toList(growable: false);
      if (players[0].color == players[1].color ||
          players[0].id == players[1].id) {
        throw const FormatException('Duplicate match player.');
      }
      final whiteClock = rawClocks['whiteMilliseconds'];
      final blackClock = rawClocks['blackMilliseconds'];
      if (whiteClock is! int ||
          whiteClock < 0 ||
          blackClock is! int ||
          blackClock < 0) {
        throw const FormatException('Invalid clock values.');
      }
      return MatchSnapshot(
        id: id,
        status: status,
        fen: fen,
        ply: ply,
        whiteToMove: turn == 'white',
        players: players,
        clocks: MatchClocks(
          whiteMilliseconds: whiteClock,
          blackMilliseconds: blackClock,
          serverTime: _date(rawClocks['serverTime']),
        ),
        updatedAt: _date(value['updatedAt']),
        lastMoveUci: lastMove as String?,
        sanHistory: rawHistory.cast<String>().toList(growable: false),
        result: switch (rawResult) {
          null => null,
          'white' => MatchResult.white,
          'black' => MatchResult.black,
          'draw' => MatchResult.draw,
          _ => throw const FormatException('Invalid match result.'),
        },
      );
    } on FormatException {
      throw _invalidResponse();
    }
  }

  MatchPlayer _player(Object? value) {
    final json = _map(value);
    final player = _map(json['player']);
    final id = player['id'];
    final displayName = player['displayName'];
    final color = switch (json['color']) {
      'white' => MatchColor.white,
      'black' => MatchColor.black,
      _ => throw const FormatException('Invalid player color.'),
    };
    if (id is! String ||
        id.isEmpty ||
        id.length > 80 ||
        displayName is! String ||
        displayName.trim().isEmpty ||
        displayName.length > 40) {
      throw const FormatException('Invalid match player.');
    }
    return MatchPlayer(id: id, displayName: displayName, color: color);
  }

  Map<String, Object?> _map(Object? value) {
    if (value is Map<String, Object?>) return value;
    throw const FormatException('Expected object.');
  }

  DateTime _date(Object? value) {
    if (value is! String) throw const FormatException('Expected date.');
    return DateTime.parse(value).toUtc();
  }

  ApiFailure _invalidResponse() => const ApiFailure(
    'Sunucu geçersiz bir maç yanıtı verdi.',
    kind: ApiFailureKind.invalidResponse,
  );
}
