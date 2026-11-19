import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/menu_back.dart';
import '../../../core/platform/game_device.dart';

import '../../../app/app_services.dart';
import '../../../core/widgets/page_layout.dart';
import '../../safety/domain/safety_repository.dart';
import '../data/local_game_playback.dart';
import '../domain/game_rules.dart';
import '../domain/match_snapshot.dart';
import '../domain/online_match_timing.dart';
import 'online_game_controller.dart';
import 'widgets/captured_pieces_strip.dart';
import 'widgets/chess_board.dart';
import 'widgets/fullscreen_game_bar.dart';
import 'widgets/focused_game_layout.dart';
import 'widgets/match_actions.dart';
import 'widgets/online_connection_pill.dart';
import '../../settings/presentation/board_appearance_controls.dart';
import '../data/local_chess_rules.dart';
import 'game_review_sheet.dart';
import '../../../core/ads/ad_service.dart';
import '../../../core/ads/ad_banner_widget.dart';

class OnlineMatchScreen extends StatefulWidget {
  const OnlineMatchScreen({super.key, required this.matchId});

  final String matchId;

  @override
  State<OnlineMatchScreen> createState() => _OnlineMatchScreenState();
}

class _OnlineMatchScreenState extends State<OnlineMatchScreen> {
  OnlineGameController? _controller;
  Timer? _refreshTimer;
  Timer? _clockTicker;
  final Stopwatch _clockWatch = Stopwatch();
  MatchSnapshot? _clockSnapshot;
  String? _lastRenderedClockKey;
  bool _zeroRefreshTriggered = false;
  bool _fullscreen = false, _soundEnabled = true;
  bool _adShownForCurrentGame = false;
  int? _playedPly;
  String? _openedRematch;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _connect();
  }

  @override
  void didUpdateWidget(covariant OnlineMatchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchId == widget.matchId) return;
    _refreshTimer?.cancel();
    _clockTicker?.cancel();
    _clockWatch
      ..stop()
      ..reset();
    _clockSnapshot = null;
    _lastRenderedClockKey = null;
    _zeroRefreshTriggered = false;
    _controller?.removeListener(_moveFeedback);
    _controller?.dispose();
    _controller = null;
    _playedPly = null;
    _openedRematch = null;
    _connect();
  }

  void _connect() {
    if (_controller != null) return;
    final repository = AppScope.of(context).matches;
    if (repository == null) return;
    final controller = OnlineGameController(repository, widget.matchId);
    _controller = controller;
    controller.addListener(_moveFeedback);
    unawaited(controller.load());
    if (!controller.hasRealtimeUpdates) {
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 4),
        (_) => unawaited(controller.refresh()),
      );
    }
    _clockTicker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _onClockTick(),
    );
  }

  void _syncClockAnchor(MatchSnapshot? snapshot) {
    if (identical(_clockSnapshot, snapshot)) return;
    _clockSnapshot = snapshot;
    _zeroRefreshTriggered = false;
    _clockWatch.reset();
    if (snapshot != null && snapshot.status == MatchStatus.active) {
      _clockWatch.start();
    } else {
      _clockWatch.stop();
    }
    _lastRenderedClockKey = snapshot == null ? null : _clockDisplayKey(snapshot);
  }

  int _liveClockMs(MatchSnapshot snapshot, MatchColor color) {
    final base = color == MatchColor.white
        ? snapshot.clocks.whiteMilliseconds
        : snapshot.clocks.blackMilliseconds;
    if (snapshot.status != MatchStatus.active) return base;
    final activeColor = snapshot.whiteToMove
        ? MatchColor.white
        : MatchColor.black;
    if (color != activeColor) return base;
    return math.max(0, base - _clockWatch.elapsedMilliseconds);
  }

  int? _liveTurnRemainingMs(MatchSnapshot snapshot) {
    final base = snapshot.turnRemainingMilliseconds;
    if (base == null || snapshot.status != MatchStatus.active) return base;
    return math.max(0, base - _clockWatch.elapsedMilliseconds);
  }

  String _clockDisplayKey(MatchSnapshot snapshot) {
    final wSec = _liveClockMs(snapshot, MatchColor.white) ~/ 1000;
    final bSec = _liveClockMs(snapshot, MatchColor.black) ~/ 1000;
    final turnMs = _liveTurnRemainingMs(snapshot);
    final turnSec = turnMs == null ? -1 : (turnMs / 1000).ceil();
    return '$wSec:$bSec:$turnSec';
  }

  void _onClockTick() {
    final controller = _controller;
    final snapshot = controller?.snapshot;
    if (!mounted ||
        controller == null ||
        snapshot == null ||
        snapshot.status != MatchStatus.active) {
      return;
    }
    final nextKey = _clockDisplayKey(snapshot);
    if (nextKey != _lastRenderedClockKey) {
      setState(() => _lastRenderedClockKey = nextKey);
    }
    final activeColor = snapshot.whiteToMove
        ? MatchColor.white
        : MatchColor.black;
    final activeMs = _liveClockMs(snapshot, activeColor);
    final turnMs = _liveTurnRemainingMs(snapshot);
    if (!_zeroRefreshTriggered &&
        controller.hasRealtimeUpdates &&
        (activeMs <= 0 || (turnMs != null && turnMs <= 0))) {
      _zeroRefreshTriggered = true;
      unawaited(controller.refresh());
    }
  }

  @override
  void dispose() {
    if (_fullscreen) unawaited(GameDevice.fullscreen(false));
    _refreshTimer?.cancel();
    _clockTicker?.cancel();
    _clockWatch.stop();
    _controller?.removeListener(_moveFeedback);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _tapSquare(
    OnlineGameController controller,
    String square,
  ) async {
    if (controller.isSubmitting ||
        controller.snapshot?.status != MatchStatus.active) {
      return;
    }
    final from = controller.selected;
    if (from == null || !controller.targets.contains(square)) {
      controller.select(square);
      return;
    }
    final selectedPly = controller.snapshot?.ply;
    var promotion = 'q';
    if (controller.rules.needsPromotion(from, square)) {
      final chosen = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Piyonu terfi ettir'),
          children: [
            for (final entry in const {
              'q': 'Vezir',
              'r': 'Kale',
              'b': 'Fil',
              'n': 'At',
            }.entries)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, entry.key),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(entry.value),
                ),
              ),
          ],
        ),
      );
      if (chosen == null ||
          !mounted ||
          controller.snapshot?.ply != selectedPly) {
        return;
      }
      promotion = chosen;
    }
    await controller.submitMove(from, square, promotion: promotion);
  }

  MatchPlayer? _opponentPlayer(OnlineGameController controller) {
    final snapshot = controller.snapshot;
    if (snapshot == null) return null;
    final myId = controller.playerId;
    if (myId != null) {
      return snapshot.players.where((p) => p.id != myId).firstOrNull;
    }
    final opponentColor = controller.flipped
        ? MatchColor.white
        : MatchColor.black;
    return snapshot.player(opponentColor);
  }

  Future<void> _copyOnlinePgn(MatchSnapshot snapshot) async {
    final pgn = LocalGamePlayback.formatOnlinePgn(
      sanMoves: snapshot.sanHistory,
      playedAt: snapshot.updatedAt,
      whiteName: snapshot.player(MatchColor.white).displayName,
      blackName: snapshot.player(MatchColor.black).displayName,
      resultPgn: switch (snapshot.result) {
        MatchResult.white => '1-0',
        MatchResult.black => '0-1',
        MatchResult.draw => '1/2-1/2',
        null => '*',
      },
    );
    try {
      await Clipboard.setData(ClipboardData(text: pgn));
      if (mounted) showNotice(context, 'PGN metni kopyalandı.');
    } catch (_) {
      if (mounted) showNotice(context, 'PGN metni kopyalanamadı.');
    }
  }

  Future<void> _reportOpponent(
    SafetyRepository safety,
    MatchPlayer opponent,
    String matchId,
  ) async {
    const reasons = [
      'Uygunsuz oyuncu adı',
      'Kasıtlı süre geciktirme',
      'Hile şüphesi',
      'Sportmenlik dışı davranış',
    ];
    var selectedReason = reasons.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, updateDialog) => AlertDialog(
          title: const Text('Oyuncuyu bildir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${opponent.displayName} için bildirim nedeni seç:'),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: selectedReason,
                onChanged: (value) {
                  if (value != null) {
                    updateDialog(() => selectedReason = value);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final reason in reasons)
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(reason),
                        value: reason,
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              key: const ValueKey('confirm-report-opponent'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Gönder'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await safety.reportPlayer(
        playerId: opponent.id,
        reason: selectedReason,
        matchId: matchId,
      );
      if (mounted) showNotice(context, 'Bildirimin alındı. Teşekkürler.');
    } catch (_) {
      if (mounted) {
        showNotice(context, 'Bildirim gönderilemedi. Yeniden dene.');
      }
    }
  }

  Future<void> _blockOpponent(
    SafetyRepository safety,
    MatchPlayer opponent,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oyuncuyu engelle'),
        content: Text(
          '${opponent.displayName} engellendiğinde davetlerine katılamaz ve yeni maçlarda seninle eşleşmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const ValueKey('confirm-block-opponent'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Engelle'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await safety.blockPlayer(opponent.id);
      if (mounted) showNotice(context, 'Oyuncu engellendi.');
    } catch (_) {
      if (mounted) {
        showNotice(context, 'Oyuncu engellenemedi. Yeniden dene.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => MenuBackScope(
    onBack: _fullscreen ? () => _setFullscreen(false) : null,
    child: _buildScreen(context),
  );

  void _setFullscreen(bool value) {
    setState(() => _fullscreen = value);
    unawaited(GameDevice.fullscreen(value));
  }

  void _moveFeedback() {
    _syncClockAnchor(_controller?.snapshot);
    final rematch = _controller?.snapshot?.interactions.rematchMatchId;
    if (rematch != null && rematch != _openedRematch) {
      _openedRematch = rematch;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.replace('/online-match/$rematch');
      });
    }
    final ply = _controller?.snapshot?.ply;
    final status = _controller?.snapshot?.status;
    if ((status == MatchStatus.completed || status == MatchStatus.abandoned) &&
        !_adShownForCurrentGame) {
      _adShownForCurrentGame = true;
      unawaited(AdService.instance.showGameOverInterstitial());
    }
    if (status == MatchStatus.completed && mounted) {
      unawaited(AppScope.of(context).competition?.record(widget.matchId));
    }
    if (ply == null) return;
    if (_playedPly != null && ply > _playedPly! && _soundEnabled) {
      unawaited(GameDevice.slideSound());
    }
    _playedPly = ply;
  }

  Widget _buildScreen(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const MenuBackButton(),
          title: const Text('Çevrim içi maç'),
        ),
        body: const PageLayout(
          eyebrow: 'Bağlantı gerekli',
          title: 'Maç sunucusuna bağlanılamıyor.',
          subtitle:
              'Bu maç, oturum açılmış bir hesap ve yapılandırılmış oyun sunucusu gerektirir.',
          children: [],
        ),
      );
    }
    final safety = AppScope.of(context).safety;
    return Scaffold(
      bottomNavigationBar: const AdBannerWidget(),
      appBar: _fullscreen
          ? null
          : AppBar(
              leading: const MenuBackButton(),
              title: const Text('Çevrim içi maç'),
              actions: [
                IconButton(
                  key: const ValueKey('game-fullscreen'),
                  tooltip: _fullscreen ? 'Tam ekrandan çık' : 'Tam ekran',
                  onPressed: () => _setFullscreen(!_fullscreen),
                  icon: Icon(
                    _fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  ),
                ),
                const BoardAppearanceButton(),
                IconButton(
                  tooltip: 'Tahtayı yenile',
                  onPressed: () => controller.snapshot == null
                      ? unawaited(controller.load())
                      : unawaited(controller.refresh()),
                  icon: const Icon(Icons.sync),
                ),
                IconButton(
                  tooltip: 'Tahtayı çevir',
                  onPressed: controller.flip,
                  icon: const Icon(Icons.flip_camera_android_outlined),
                ),
                if (safety != null)
                  ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) {
                      final opponent = _opponentPlayer(controller);
                      final snapshot = controller.snapshot;
                      if (opponent == null || snapshot == null) {
                        return const SizedBox.shrink();
                      }
                      return PopupMenuButton<String>(
                        key: const ValueKey('online-match-menu'),
                        tooltip: 'Güvenlik seçenekleri',
                        onSelected: (action) {
                          if (action == 'report') {
                            unawaited(
                              _reportOpponent(safety, opponent, snapshot.id),
                            );
                          } else if (action == 'block') {
                            unawaited(_blockOpponent(safety, opponent));
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            key: ValueKey('report-opponent'),
                            value: 'report',
                            child: Text('Oyuncuyu bildir'),
                          ),
                          PopupMenuItem(
                            key: ValueKey('block-opponent'),
                            value: 'block',
                            child: Text('Oyuncuyu engelle'),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final snapshot = controller.snapshot;
            _syncClockAnchor(snapshot);
            if (snapshot == null && controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot == null) {
              return PageLayout(
                eyebrow: 'Sunucu bağlantısı',
                title: 'Maç yüklenemedi.',
                subtitle: controller.error ?? 'Yeniden deneyebilirsin.',
                children: [
                  FilledButton.icon(
                    onPressed: () => unawaited(controller.load()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Yeniden dene'),
                  ),
                ],
              );
            }
            final topColor = controller.flipped
                ? MatchColor.white
                : MatchColor.black;
            final bottomColor = controller.flipped
                ? MatchColor.black
                : MatchColor.white;
            if (_fullscreen) {
              Widget player(MatchColor color) => _OnlinePlayerRow(
                player: snapshot.player(color),
                milliseconds: _liveClockMs(snapshot, color),
                active:
                    snapshot.status == MatchStatus.active &&
                    snapshot.whiteToMove == (color == MatchColor.white),
                rules: controller.rules,
              );
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: FocusedGameLayout(
                      key: const ValueKey('focused-game'),
                      board: ChessBoard(
                        controller: controller,
                        allowMoveHints: false,
                        onSquareTap: (square) => _tapSquare(controller, square),
                      ),
                      topPlayer: player(topColor),
                      bottomPlayer: player(bottomColor),
                      status: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OnlineConnectionPill(
                            connected: controller.connected,
                            label: controller.connectionLabel,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            controller.error ??
                                '${_matchStatus(controller)}${_turnStatus(snapshot)}',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      controls: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => SafeArea(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: ListenableBuilder(
                                    listenable: controller,
                                    builder: (_, _) => OnlineMatchActions(
                                      controller: controller,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.handshake_outlined),
                            label: const Text('Maç seçenekleri'),
                          ),
                          IconButton(
                            key: const ValueKey('focused-game-sound'),
                            tooltip: _soundEnabled
                                ? 'Taş seslerini kapat'
                                : 'Taş seslerini aç',
                            onPressed: () =>
                                setState(() => _soundEnabled = !_soundEnabled),
                            icon: Icon(
                              _soundEnabled
                                  ? Icons.volume_up_outlined
                                  : Icons.volume_off_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    left: 8,
                    right: 8,
                    child: FullscreenGameBar(
                      title: 'Çevrim içi maç',
                      onExit: () => _setFullscreen(false),
                      onFlip: controller.flip,
                    ),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const DemoLabel(text: 'SUNUCU MAÇI'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Maç ${snapshot.id}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      OnlineConnectionPill(
                        connected: controller.connected,
                        label: controller.connectionLabel,
                        key: const ValueKey('online-connection-status'),
                      ),
                      _OnlinePlayerRow(
                        player: snapshot.player(topColor),
                        milliseconds: _liveClockMs(snapshot, topColor),
                        active:
                            snapshot.status == MatchStatus.active &&
                            snapshot.whiteToMove ==
                                (topColor == MatchColor.white),
                        rules: controller.rules,
                      ),
                      const SizedBox(height: 14),
                      ChessBoard(
                        controller: controller,
                        allowMoveHints: false,
                        onSquareTap: (square) => _tapSquare(controller, square),
                      ),
                      const SizedBox(height: 14),
                      _OnlinePlayerRow(
                        player: snapshot.player(bottomColor),
                        milliseconds: _liveClockMs(snapshot, bottomColor),
                        active:
                            snapshot.status == MatchStatus.active &&
                            snapshot.whiteToMove ==
                                (bottomColor == MatchColor.white),
                        rules: controller.rules,
                      ),
                      const SizedBox(height: 16),
                      SurfaceCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              snapshot.status == MatchStatus.active
                                  ? Icons.circle
                                  : Icons.flag_outlined,
                              size: snapshot.status == MatchStatus.active
                                  ? 9
                                  : 22,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _matchStatus(controller),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (controller.isSubmitting)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (snapshot.status == MatchStatus.active &&
                          snapshot.turnRemainingMilliseconds != null)
                        Text(
                          _turnStatus(snapshot).trim(),
                          key: const ValueKey('online-turn-countdown'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      Text(
                        'Saatler sunucudan alınan son görüntüdür · ${_clockTime(snapshot.clocks.serverTime)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (controller.error case final message?) ...[
                        const SizedBox(height: 12),
                        SurfaceCard(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      OnlineMatchActions(controller: controller),
                      if (snapshot.status == MatchStatus.completed) ...[
                        if (AppScope.of(context).competition
                            case final competition?)
                          ListenableBuilder(
                            listenable: competition,
                            builder: (context, _) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                competition.status(widget.matchId) ??
                                    'Sonuç doğrulanıyor…',
                              ),
                            ),
                          ),
                        TextButton.icon(
                          onPressed: () => showGameReview(
                            context,
                            initialFen: LocalChessRules().fen,
                            moves: snapshot.sanHistory,
                          ),
                          icon: const Icon(Icons.lightbulb_outline),
                          label: const Text('Bu maçtan ne öğrenebilirim?'),
                        ),
                      ],
                      SwitchListTile.adaptive(
                        key: const ValueKey('game-sound'),
                        title: const Text('Taş sesleri'),
                        value: _soundEnabled,
                        onChanged: (value) =>
                            setState(() => _soundEnabled = value),
                      ),
                      Row(
                        children: [
                          const Expanded(child: SectionTitle('Hamleler')),
                          if (snapshot.sanHistory.isNotEmpty)
                            OutlinedButton.icon(
                              key: const ValueKey('copy-online-pgn'),
                              onPressed: () => _copyOnlinePgn(snapshot),
                              icon: const Icon(Icons.copy_outlined, size: 18),
                              label: const Text('PGN kopyala'),
                            ),
                        ],
                      ),
                      SurfaceCard(
                        child: snapshot.sanHistory.isEmpty
                            ? const Text('Henüz hamle yapılmadı.')
                            : Wrap(
                                spacing: 20,
                                runSpacing: 10,
                                children: [
                                  for (
                                    var i = 0;
                                    i < snapshot.sanHistory.length;
                                    i += 2
                                  )
                                    Text(
                                      '${i ~/ 2 + 1}. ${snapshot.sanHistory[i]}  ${i + 1 < snapshot.sanHistory.length ? snapshot.sanHistory[i + 1] : ''}',
                                      style: const TextStyle(
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _matchStatus(OnlineGameController controller) {
    final snapshot = controller.snapshot!;
    if (snapshot.interactions.resignedBy case final resignedUid?) {
      final resignedWhite =
          snapshot.player(MatchColor.white).id == resignedUid;
      final winner = snapshot.result == MatchResult.white ? 'Beyaz' : 'Siyah';
      return '${resignedWhite ? 'Beyaz' : 'Siyah'} oyunu terk etti · $winner kazandı';
    }
    if (snapshot.timeoutReason == MatchTimeoutReason.inactivity) {
      return '3 dakika hamle yapılmadı · ${snapshot.result == MatchResult.white ? 'Beyaz' : 'Siyah'} kazandı';
    }
    return switch (snapshot.status) {
      MatchStatus.active => controller.rules.status,
      MatchStatus.completed => switch (snapshot.result) {
        MatchResult.white => 'Maç tamamlandı · Beyaz kazandı',
        MatchResult.black => 'Maç tamamlandı · Siyah kazandı',
        MatchResult.draw || null => 'Maç tamamlandı · Berabere',
      },
      MatchStatus.abandoned => 'Maç sona erdi · Oyunculardan biri ayrıldı',
    };
  }

  String _turnStatus(MatchSnapshot snapshot) {
    final remaining = _liveTurnRemainingMs(snapshot);
    if (remaining == null || snapshot.status != MatchStatus.active) return '';
    final seconds = (remaining / 1000).ceil();
    final time =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return '\nBu hamle için kalan: $time · 3 dakika hamle yapmayan kaybeder';
  }

  String _clockTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _OnlinePlayerRow extends StatelessWidget {
  const _OnlinePlayerRow({
    required this.player,
    required this.milliseconds,
    required this.active,
    required this.rules,
  });

  final MatchPlayer player;
  final int milliseconds;
  final bool active;
  final GameRules rules;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: player.color == MatchColor.white
              ? const Color(0xFFF1E7D2)
              : const Color(0xFF2E3C32),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBDAA8E)),
        ),
        child: Icon(
          Icons.person_outline,
          color: player.color == MatchColor.white
              ? const Color(0xFF554932)
              : const Color(0xFFEBE4D6),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              player.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${player.color == MatchColor.white ? 'Beyaz' : 'Siyah'}${active ? ' · Hamle sırası' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            CapturedPiecesStrip(
              rules: rules,
              forWhite: player.color == MatchColor.white,
            ),
          ],
        ),
      ),
      Text(
        _formatClock(milliseconds),
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    ],
  );

  String _formatClock(int value) {
    final totalSeconds = value ~/ 1000;
    return '${totalSeconds ~/ 60}:${(totalSeconds % 60).toString().padLeft(2, '0')}';
  }
}
