import 'package:flutter/material.dart';

import '../../../core/routing/menu_back.dart';

import 'package:flutter/services.dart';

import '../../../app/app_services.dart';
import '../../../core/widgets/page_layout.dart';
import '../data/local_game_playback.dart';
import '../domain/saved_game.dart';
import 'game_replay_controller.dart';
import 'saved_game_summary.dart';
import 'game_review_sheet.dart';
import 'widgets/chess_board.dart';
import '../../settings/presentation/board_appearance_controls.dart';

class GameReplayScreen extends StatefulWidget {
  const GameReplayScreen({super.key, required this.gameId});
  final String gameId;
  @override
  State<GameReplayScreen> createState() => _GameReplayScreenState();
}

class _GameReplayScreenState extends State<GameReplayScreen> {
  Future<SavedGame?>? _loading;
  GameReplayController? _controller;
  int _loadGeneration = 0;

  @override
  void didUpdateWidget(GameReplayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId) {
      _controller?.dispose();
      _controller = null;
      _loading = _load();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loading ??= _load();
  }

  Future<SavedGame?> _load() async {
    final id = widget.gameId;
    final generation = ++_loadGeneration;
    final games = await AppScope.of(context).gameHistory.list();
    if (!mounted || generation != _loadGeneration) return null;
    final game = games.where((game) => game.id == id).firstOrNull;
    if (game == null) return null;
    final playback = LocalGamePlayback(game);
    if (!mounted) return null;
    _controller = GameReplayController(playback);
    return game;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const MenuBackButton(),
      title: const Text('Oyun incelemesi'),
      actions: const [BoardAppearanceButton()],
    ),
    body: FutureBuilder<SavedGame?>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return PageLayout(
            eyebrow: 'Maç geçmişi',
            title: 'Oyun açılamadı.',
            children: [
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.hasError
                          ? 'Kayıt okunamadı veya hamle bilgisi geçersiz. Diğer kayıtlarını geçmiş ekranından açabilirsin.'
                          : 'Bu oyun bu cihazda bulunamadı.',
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        _controller?.dispose();
                        _controller = null;
                        setState(() => _loading = _load());
                      },
                      child: const Text('Yeniden dene'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        final game = snapshot.data!;
        final controller = _controller!;
        return SafeArea(
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DemoLabel(text: game.result.label),
                      const SizedBox(height: 12),
                      Text(savedGameDate(game)),
                      Text(savedGameSummary(game)),
                      if (game.result.name != 'unfinished')
                        TextButton.icon(
                          onPressed: () => showGameReview(
                            context,
                            initialFen: game.initialFen,
                            moves: game.moves,
                          ),
                          icon: const Icon(Icons.lightbulb_outline),
                          label: const Text('Bu maçtan ne öğrenebilirim?'),
                        ),
                      const SizedBox(height: 18),
                      ChessBoard(controller: controller),
                      const SizedBox(height: 18),
                      Center(
                        child: Text(
                          controller.index == 0
                              ? 'Başlangıç konumu'
                              : '${controller.index} / ${game.moves.length} · ${game.moves[controller.index - 1]}',
                          key: const ValueKey('replay-position'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'İlk konum',
                              onPressed: controller.index == 0
                                  ? null
                                  : () => controller.seek(0),
                              icon: const Icon(Icons.first_page),
                            ),
                            IconButton(
                              tooltip: 'Önceki hamle',
                              onPressed: controller.index == 0
                                  ? null
                                  : () => controller.seek(controller.index - 1),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            IconButton(
                              tooltip: 'Sonraki hamle',
                              onPressed: controller.index == game.moves.length
                                  ? null
                                  : () => controller.seek(controller.index + 1),
                              icon: const Icon(Icons.chevron_right),
                            ),
                            IconButton(
                              tooltip: 'Son konum',
                              onPressed: controller.index == game.moves.length
                                  ? null
                                  : () => controller.seek(game.moves.length),
                              icon: const Icon(Icons.last_page),
                            ),
                            IconButton(
                              tooltip: 'Tahtayı çevir',
                              onPressed: controller.flip,
                              icon: const Icon(
                                Icons.flip_camera_android_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await Clipboard.setData(
                              ClipboardData(text: controller.playback.pgn),
                            );
                            if (context.mounted) {
                              showNotice(context, 'PGN metni kopyalandı.');
                            }
                          } catch (_) {
                            if (context.mounted) {
                              showNotice(
                                context,
                                'PGN kopyalanamadı. Yeniden dene.',
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('PGN kopyala'),
                      ),
                      const SectionTitle('Hamleler'),
                      SurfaceCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < game.moves.length; i++)
                              ChoiceChip(
                                label: Text(
                                  '${i ~/ 2 + 1}${i.isEven ? '.' : '...'} ${game.moves[i]}',
                                ),
                                selected: controller.index == i + 1,
                                onSelected: (_) => controller.seek(i + 1),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Kayıt incelemesi · hamleleri izlerken kayıt değişmez.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
