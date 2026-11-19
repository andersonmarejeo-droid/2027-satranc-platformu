import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_services.dart';
import '../../../core/routing/menu_back.dart';
import '../../../core/widgets/page_layout.dart';
import '../../challenges/domain/online_challenge_repository.dart';
import '../domain/match_snapshot.dart';

class OnlineGamesScreen extends StatefulWidget {
  const OnlineGamesScreen({super.key});
  @override
  State<OnlineGamesScreen> createState() => _OnlineGamesScreenState();
}

class _OnlineGamesScreenState extends State<OnlineGamesScreen> {
  Future<List<OnlineMatchSummary>>? _games;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _games ??= _loadSummaries();
  }

  Future<List<OnlineMatchSummary>> _loadSummaries() {
    final repo = AppScope.of(context).challenges;
    return repo is OnlineChallengeRepository
        ? repo.recentMatchSummaries()
        : Future.value(const []);
  }

  void _reload() {
    setState(() => _games = _loadSummaries());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const MenuBackButton(),
      title: const Text('Çevrim içi maçlarım'),
      actions: [
        IconButton(
          tooltip: 'Listeyi yenile',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<OnlineMatchSummary>>(
      future: _games,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Maçlar alınamadı. İnternet bağlantını kontrol et.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Yeniden dene'),
                  ),
                ],
              ),
            ),
          );
        }
        final summaries = snapshot.data ?? const [];
        if (summaries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Henüz çevrim içi maçın yok. Oyna ekranından başlayabilirsin.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            final future = _loadSummaries();
            setState(() => _games = future);
            await future;
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: summaries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _OnlineMatchCard(
              summary: summaries[index],
              onTap: () => context.push('/online-match/${summaries[index].id}'),
            ),
          ),
        );
      },
    ),
  );
}

class _OnlineMatchCard extends StatelessWidget {
  const _OnlineMatchCard({required this.summary, required this.onTap});

  final OnlineMatchSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shortId = summary.id.length > 8
        ? summary.id.substring(0, 8)
        : summary.id;
    final isWhite = summary.playerColor == MatchColor.white;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        key: ValueKey('online-game-card-${summary.id}'),
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isWhite
                      ? const Color(0xFFF1E7D2)
                      : const Color(0xFF2E3C32),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBDAA8E)),
                ),
                child: Icon(
                  summary.status == MatchStatus.active
                      ? Icons.sports_esports_outlined
                      : Icons.flag_outlined,
                  color: isWhite
                      ? const Color(0xFF554932)
                      : const Color(0xFFEBE4D6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            summary.statusLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: summary.isMyTurn
                                  ? scheme.primary
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(summary.updatedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isWhite ? 'Beyaz' : 'Siyah'} · ${summary.timeControl.label} · ${summary.ply} yarım hamle',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Maç $shortId',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
  }
}
