import 'package:flutter/material.dart';

import '../../../core/routing/menu_back.dart';

import 'package:go_router/go_router.dart';

import '../../../app/app_services.dart';
import '../../../core/widgets/page_layout.dart';
import '../domain/saved_game.dart';
import 'saved_game_summary.dart';

class GameHistoryScreen extends StatefulWidget {
  const GameHistoryScreen({super.key});
  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen> {
  Future<List<SavedGame>>? _games;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _games ??= AppScope.of(context).gameHistory.list();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const MenuBackButton(),
      title: const Text('Maç geçmişi'),
    ),
    body: FutureBuilder<List<SavedGame>>(
      future: _games,
      builder: (context, snapshot) => PageLayout(
        eyebrow: 'Tahtana yeniden bak',
        title: 'Kaydettiğin oyunlar.',
        subtitle: 'Son 100 yerel oyun bu cihazda saklanır. Hamleleri inceleyebilir, PGN metnini kopyalayabilirsin.',
        children: [
          if (snapshot.connectionState != ConnectionState.done)
            const Center(child: CircularProgressIndicator())
          else if (snapshot.hasError)
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Maç geçmişi açılamadı. Yeniden deneyebilirsin.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _games = AppScope.of(context).gameHistory.list();
                    }),
                    child: const Text('Yeniden dene'),
                  ),
                ],
              ),
            )
          else if (snapshot.data!.isEmpty)
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.history,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text('Henüz kaydedilmiş oyun yok.'),
                  const SizedBox(height: 8),
                  const Text(
                    'Yerel tahtada birkaç hamle oyna, ardından “Oyunu kaydet” düğmesini kullan.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/play'),
                    child: const Text('Oyna ekranına git'),
                  ),
                ],
              ),
            )
          else
            for (final game in snapshot.data!) ...[
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  key: ValueKey('saved-game-${game.id}'),
                  leading: const Icon(Icons.view_module_outlined),
                  title: Text(game.result.label),
                  subtitle: Text(
                    '${savedGameDate(game)}\n${savedGameSummary(game)}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/history/${game.id}'),
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    ),
  );
}
