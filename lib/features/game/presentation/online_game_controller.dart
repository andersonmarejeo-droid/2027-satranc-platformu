import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/networking/api_client.dart';
import '../data/local_chess_rules.dart';
import '../domain/game_rules.dart';
import '../domain/match_repository.dart';
import '../domain/match_snapshot.dart';
import '../domain/match_interactions.dart';
import '../domain/match_stream_event.dart';
import '../domain/owned_match_repository.dart';
import '../domain/match_connection_repository.dart';
import 'board_view_state.dart';

class OnlineGameController extends ChangeNotifier implements BoardViewState {
  OnlineGameController(this._repository, this.matchId);

  final MatchRepository _repository;
  final String matchId;
  MatchSnapshot? snapshot;
  LocalChessRules? _rules;
  @override
  String? selected;
  @override
  String? lastFrom;
  @override
  String? lastTo;
  String? error;
  bool isLoading = true;
  bool isSubmitting = false;
  @override
  bool flipped = false;
  bool _refreshInProgress = false;
  bool _disposed = false;
  int _lastSequence = 0;
  StreamSubscription<MatchStreamEvent>? _eventSubscription;
  StreamSubscription<MatchConnection>? _connectionSubscription;
  Timer? _retryTimer;
  int _retryAttempt = 0;
  bool connected = true;
  DateTime? opponentSeenAt;
  String get connectionLabel => !connected
      ? 'Yeniden bağlanıyor…'
      : opponentSeenAt == null
      ? 'Bağlı · Rakipten haber bekleniyor'
      : DateTime.now().difference(opponentSeenAt!).inSeconds < 65
      ? 'Bağlı · Rakip oyun ekranında'
      : 'Bağlı · Rakipten haber bekleniyor';
  bool get supportsInteractions => _repository is MatchSocialRepository;
  bool get hasRealtimeUpdates => _repository is RealtimeMatchRepository;
  String? get playerId => _repository is MatchSocialRepository
      ? (_repository as MatchSocialRepository).playerId
      : (_repository is OwnedMatchRepository
          ? (_repository as OwnedMatchRepository).playerId
          : null);
  bool get canPlay {
    final repo = _repository, current = snapshot;
    if (repo is! OwnedMatchRepository || current == null) return true;
    return current
            .player(current.whiteToMove ? MatchColor.white : MatchColor.black)
            .id ==
        (repo as OwnedMatchRepository).playerId;
  }

  @override
  GameRules get rules => _rules!;

  @override
  List<String> get targets => selected == null || _rules == null
      ? const []
      : _rules!.destinations(selected!);

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      _apply(await _repository.fetch(matchId));
      connected = true;
      _retryAttempt = 0;
      _watchEvents();
      final repository = _repository;
      if (repository is MatchConnectionRepository &&
          _connectionSubscription == null) {
        _connectionSubscription = (repository as MatchConnectionRepository)
            .watchConnection(matchId)
            .listen(
              (state) {
                final recovered = !connected && state.connected;
                connected = state.connected;
                opponentSeenAt = state.opponentSeenAt;
                notifyListeners();
                if (recovered) unawaited(refresh());
              },
              onError: (Object _) {
                connected = false;
                notifyListeners();
              },
            );
      }
    } on ApiFailure catch (failure) {
      error = failure.message;
    } catch (_) {
      error = 'Maç yüklenemedi. Bağlantını kontrol edip yeniden dene.';
      connected = false;
      _scheduleRetry();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if ((!supportsInteractions && snapshot?.status != MatchStatus.active) ||
        isSubmitting ||
        _refreshInProgress) {
      return;
    }
    _refreshInProgress = true;
    try {
      _apply(await _repository.fetch(matchId));
      error = null;
      connected = true;
      _retryAttempt = 0;
      _watchEvents();
    } on ApiFailure catch (failure) {
      error = failure.message;
    } catch (_) {
      error = 'Maç durumu yenilenemedi.';
      connected = false;
      _scheduleRetry();
    } finally {
      _refreshInProgress = false;
    }
    notifyListeners();
  }

  void select(String square) {
    if (!connected ||
        isSubmitting ||
        !canPlay ||
        snapshot?.status != MatchStatus.active ||
        _rules == null) {
      return;
    }
    final piece = _rules!.pieceAt(square);
    selected =
        piece != null &&
            piece.isWhite == _rules!.whiteToMove &&
            selected != square
        ? square
        : null;
    notifyListeners();
  }

  Future<void> submitMove(
    String from,
    String to, {
    String promotion = 'q',
  }) async {
    final current = snapshot;
    if (current == null ||
        !connected ||
        !canPlay ||
        current.status != MatchStatus.active ||
        isSubmitting ||
        _rules == null ||
        !_rules!.destinations(from).contains(to)) {
      return;
    }
    isSubmitting = true;
    error = null;
    notifyListeners();
    try {
      _apply(
        await _repository.submitMove(
          matchId,
          expectedPly: current.ply,
          uci: '$from$to${_rules!.needsPromotion(from, to) ? promotion : ''}',
        ),
      );
      selected = null;
      lastFrom = from;
      lastTo = to;
    } on ApiFailure catch (failure) {
      if (failure.statusCode == 409) {
        try {
          _apply(await _repository.fetch(matchId));
          error = snapshot?.status == MatchStatus.completed
              ? null
              : 'Tahta güncellendi; güncel konumdan yeniden hamle yap.';
        } catch (_) {
          error = 'Sıra değişmiş. Tahtayı yenileyip yeniden dene.';
        }
      } else {
        error = failure.message;
      }
    } catch (_) {
      error = 'Hamle sunucuya iletilemedi. Yeniden deneyebilirsin.';
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void flip() {
    flipped = !flipped;
    notifyListeners();
  }

  Future<void> _socialAction(
    Future<MatchSnapshot> Function(MatchSocialRepository) action,
  ) async {
    if (!supportsInteractions || isSubmitting) return;
    isSubmitting = true;
    error = null;
    notifyListeners();
    try {
      _apply(await action(_repository as MatchSocialRepository));
    } catch (_) {
      error = 'İstek gönderilemedi. Teklif değişmiş olabilir; yeniden dene.';
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> offerDraw() => _socialAction((repo) => repo.offerDraw(matchId));
  Future<void> respondToDraw(bool accept) =>
      _socialAction((repo) => repo.respondToDraw(matchId, accept: accept));
  Future<void> resign() => _socialAction((repo) => repo.resign(matchId));
  Future<void> requestRematch() =>
      _socialAction((repo) => repo.requestRematch(matchId));
  Future<void> sendQuickMessage(QuickMessageCode code) =>
      _socialAction((repo) => repo.sendQuickMessage(matchId, code));

  Future<String?> acceptRematch() async {
    if (!supportsInteractions || isSubmitting) return null;
    isSubmitting = true;
    error = null;
    notifyListeners();
    try {
      return await (_repository as MatchSocialRepository).acceptRematch(
        matchId,
      );
    } catch (_) {
      error = 'Rövanş açılamadı. Bağlantını kontrol edip yeniden dene.';
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_eventSubscription?.cancel());
    unawaited(_connectionSubscription?.cancel());
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  void _watchEvents() {
    if (_disposed ||
        _eventSubscription != null ||
        (!supportsInteractions && snapshot?.status != MatchStatus.active)) {
      return;
    }
    _eventSubscription = _repository
        .watchEvents(matchId, afterSequence: _lastSequence)
        .listen(
          (event) {
            if (event.matchId != matchId || event.sequence <= _lastSequence) {
              return;
            }
            _lastSequence = event.sequence;
            if (const {
              'match.snapshot',
              'move.accepted',
              'clock.updated',
              'draw.offered',
              'match.ended',
              'error',
            }.contains(event.type)) {
              if (event.type == 'error') {
                error = 'Sunucu canlı maç isteğini reddetti.';
              }
              if (event.payload['snapshot'] case final MatchSnapshot liveSnap) {
                _apply(liveSnap);
                if (event.type != 'error') error = null;
                connected = true;
                _retryAttempt = 0;
                notifyListeners();
              } else {
                unawaited(refresh());
              }
            }
          },
          onError: (Object _) {
            connected = false;
            error =
                'Bağlantı kesildi. İnternet gelince tahta yeniden eşitlenir.';
            notifyListeners();
            final subscription = _eventSubscription;
            _eventSubscription = null;
            unawaited(subscription?.cancel());
            _scheduleRetry();
          },
        );
  }

  void _scheduleRetry() {
    if (_disposed || _retryTimer?.isActive == true) return;
    final seconds = [2, 4, 8, 16, 30][_retryAttempt.clamp(0, 4)];
    _retryAttempt++;
    _retryTimer = Timer(Duration(seconds: seconds), () {
      if (_disposed) return;
      if (snapshot == null) {
        unawaited(load());
      } else {
        unawaited(refresh());
      }
    });
  }

  void _apply(MatchSnapshot next) {
    if (_disposed) return;
    if (next.id != matchId) {
      throw const ApiFailure(
        'Sunucu farklı bir maç konumu döndürdü.',
        kind: ApiFailureKind.invalidResponse,
      );
    }
    LocalChessRules rules;
    if (next.sanHistory.isNotEmpty) {
      try {
        final replayed = LocalChessRules.fromHistory(
          initialFen: LocalChessRules().fen,
          moves: next.sanHistory,
        );
        rules = replayed.fen == next.fen
            ? replayed
            : LocalChessRules(fen: next.fen);
      } on FormatException {
        rules = LocalChessRules(fen: next.fen);
      }
    } else {
      rules = LocalChessRules(fen: next.fen);
    }
    if (rules.whiteToMove != next.whiteToMove) {
      throw const ApiFailure(
        'Sunucu maç sırası ile tahta konumu uyuşmuyor.',
        kind: ApiFailureKind.invalidResponse,
      );
    }
    final current = snapshot;
    if (current != null &&
        (next.ply < current.ply ||
            next.updatedAt.isBefore(current.updatedAt))) {
      return;
    }
    if (snapshot?.ply != next.ply) {
      selected = null;
      final move = next.lastMoveUci;
      lastFrom = move?.substring(0, 2);
      lastTo = move?.substring(2, 4);
    }
    snapshot = next;
    if (current == null && _repository is OwnedMatchRepository) {
      flipped =
          next.player(MatchColor.black).id ==
          (_repository as OwnedMatchRepository).playerId;
    }
    _rules = rules;
    if (next.status != MatchStatus.active && !supportsInteractions) {
      final subscription = _eventSubscription;
      _eventSubscription = null;
      unawaited(subscription?.cancel());
    }
  }
}
