import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_services.dart';
import '../../../core/widgets/page_layout.dart';
import '../domain/time_control.dart';
import '../domain/game_result.dart';
import '../domain/saved_game.dart';
import '../domain/computer_difficulty.dart';
import 'game_draft_controller.dart';
import 'saved_game_summary.dart';
import 'quick_play_controller.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});
  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  TimeControl selected = const TimeControl(10, 0);
  ComputerDifficulty difficulty = ComputerDifficulty.easy;
  PlayerSideChoice side = PlayerSideChoice.white;
  bool clockEnabled = false, _starting = false;
  bool _preferencesLoaded = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preferencesLoaded) return;
    _preferencesLoaded = true;
    final choice = AppScope.of(context).quickPlay?.value;
    if (choice != null) {
      selected = choice.time;
      difficulty = choice.difficulty;
      side = choice.side;
      clockEnabled = choice.clockEnabled;
    }
  }

  Future<void> _startGame(
    GameDraftController store,
    GameOpponent opponent,
  ) async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      if (store.draft != null || store.hasError) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Yeni yerel oyun?'),
            content: const Text(
              'Yeni tahta, devam edebileceğin son yerel oyunun yerini alacak. Maç geçmişine kaydettiğin oyunlar korunur.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yeni oyun'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await store.clear();
      }
      if (!mounted) return;
      final time = selected;
      await AppScope.of(context).quickPlay?.save(
        QuickPlayChoice(
          mode: opponent == GameOpponent.computer
              ? QuickPlayMode.computer
              : QuickPlayMode.twoPlayers,
          time: time,
          clockEnabled: clockEnabled,
          difficulty: difficulty,
          side: side,
        ),
      );
      if (!mounted) return;
      final playWhite = opponent != GameOpponent.computer
          ? true
          : switch (side) {
              PlayerSideChoice.white => true,
              PlayerSideChoice.black => false,
              PlayerSideChoice.random => Random().nextBool(),
            };
      context.push(
        '/game?minutes=${time.minutes}&increment=${time.incrementSeconds}&clock=${clockEnabled ? 'on' : 'off'}&opponent=${opponent.name}&difficulty=${difficulty.name}${!playWhite ? '&playerColor=black' : ''}',
      );
    } catch (_) {
      if (mounted) {
        showNotice(context, 'Yeni tahta açılamadı. Yerel kaydı yeniden dene.');
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).gameDraft;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _page(context, store),
    );
  }

  Widget _page(BuildContext context, GameDraftController store) {
    final ready = !_starting && !store.isLoading;
    final online = AppScope.of(context).matchmaking != null;
    return PageLayout(
      compact: true,
      eyebrow: 'Hızlı Başlat',
      title: 'Oyun Modu',
      subtitle: 'Modunu seç, tek dokunuşla tahtaya geç.',
      children: [
        if (store.draft case final draft?) ...[
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.history_toggle_off, color: Color(0xFFD4AF37), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.game.result == GameResult.unfinished
                            ? 'Yarım kalan yerel oyunun var'
                            : 'Son oyun tahtası hazır',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      Text(
                        savedGameSummary(draft.game),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                FilledButton.tonalIcon(
                  key: const ValueKey('resume-local-game'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: ready ? () => context.push('/game?resume=1') : null,
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: Text(
                    draft.game.result == GameResult.unfinished ? 'Devam et' : 'Tahtaya dön',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        ActionCard(
          key: const ValueKey('start-computer-game'),
          dense: true,
          icon: Icons.smart_toy_outlined,
          title: 'Bilgisayara karşı oyna',
          subtitle: clockEnabled
              ? '${difficulty.label} · ${selected.plainLabel} · İnternetsiz'
              : '${difficulty.label} · İnternetsiz oyna',
          highlighted: true,
          onPressed: ready ? () => _startGame(store, GameOpponent.computer) : null,
        ),
        const SizedBox(height: 5),
        ActionCard(
          key: const ValueKey('start-online-game'),
          dense: true,
          icon: Icons.public_outlined,
          title: 'Çevrim içi rakip bul',
          subtitle: online
              ? (clockEnabled
                    ? 'Canlı rakiple eşleş · ${selected.plainLabel}'
                    : 'Önce süre seç, ardından oyna')
              : 'Canlı oyuncularla oyun yakında',
          onPressed: online && ready
              ? () async {
                  if (!clockEnabled) {
                    setState(() => clockEnabled = true);
                    showNotice(
                      context,
                      'Çevrim içi oyun için bir süre seç, ardından oyna.',
                    );
                    return;
                  }
                  final time = selected;
                  try {
                    await AppScope.of(context).quickPlay?.save(
                      QuickPlayChoice(
                        mode: QuickPlayMode.online,
                        time: time,
                        clockEnabled: true,
                        difficulty: difficulty,
                        side: side,
                      ),
                    );
                  } catch (_) {
                    if (context.mounted) {
                      showNotice(context, 'Oyun tercihi kaydedilemedi.');
                    }
                    return;
                  }
                  if (!context.mounted) return;
                  context.push(
                    '/matchmaking?minutes=${time.minutes}&increment=${time.incrementSeconds}&start=1',
                  );
                }
              : null,
        ),
        const SizedBox(height: 5),
        ActionCard(
          key: const ValueKey('start-game'),
          dense: true,
          icon: Icons.people_outline,
          title: 'İki kişi oyna',
          subtitle: 'Aynı telefonda sırayla hamle yapın',
          onPressed: ready ? () => _startGame(store, GameOpponent.twoPlayers) : null,
        ),
        const SizedBox(height: 8),
        SurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zorluk: ${difficulty.label}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                difficulty.description,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 5,
                runSpacing: 4,
                children: [
                  for (final level in ComputerDifficulty.values)
                    ChoiceChip(
                      key: ValueKey('difficulty-${level.name}'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelStyle: const TextStyle(fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      label: Text(level.label),
                      selected: difficulty == level,
                      onSelected: ready ? (_) => setState(() => difficulty = level) : null,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Taş Rengi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 5),
              Wrap(
                spacing: 5,
                runSpacing: 4,
                children: [
                  for (final entry in const {
                    PlayerSideChoice.white: 'Beyaz',
                    PlayerSideChoice.black: 'Siyah',
                    PlayerSideChoice.random: 'Rastgele',
                  }.entries)
                    ChoiceChip(
                      key: ValueKey('side-${entry.key.name}'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelStyle: const TextStyle(fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      label: Text(entry.value),
                      selected: side == entry.key,
                      onSelected: ready ? (_) => setState(() => side = entry.key) : null,
                    ),
                ],
              ),
              const Divider(height: 16),
              const Text('Oyun Süresi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 5),
              Wrap(
                spacing: 5,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    key: const ValueKey('time-unlimited'),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelStyle: const TextStyle(fontSize: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    label: const Text('Süresiz'),
                    selected: !clockEnabled,
                    onSelected: ready ? (_) => setState(() => clockEnabled = false) : null,
                  ),
                  for (final time in TimeControl.presets)
                    _timeChoice(time, ready),
                ],
              ),
              const SizedBox(height: 2),
              ExpansionTile(
                key: const ValueKey('more-time-controls'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                shape: const Border(),
                collapsedShape: const Border(),
                dense: true,
                visualDensity: VisualDensity.compact,
                title: const Text(
                  'Diğer süreler',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Kısa süreler', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                  ),
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 5,
                      runSpacing: 2,
                      children: [
                        for (final time in TimeControl.shorterPresets)
                          _timeChoice(time, ready),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Daha uzun süreler', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                  ),
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 5,
                      runSpacing: 2,
                      children: [
                        for (final time in TimeControl.longerPresets)
                          _timeChoice(time, ready),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Hamle başı ek süreli', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                  ),
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 5,
                      runSpacing: 2,
                      children: [
                        for (final time in TimeControl.tournamentPresets)
                          _timeChoice(time, ready),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (online) ...[
          const SizedBox(height: 6),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => context.push('/challenges'),
                  icon: const Icon(Icons.send_outlined, size: 15),
                  label: const Text('Meydan oku', style: TextStyle(fontSize: 12)),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => context.push('/online-games'),
                  icon: const Icon(Icons.history, size: 15),
                  label: const Text('Çevrim içi maçlarım', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _timeChoice(TimeControl time, bool ready) => ChoiceChip(
    key: ValueKey('time-${time.minutes}-${time.incrementSeconds}'),
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    labelStyle: const TextStyle(fontSize: 12),
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    label: Text(
      time.incrementSeconds == 0
          ? '${time.minutes} dk'
          : '${time.minutes} dk · ${time.incrementSeconds} sn',
    ),
    selected:
        clockEnabled &&
        selected.minutes == time.minutes &&
        selected.incrementSeconds == time.incrementSeconds,
    onSelected: ready
        ? (_) => setState(() {
            selected = time;
            clockEnabled = true;
          })
        : null,
  );
}
