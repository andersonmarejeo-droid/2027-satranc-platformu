import 'package:flutter/material.dart';

import '../../../app/app_services.dart';
import '../../../core/widgets/page_layout.dart';
import '../../../core/widgets/online_consent.dart';
import '../../profile/domain/community_membership.dart';
import '../../schools/presentation/community_picker.dart';
import '../domain/leaderboard_repository.dart';
import '../domain/competition_score.dart';

class CommunityRankingsScreen extends StatefulWidget {
  const CommunityRankingsScreen({super.key, required this.repository});
  final CommunityStandingsRepository repository;
  @override
  State<CommunityRankingsScreen> createState() =>
      _CommunityRankingsScreenState();
}

class _CommunityRankingsScreenState extends State<CommunityRankingsScreen> {
  RankingScope _scope = RankingScope.country;
  CommunityMembership? _selection;
  String _period = 'week';
  String? _group;
  CompetitionStandings? _standings;
  bool _loading = false;
  String? _error;
  int _generation = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selection != null) return;
    _selection = AppScope.of(context).membership.value;
    _group = _selection!.groupIds.firstOrNull;
    _scope = _selection!.classId != null
        ? RankingScope.classroom
        : _selection!.schoolId != null
        ? RankingScope.school
        : _selection!.cityId != null
        ? RankingScope.city
        : RankingScope.country;
    if (widget.repository.currentPlayerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  String? get _id => switch (_scope) {
    RankingScope.country => _selection?.countryId ?? 'tr',
    RankingScope.city => _selection?.cityId,
    RankingScope.school => _selection?.schoolId,
    RankingScope.classroom => _selection?.classId,
    RankingScope.group => _group,
  };
  Future<void> _load() async {
    final id = _id, generation = ++_generation;
    if (id == null) {
      setState(() {
        _standings = null;
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _standings = null;
    });
    try {
      final period = _period == 'week'
          ? competitionWeek(DateTime.now())
          : _period == 'month'
          ? competitionMonth(DateTime.now())
          : 'all';
      final result = await widget.repository.load(_scope, id, period);
      if (mounted && generation == _generation) {
        setState(() => _standings = result);
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(
          () => _error =
              'Sıralama yüklenemedi. İnternetini kontrol edip yeniden dene.',
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _connect() async {
    if (!await ensureOnlineConsent(context) || !mounted) return;
    final account = AppScope.of(context).account;
    try {
      if (account != null && account.auth.currentUser == null) {
        await account.auth.signInAnonymously();
      }
    } catch (_) {
      if (mounted) showNotice(context, 'Sıralamaya bağlanılamadı.');
      return;
    }
    if (mounted) await _load();
  }

  Future<void> _joinRanking() async {
    if (!await ensureOnlineConsent(context) || !mounted) return;
    final account = AppScope.of(context).account;
    final profile = AppScope.of(context).profile;

    if (account == null) {
      if (mounted) showNotice(context, 'Sıralama bağlantısı kurulamadı.');
      return;
    }

    if (account.auth.currentUser == null) {
      try {
        await account.auth.signInAnonymously();
      } catch (_) {
        if (mounted) showNotice(context, 'Sıralama sunucusuna bağlanılamadı.');
        return;
      }
    }

    final currentName = profile.profile?.displayName ?? '';
    if (currentName.isEmpty || currentName == 'Misafir oyuncu') {
      if (!mounted) return;
      final nameController = TextEditingController();
      final enteredName = await showDialog<String>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Sıralamaya Katıl'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Liderlik tablosunda görünecek adını ve soyadını yaz:'),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Adın ve Soyadın',
                  hintText: 'Örn: Ahmet Yılmaz',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogCtx, nameController.text.trim()),
              child: const Text('Katıl'),
            ),
          ],
        ),
      );
      if (enteredName == null || enteredName.isEmpty || !mounted) return;
      await profile.saveDisplayName(enteredName);
    }

    try {
      await account.setRanking(true);
      if (mounted) {
        showNotice(context, 'Sıralamaya başarıyla katıldın!');
        await _load();
      }
    } catch (_) {
      if (mounted) {
        showNotice(context, account.error ?? 'Sıralamaya katılınamadı.');
      }
    }
  }

  Future<void> _pick() async {
    var value = _selection!;
    if (_scope == RankingScope.country) return;
    if ((_scope == RankingScope.school || _scope == RankingScope.classroom) &&
        value.cityId == null) {
      final city = await showCommunityPicker(
        context,
        kind: CommunityKind.city,
        parentId: value.countryId ?? 'tr',
      );
      if (city == null || city.isEmpty || !mounted) return;
      value = value.select(CommunityKind.city, city);
      setState(() => _selection = value);
    }
    if (_scope == RankingScope.classroom && value.schoolId == null) {
      final school = await showCommunityPicker(
        context,
        kind: CommunityKind.school,
        parentId: value.cityId,
      );
      if (school == null || school.isEmpty || !mounted) return;
      value = value.select(CommunityKind.school, school);
      setState(() => _selection = value);
    }
    String? id;
    if (_scope == RankingScope.classroom && value.schoolId != null) {
      id = await showClassroomPicker(
        context,
        schoolId: value.schoolId!,
        selectedId: value.classId,
      );
    } else {
      final kind = switch (_scope) {
        RankingScope.city => CommunityKind.city,
        RankingScope.group => CommunityKind.group,
        _ => CommunityKind.school,
      };
      id = await showCommunityPicker(
        context,
        kind: kind,
        parentId: kind == CommunityKind.city
            ? value.countryId ?? 'tr'
            : kind == CommunityKind.school
            ? value.cityId
            : null,
        selectedId: _id,
      );
    }
    if (id == null || id.isEmpty || !mounted) return;
    setState(() {
      final kind = switch (_scope) {
        RankingScope.city => CommunityKind.city,
        RankingScope.group => CommunityKind.group,
        _ =>
          id!.startsWith('class:') ||
                  CommunityDirectory.find(id)?.kind == CommunityKind.classroom
              ? CommunityKind.classroom
              : CommunityKind.school,
      };
      if (kind == CommunityKind.group) {
        _group = id;
      } else {
        _selection = _selection!.select(kind, id);
      }
    });
    if (widget.repository.currentPlayerId != null) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final signed = widget.repository.currentPlayerId != null,
        own = _standings?.own;
    final name = CommunityDirectory.find(_id)?.name ?? 'Seçim yap';
    return RefreshIndicator(
      onRefresh: signed ? _load : _connect,
      child: PageLayout(
        eyebrow: 'Topluluk puanı',
        title: _period == 'week' ? 'Haftanın kupası.' : 'Tahtanın liderleri.',
        subtitle: 'Gerçek maç sonuçları · Kazanç 3, beraberlik 1 puan',
        trailing: IconButton(
          tooltip: 'Sıralamayı yenile',
          onPressed: _loading
              ? null
              : signed
              ? _load
              : _connect,
          icon: const Icon(Icons.refresh),
        ),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final entry in const {
                      RankingScope.classroom: 'Sınıfım',
                      RankingScope.school: 'Okulum',
                      RankingScope.city: 'Şehrim',
                      RankingScope.country: 'Türkiye',
                      RankingScope.group: 'Gruplar',
                    }.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _scope == entry.key,
                        onSelected: (_) {
                          setState(() => _scope = entry.key);
                          if (signed) _load();
                        },
                      ),
                  ],
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _scope == RankingScope.group
                        ? Icons.groups_outlined
                        : Icons.school_outlined,
                  ),
                  title: Text(name),
                  subtitle: Text(
                    _scope == RankingScope.group
                        ? 'Gruplar okul seçiminden bağımsızdır.'
                        : _selection!.path,
                  ),
                  trailing: _scope == RankingScope.country
                      ? null
                      : const Icon(Icons.expand_more),
                  onTap: _scope == RankingScope.country ? null : _pick,
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final p in const {
                      'week': 'Bu hafta',
                      'month': 'Bu ay',
                      'all': 'Tüm zamanlar',
                    }.entries)
                      ChoiceChip(
                        label: Text(p.value),
                        selected: _period == p.key,
                        onSelected: (_) {
                          setState(() => _period = p.key);
                          if (signed) _load();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const ValueKey('my-live-rank'),
            onPressed: () async {
              setState(() {
                _selection = AppScope.of(context).membership.value;
                _scope = _selection!.classId != null
                    ? RankingScope.classroom
                    : _selection!.schoolId != null
                    ? RankingScope.school
                    : _selection!.cityId != null
                    ? RankingScope.city
                    : RankingScope.country;
              });
              if (signed) {
                await _load();
              } else {
                await _connect();
              }
            },
            icon: const Icon(Icons.my_location),
            label: const Text('Benim sıram'),
          ),
          if (!signed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton(
                onPressed: _connect,
                child: const Text('Sıralamaları aç'),
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            SurfaceCard(
              child: Column(
                children: [
                  Text(_error!),
                  TextButton(
                    onPressed: _load,
                    child: const Text('Yeniden dene'),
                  ),
                ],
              ),
            ),
          if (signed && !_loading && _error == null) ...[
            const SizedBox(height: 8),
            SurfaceCard(
              child: own == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _id == null
                              ? 'Önce okulunu veya sınıfını seç.'
                              : 'Bu seçimde henüz puanın yok.',
                        ),
                        TextButton(
                          onPressed: _id == null ? _pick : _joinRanking,
                          child: Text(
                            _id == null
                                ? 'Topluluğumu seç'
                                : 'Sıralamaya katıl',
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(Icons.emoji_events_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${_standings!.rank}. sıradasın · ${own.points} puan\n${own.games} maç · ${own.wins} galibiyet',
                          ),
                        ),
                      ],
                    ),
            ),
            const SectionTitle('Oyuncular'),
            if (_standings?.players.isEmpty ?? true)
              const Text('Henüz sonuç yok. İlk maçlarla bu liste oluşacak.'),
            for (final (index, player)
                in (_standings?.players ?? <CompetitionScore>[]).indexed)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: SizedBox(
                  width: 32,
                  child: Text(
                    '${index + 1}.',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                title: Text(
                  player.uid == widget.repository.currentPlayerId
                      ? '${player.alias} · Sen'
                      : player.alias,
                ),
                subtitle: Text(
                  '${player.games} maç · ${player.wins} galibiyet',
                ),
                trailing: Text('${player.points} puan'),
              ),
            if (_standings?.hasMore == true)
              const Text(
                'İlk 100 oyuncu gösterilir; kendi sıran tüm oyuncular üzerinden hesaplanır.',
              ),
          ],
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              tilePadding: EdgeInsets.zero,
              leading: Icon(
                Icons.info_outline,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Puanlama ve kural bilgisi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 8),
                  child: Text(
                    'Sonuçlar iki oyuncunun uygulamasında doğrulanır. Okul ve sınıf üyeliği oyuncunun beyanıdır. Puan bir Elo derecesi değildir. Haftalık kupa pazartesi Türkiye saatiyle yenilenir.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
