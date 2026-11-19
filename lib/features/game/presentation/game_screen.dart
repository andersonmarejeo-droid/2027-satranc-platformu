import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_services.dart';
import '../../../core/ads/ad_banner_widget.dart';
import '../../../core/ads/ad_service.dart';
import '../../../core/platform/game_device.dart';
import '../../../core/routing/menu_back.dart';
import '../../../core/widgets/page_layout.dart';
import '../../settings/presentation/board_appearance_controls.dart';
import '../domain/computer_difficulty.dart';
import '../domain/game_draft.dart';
import '../domain/game_result.dart';
import '../domain/game_rules.dart';
import '../domain/saved_game.dart';
import '../domain/time_control.dart';
import 'game_controller.dart';
import 'game_review_sheet.dart';
import 'move_presentation.dart';
import 'widgets/captured_pieces_strip.dart';
import 'widgets/chess_board.dart';
import 'widgets/focused_game_layout.dart';
import 'widgets/fullscreen_game_bar.dart';
import 'widgets/match_actions.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.timeControl = const TimeControl(10, 0),
    this.clockEnabled = true,
    this.draft,
    this.difficulty = ComputerDifficulty.medium,
    this.opponent = GameOpponent.twoPlayers,
    this.humanPlaysWhite = true,
    this.matchmakingFallback = false,
  });

  final TimeControl timeControl;
  final bool clockEnabled;
  final GameDraft? draft;
  final ComputerDifficulty difficulty;
  final GameOpponent opponent;
  final bool humanPlaysWhite;
  final bool matchmakingFallback;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  static final Random _random = Random();

  late GameController controller;
  bool _initialized = false;
  bool _restoreFailed = false;
  bool _saving = false;
  bool _fullscreen = false;
  bool _soundEnabled = true;
  bool _allowPop = false;
  bool _leaving = false;
  bool _adShown = false;

  int _computerToken = 0;
  bool _computerThinking = false;

  late String _initialFen;
  late String _recordId;
  late DateTime _startedAt;
  String? _savedSignature;
  final List<String> _localMessages = [];

  bool get _computer => widget.opponent == GameOpponent.computer;
  bool get _humanWhite => !_computer || widget.humanPlaysWhite;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _initGame();
  }

  void _initGame() {
    final draft = widget.draft;
    if (draft != null) {
      try {
        controller = GameController.restore(draft);
        _initialFen = draft.game.initialFen;
        _recordId = draft.game.id;
        _startedAt = draft.game.savedAt;
        _savedSignature = _signature;
        if (!controller.rules.isOver && !controller.clock.hasEnded) {
          controller.clock.resume();
        }
      } catch (_) {
        _restoreFailed = true;
        return;
      }
    } else {
      final rules = AppScope.of(context).gameRules();
      controller = GameController(
        rules,
        timeControl: widget.timeControl,
        clockEnabled: widget.clockEnabled,
      );
      if (_computer && !_humanWhite) {
        controller.flipped = true;
      }
      _newRecord();
    }
    controller.clock.addListener(_clockChanged);

    if (_computer &&
        !controller.rules.isOver &&
        !controller.clock.hasEnded &&
        !controller.clock.isPaused &&
        controller.rules.whiteToMove != _humanWhite) {
      unawaited(_computerTurn());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_restoreFailed || !_initialized) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _cancelComputer();
        if (!controller.rules.isOver && !controller.clock.hasEnded) {
          controller.clock.pause();
        }
        unawaited(_checkpoint());
      case AppLifecycleState.resumed:
        break;
    }
  }

  @override
  void dispose() {
    _cancelComputer();
    WidgetsBinding.instance.removeObserver(this);
    if (_fullscreen) unawaited(GameDevice.fullscreen(false));
    if (_initialized && !_restoreFailed) {
      controller.clock.removeListener(_clockChanged);
      controller.dispose();
    }
    super.dispose();
  }

  void _cancelComputer() {
    _computerToken++;
    if (_computerThinking && mounted) {
      setState(() => _computerThinking = false);
    } else {
      _computerThinking = false;
    }
  }

  void _clockChanged() {
    if (!mounted) return;
    if (controller.clock.isFlagged) {
      _cancelComputer();
      unawaited(_checkpoint());
      _checkGameOverAndShowAd();
    }
  }

  void _checkGameOverAndShowAd() {
    if (_adShown) return;
    if (controller.rules.isOver || controller.clock.hasEnded) {
      _adShown = true;
      unawaited(AdService.instance.showGameOverInterstitial());
    }
  }

  void _newRecord() {
    _initialFen = controller.rules.fen;
    _recordId = List.generate(
      32,
      (_) => _random.nextInt(16).toRadixString(16),
    ).join();
    _startedAt = DateTime.now();
    _savedSignature = null;
    _adShown = false;
    _localMessages.clear();
  }

  GameResult get _result => controller.clock.isFlagged
      ? (controller.clock.whiteWonOnTime
            ? GameResult.whiteWins
            : GameResult.blackWins)
      : controller.rules.result;

  String get _signature =>
      '${controller.rules.history.join(' ')}|${_result.name}';

  SavedGame _record() => SavedGame(
    id: _recordId,
    savedAt: _startedAt,
    initialFen: _initialFen,
    moves: controller.rules.history,
    timeControl: widget.timeControl,
    clockEnabled: widget.clockEnabled,
    result: _result,
    opponent: widget.opponent,
    difficulty: widget.difficulty,
    agreedDraw: controller.rules.agreedDraw,
    resigned: controller.rules.resigned,
    humanPlaysWhite: _humanWhite,
  );

  GameDraft _draft() => GameDraft(
    game: _record(),
    clock: controller.clock.exportState(),
    flipped: controller.flipped,
    lastFrom: controller.lastFrom,
    lastTo: controller.lastTo,
  );

  Future<void> _checkpoint() async {
    if (!mounted || _restoreFailed) return;
    final store = AppScope.of(context).gameDraft;
    if (controller.rules.history.isEmpty && !controller.rules.isOver && !controller.clock.hasEnded) {
      return;
    }
    try {
      await store.save(_draft());
    } catch (_) {
      // Taslak kaydetme hatası store.hasError üzerinden arayüzde görünür.
    }
  }

  Future<void> _computerTurn() async {
    if (!_computer || _restoreFailed || !mounted) return;
    if (controller.rules.isOver ||
        controller.clock.hasEnded ||
        controller.clock.isPaused) {
      return;
    }
    if (controller.rules.whiteToMove == _humanWhite) return;

    final token = ++_computerToken;
    final fen = controller.rules.fen;
    setState(() => _computerThinking = true);
    final watch = Stopwatch()..start();

    try {
      final move = await AppScope.of(context).computerMove(
        fen,
        widget.difficulty,
      );
      final remaining = MovePresentation.computerDelay - watch.elapsed;
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }
      if (!mounted || token != _computerToken) return;
      if (move == null ||
          controller.rules.isOver ||
          controller.clock.hasEnded ||
          controller.clock.isPaused ||
          controller.rules.fen != fen) {
        return;
      }
      final from = move['from'];
      final to = move['to'];
      if (from == null || to == null) return;
      final played = controller.playMove(
        from,
        to,
        promotion: move['promotion'] ?? 'q',
      );
      if (played) {
        if (_soundEnabled) unawaited(GameDevice.slideSound());
        await _checkpoint();
        _checkGameOverAndShowAd();
      }
    } finally {
      if (mounted && token == _computerToken) {
        setState(() => _computerThinking = false);
      }
    }
  }

  Future<void> _tapSquare(String square) async {
    if (controller.clock.isPaused ||
        controller.rules.isOver ||
        controller.clock.hasEnded) {
      return;
    }
    if (_computer && controller.rules.whiteToMove != _humanWhite) {
      return;
    }

    final from = controller.selected;
    if (from == null || !controller.targets.contains(square)) {
      controller.selectOrMove(square);
      return;
    }

    final fenBefore = controller.rules.fen;
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
      if (chosen == null || !mounted || controller.rules.fen != fenBefore) {
        return;
      }
      promotion = chosen;
    }

    final played = controller.playMove(from, square, promotion: promotion);
    if (!played) return;
    if (_soundEnabled) unawaited(GameDevice.slideSound());
    await _checkpoint();
    _checkGameOverAndShowAd();
    if (mounted) unawaited(_computerTurn());
  }

  Future<void> _undoMove() async {
    if (!controller.canUndo || _saving) return;
    _cancelComputer();
    controller.undo();
    if (_computer &&
        controller.canUndo &&
        controller.rules.whiteToMove != _humanWhite) {
      controller.undo();
    }
    await _checkpoint();
    if (mounted &&
        _computer &&
        !controller.clock.isPaused &&
        controller.rules.whiteToMove != _humanWhite) {
      unawaited(_computerTurn());
    }
  }

  Future<void> _saveGame() async {
    if (_saving ||
        (controller.rules.history.isEmpty && !controller.rules.isOver)) {
      return;
    }
    controller.clock.exportState();
    final signature = _signature;
    final game = _record();
    setState(() => _saving = true);
    try {
      await AppScope.of(context).gameHistory.save(game);
      if (!mounted) return;
      setState(() => _savedSignature = signature);
      showNotice(
        context,
        'Oyun kaydedildi. Profil → Maç geçmişi üzerinden açabilirsin.',
      );
    } catch (_) {
      if (mounted) showNotice(context, 'Oyun kaydedilemedi. Yeniden dene.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _offerDraw() async {
    if (controller.rules.isOver || controller.clock.hasEnded) return;
    final fen = controller.rules.fen;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Beraberlik teklif et'),
        content: Text(
          _computer
              ? 'Bu alıştırma oyununu bilgisayarla berabere bitirebilirsin.'
              : 'Telefonu rakibine ver. Beraberliği kabul ediyor musun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Devam et'),
          ),
          FilledButton(
            key: const ValueKey('accept-local-draw'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Beraberliği kabul et'),
          ),
        ],
      ),
    );
    if (!mounted || agreed != true) return;
    if (controller.rules.fen != fen || !controller.agreeDraw()) {
      showNotice(
        context,
        'Oyun değişti. Güncel konumdan yeniden teklif edebilirsin.',
      );
      return;
    }
    _cancelComputer();
    await _checkpoint();
    _checkGameOverAndShowAd();
  }

  Future<void> _resignGame() async {
    if (controller.rules.isOver || controller.clock.hasEnded) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oyunu terk et'),
        content: Text(
          _computer
              ? 'Oyunu terk etmek istediğine emin misin? Bilgisayar kazanmış sayılır.'
              : '${controller.rules.whiteToMove ? 'Beyaz' : 'Siyah'} adına oyunu terk etmek istediğine emin misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const ValueKey('confirm-resign'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Terk et'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    if (!controller.resign(white: _computer ? _humanWhite : null)) {
      return;
    }
    _cancelComputer();
    await _checkpoint();
    _checkGameOverAndShowAd();
  }

  Future<void> _rematch() async {
    if (_saving || (!controller.rules.isOver && !controller.clock.hasEnded)) {
      return;
    }
    setState(() => _saving = true);
    try {
      if (controller.rules.history.isNotEmpty) {
        await AppScope.of(context).gameHistory.save(_record());
      }
      if (!mounted) return;
      _cancelComputer();
      controller.reset();
      if (_computer && !_humanWhite) controller.flipped = true;
      setState(_newRecord);
      await _checkpoint();
      if (mounted) unawaited(_computerTurn());
    } catch (_) {
      if (mounted) {
        showNotice(
          context,
          'Maç kaydedilemedi; rövanşı yeniden deneyebilirsin.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _leave() async {
    if (_fullscreen) {
      _setFullscreen(false);
      return;
    }
    if (_leaving) return;
    _leaving = true;
    _cancelComputer();
    if (!_restoreFailed) {
      if (!controller.rules.isOver && !controller.clock.hasEnded) {
        controller.clock.pause();
      }
      await _checkpoint();
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/play');
    }
  }

  void _setFullscreen(bool value) {
    setState(() => _fullscreen = value);
    unawaited(GameDevice.fullscreen(value));
  }

  void _togglePause() {
    if (controller.clock.isPaused) {
      controller.clock.resume();
      unawaited(_checkpoint());
      unawaited(_computerTurn());
    } else {
      _cancelComputer();
      controller.clock.pause();
      unawaited(_checkpoint());
    }
  }

  String _turnStatusText() {
    if (controller.rules.isOver || controller.clock.hasEnded) {
      if (_computer) {
        final result = _result;
        if (result == GameResult.whiteWins || result == GameResult.blackWins) {
          final humanWon = (result == GameResult.whiteWins) == _humanWhite;
          return humanWon
              ? '${controller.status} · Sen kazandın'
              : '${controller.status} · Bilgisayar kazandı';
        }
      }
      return controller.status;
    }
    if (_computer) {
      if (_computerThinking || controller.rules.whiteToMove != _humanWhite) {
        return 'Bilgisayar düşünüyor…';
      }
      return 'Senin sıran';
    }
    return controller.rules.status;
  }

  void _openMatchActionsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: ListenableBuilder(
            listenable: controller,
            builder: (sheetContext, _) => StatefulBuilder(
              builder: (_, setSheetState) => _matchActions(
                onChanged: () => setSheetState(() {}),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _matchActions({VoidCallback? onChanged}) {
    final ended = controller.rules.isOver || controller.clock.hasEnded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!ended)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('offer-draw'),
                onPressed: _saving || controller.rules.history.isEmpty
                    ? null
                    : _offerDraw,
                icon: const Icon(Icons.handshake_outlined, size: 18),
                label: const Text('Beraberlik teklif et'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('resign-game'),
                onPressed: _saving ? null : _resignGame,
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text('Oyunu terk et'),
              ),
            ],
          )
        else ...[
          const Text(
            'Güzel oyundu.',
            style: TextStyle(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const ValueKey('request-rematch'),
            onPressed: _saving ? null : _rematch,
            icon: const Icon(Icons.replay),
            label: const Text('Tekrar oyna'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('review-finished-game'),
            onPressed: () => showGameReview(
              context,
              initialFen: _initialFen,
              moves: controller.rules.history,
            ),
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('Bu maçtan ne öğrenebilirim?'),
          ),
        ],
        if (ended && !_computer) ...[
          const SizedBox(height: 10),
          const Text(
            'Bu cihazdaki rakibine göster:',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          QuickMessages(
            enabled: _localMessages.length < 12,
            onSend: (code) {
              setState(() => _localMessages.add(code.label));
              onChanged?.call();
            },
          ),
          for (final message in _localMessages.skip(
            _localMessages.length > 4 ? _localMessages.length - 4 : 0,
          ))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(message),
            ),
        ],
      ],
    );
  }

  Widget _gameControls({required bool fullscreen, required bool isLandscape}) {
    final ended = controller.rules.isOver || controller.clock.hasEnded;
    final isSaved = _savedSignature == _signature && _savedSignature != null;
    final draftStore = AppScope.of(context).gameDraft;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!ended && (widget.clockEnabled || controller.clock.isPaused))
              IconButton(
                key: const ValueKey('pause-local-game'),
                tooltip: controller.clock.isPaused ? 'Devam et' : 'Duraklat',
                onPressed: _togglePause,
                icon: Icon(
                  controller.clock.isPaused ? Icons.play_arrow : Icons.pause,
                ),
              ),
            TextButton.icon(
              onPressed:
                  controller.canUndo && !_saving && !controller.clock.isPaused
                  ? _undoMove
                  : null,
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('Geri al'),
            ),
            IconButton(
              key: const ValueKey('save-local-game'),
              tooltip: 'Oyunu kaydet',
              onPressed:
                  _saving ||
                      (controller.rules.history.isEmpty &&
                          !controller.rules.isOver)
                  ? null
                  : _saveGame,
              icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
            ),
            IconButton(
              key: ValueKey(fullscreen ? 'focused-game-sound' : 'game-sound'),
              tooltip: _soundEnabled
                  ? 'Taş seslerini kapat'
                  : 'Taş seslerini aç',
              onPressed: () => setState(() => _soundEnabled = !_soundEnabled),
              icon: Icon(
                _soundEnabled
                    ? Icons.volume_up_outlined
                    : Icons.volume_off_outlined,
              ),
            ),
            if (fullscreen)
              TextButton.icon(
                key: const ValueKey('open-match-actions'),
                onPressed: _openMatchActionsSheet,
                icon: const Icon(Icons.handshake_outlined, size: 18),
                label: const Text('Maç seçenekleri'),
              ),
          ],
        ),
        if (!fullscreen && !isLandscape) ...[
          const SizedBox(height: 4),
          _matchActions(),
        ] else if (!fullscreen && isLandscape) ...[
          const SizedBox(height: 4),
          if (!ended)
            _matchActions()
          else
            FilledButton.tonalIcon(
              key: const ValueKey('open-match-actions'),
              onPressed: _openMatchActionsSheet,
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Maç sonu seçenekleri'),
            ),
        ],
        if (draftStore.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: _checkpoint,
              icon: const Icon(Icons.sync_problem, size: 16),
              label: const Text('Otomatik kayıt başarısız · Yeniden dene'),
            ),
          ),
      ],
    );
  }

  Widget _focusedGame({bool fullscreen = false, bool isLandscape = false}) =>
      FocusedGameLayout(
        key: fullscreen ? const ValueKey('focused-game') : null,
        landscapeHeader: isLandscape && !fullscreen
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BackButton(onPressed: _leave),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          widget.matchmakingFallback
                              ? 'Bilgisayar rakibi'
                              : _computer
                              ? 'Sen ve Bilgisayar'
                              : 'İki kişilik oyun',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (widget.clockEnabled) ...[
                        const SizedBox(width: 4),
                        Text(
                          widget.timeControl.plainLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 20,
                        tooltip: 'Tahtayı çevir',
                        onPressed: () {
                          controller.flip();
                          unawaited(_checkpoint());
                        },
                        icon: const Icon(Icons.flip_camera_android_outlined),
                      ),
                      IconButton(
                        key: const ValueKey('game-fullscreen'),
                        visualDensity: VisualDensity.compact,
                        iconSize: 20,
                        tooltip: _fullscreen ? 'Tam ekrandan çık' : 'Tam ekran',
                        onPressed: () => _setFullscreen(!_fullscreen),
                        icon: Icon(
                          _fullscreen
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                        ),
                      ),
                      const BoardAppearanceButton(),
                    ],
                  ),
                ),
              )
            : null,
        landscapeAd: isLandscape && !fullscreen ? const AdBannerWidget() : null,
        board: ChessBoard(
          controller: controller,
          onSquareTap: controller.clock.isPaused ? null : _tapSquare,
        ),
        topPlayer: _PlayerRow(
          white: controller.flipped,
          computer: _computer,
          humanWhite: _humanWhite,
          rules: controller.rules,
          active:
              !controller.clock.hasEnded &&
              controller.rules.whiteToMove == controller.flipped,
          clockText: widget.clockEnabled
              ? controller.clock.textFor(controller.flipped)
              : null,
          badge: _computer && (controller.flipped != _humanWhite)
              ? _DifficultyBadge(label: widget.difficulty.label)
              : null,
        ),
        bottomPlayer: _PlayerRow(
          white: !controller.flipped,
          computer: _computer,
          humanWhite: _humanWhite,
          rules: controller.rules,
          active:
              !controller.clock.hasEnded &&
              controller.rules.whiteToMove != controller.flipped,
          clockText: widget.clockEnabled
              ? controller.clock.textFor(!controller.flipped)
              : null,
          statusText: isLandscape ? null : _turnStatusText(),
          badge: _computer && (!controller.flipped != _humanWhite)
              ? _DifficultyBadge(label: widget.difficulty.label)
              : null,
        ),
        status: isLandscape
            ? Text(
                _turnStatusText(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              )
            : const SizedBox.shrink(),
        controls: _gameControls(fullscreen: fullscreen, isLandscape: isLandscape),
      );

  Widget _fullscreenBody(BuildContext context, bool isLandscape) {
    final title = widget.matchmakingFallback
        ? 'Bilgisayar rakibi'
        : _computer
        ? 'Sen ve Bilgisayar'
        : 'İki kişilik oyun';
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 48),
          child: _focusedGame(fullscreen: true, isLandscape: isLandscape),
        ),
        Positioned(
          top: 4,
          left: 8,
          right: 8,
          child: FullscreenGameBar(
            title: title,
            onExit: () => _setFullscreen(false),
            onFlip: () {
              controller.flip();
              unawaited(_checkpoint());
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_restoreFailed) {
      return MenuBackScope(
        child: Scaffold(
          appBar: AppBar(
            leading: const MenuBackButton(),
            title: const Text('Yerel oyun'),
          ),
          body: PageLayout(
            eyebrow: 'Kayıt korunuyor',
            title: 'Tahta açılamadı.',
            children: [
              const Text(
                'Kayıtlı hamleler veya saat bilgisi geçersiz. Oyna ekranından yeni oyun açabilir, mevcut maç geçmişini inceleyebilirsin.',
              ),
              OutlinedButton(
                onPressed: () => context.go('/play'),
                child: const Text('Oyna ekranına dön'),
              ),
            ],
          ),
        ),
      );
    }

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return PopScope<Object?>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        bottomNavigationBar: isLandscape || _fullscreen
            ? null
            : const AdBannerWidget(),
        appBar: isLandscape || _fullscreen
            ? null
            : AppBar(
                leading: BackButton(onPressed: _leave),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.matchmakingFallback
                          ? 'Bilgisayar rakibi'
                          : _computer
                          ? 'Sen ve Bilgisayar'
                          : 'İki kişilik oyun',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15),
                    ),
                    if (widget.clockEnabled)
                      Text(
                        widget.timeControl.plainLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
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
                    tooltip: 'Tahtayı çevir',
                    onPressed: () {
                      controller.flip();
                      unawaited(_checkpoint());
                    },
                    icon: const Icon(Icons.flip_camera_android_outlined),
                  ),
                ],
              ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([
              controller,
              AppScope.of(context).boardAppearance,
              AppScope.of(context).gameDraft,
            ]),
            builder: (context, _) => _fullscreen
                ? _fullscreenBody(context, isLandscape)
                : _focusedGame(fullscreen: false, isLandscape: isLandscape),
          ),
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    ),
  );
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.white,
    required this.computer,
    required this.humanWhite,
    required this.rules,
    required this.active,
    this.clockText,
    this.statusText,
    this.badge,
  });

  final bool white;
  final bool computer;
  final bool humanWhite;
  final GameRules rules;
  final bool active;
  final String? clockText;
  final String? statusText;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComputerSide = computer && (white != humanWhite);
    final name = computer
        ? (isComputerSide ? 'Bilgisayar' : 'Sen')
        : (white ? 'Beyaz' : 'Siyah');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: white ? const Color(0xFFF1E7D2) : const Color(0xFF2E3C32),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBDAA8E)),
            ),
            child: Icon(
              isComputerSide ? Icons.smart_toy_outlined : Icons.person_outline,
              size: 18,
              color: white ? const Color(0xFF554932) : const Color(0xFFEBE4D6),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      badge!,
                    ],
                    if (statusText != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          statusText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                CapturedPiecesStrip(rules: rules, forWhite: white),
              ],
            ),
          ),
          if (clockText case final time?) ...[
            const SizedBox(width: 6),
            Container(
              key: ValueKey('clock-${white ? 'white' : 'black'}'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: active
                    ? theme.colorScheme.primary.withValues(alpha: 0.14)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: active
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(width: 6),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}
