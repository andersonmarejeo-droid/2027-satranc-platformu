import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_services.dart';
import '../../../core/widgets/page_layout.dart';
import '../../profile/domain/community_membership.dart';
import '../../profile/presentation/community_membership_controller.dart';
import '../domain/leaderboard_repository.dart';
import '../domain/competition_score.dart';
import 'community_rankings_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  RankingScope _scope = RankingScope.country;
  String _country = 'tr';
  String? _city, _school, _classroom, _group;
  bool _initialized = false;
  final _myRankKey = GlobalKey();
  late CommunityMembershipController _membership;
  String _communityQuery = '';
  int _visibleCommunities = 40;
  String? _communityListKey;
  List<CommunityNode> _communityList = [];
  final _communitySearch = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _membership = AppScope.of(context).membership;
      _useMyCommunity(navigate: true);
      _membership.addListener(_membershipChanged);
      _initialized = true;
    }
  }

  void _membershipChanged() {
    if (mounted && !_membership.saving) {
      setState(() => _useMyCommunity(navigate: true));
    }
  }

  @override
  void dispose() {
    _membership.removeListener(_membershipChanged);
    _communitySearch.dispose();
    super.dispose();
  }

  void _useMyCommunity({bool navigate = false}) {
    final value = AppScope.of(context).membership.value;
    _country = value.countryId ?? 'tr';
    _city = value.cityId;
    _school = value.schoolId;
    _classroom = value.classId;
    _group = value.groupIds.firstOrNull;
    if (navigate) {
      _scope = _classroom != null
          ? RankingScope.classroom
          : _school != null
          ? RankingScope.school
          : _city != null
          ? RankingScope.city
          : RankingScope.country;
    }
  }

  void _selectScope(RankingScope scope) {
    _clearSearch();
    _scope = scope;
    switch (scope) {
      case RankingScope.city:
        _city = _school = _classroom = null;
      case RankingScope.school:
        _school = _classroom = null;
      case RankingScope.group:
        _group = null;
      default:
        break;
    }
  }

  String _name(String? id) => CommunityDirectory.find(id)?.name ?? '';
  String get _path =>
      (_scope == RankingScope.group
              ? [_group]
              : _scope == RankingScope.country
              ? [_country]
              : _scope == RankingScope.city
              ? [_country, _city]
              : [
                  _country,
                  _city,
                  _school,
                  if (_scope == RankingScope.classroom) _classroom,
                ])
          .map(_name)
          .where((s) => s.isNotEmpty)
          .join(' › ');

  void _backToList() {
    _clearSearch();
    switch (_scope) {
      case RankingScope.city:
        _city = _school = _classroom = null;
      case RankingScope.school:
        _school = _classroom = null;
      case RankingScope.classroom:
        _classroom = null;
      case RankingScope.group:
        _group = null;
      default:
        break;
    }
  }

  void _clearSearch() {
    _communityQuery = '';
    _communitySearch.clear();
    _visibleCommunities = 40;
  }

  void _backOneLevel() {
    if (_scope == RankingScope.classroom && _classroom != null) {
      setState(() => _classroom = null);
    } else if (_scope == RankingScope.classroom && _school != null) {
      setState(() => _scope = RankingScope.school);
    } else if ((_scope == RankingScope.school && _school != null) ||
        (_scope == RankingScope.city && _city != null) ||
        (_scope == RankingScope.group && _group != null)) {
      setState(_backToList);
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.of(context).leaderboard;
    if (repository is CommunityStandingsRepository) {
      return CommunityRankingsScreen(repository: repository);
    }
    final selectedId = switch (_scope) {
      RankingScope.country => _country,
      RankingScope.city => _city,
      RankingScope.school => _school,
      RankingScope.classroom => _classroom,
      RankingScope.group => _group,
    };
    final players =
        selectedId == null
              ? <RankingEntry>[]
              : [...repository.entries(_scope, id: selectedId)]
          ..sort((a, b) {
            final score = b.rating.compareTo(a.rating);
            return score != 0 ? score : a.name.compareTo(b.name);
          });
    final ownId = repository.currentPlayerId;
    final myIndex = ownId == null
        ? -1
        : players.indexWhere((p) => p.playerId == ownId);
    final communityListKey = '$_scope/$_country/$_city/$_school';
    if (_communityListKey != communityListKey) {
      _communityList = switch (_scope) {
        RankingScope.city => CommunityDirectory.children(
          CommunityKind.city,
          _country,
        ),
        RankingScope.school =>
          CommunityDirectory.schoolOptions(_city)
              .where(
                (n) =>
                    _city != null ||
                    CommunityDirectory.belongsTo(n.id, _country),
              )
              .toList(),
        RankingScope.classroom =>
          _school == null
              ? <CommunityNode>[]
              : CommunityDirectory.children(CommunityKind.classroom, _school),
        RankingScope.group => CommunityDirectory.children(
          CommunityKind.group,
          null,
        ),
        _ => <CommunityNode>[],
      };
      _communityListKey = communityListKey;
    }
    int average(CommunityNode node) {
      final entries = repository.entries(_scope, id: node.id);
      return entries.isEmpty
          ? 0
          : (entries.fold<int>(0, (sum, p) => sum + p.rating) / entries.length)
                .round();
    }

    final communities = _communityList
        .where((node) => CommunityDirectory.matches(node, _communityQuery))
        .toList();
    final scores = {for (final node in communities) node.id: average(node)};
    communities.sort((a, b) {
      final score = scores[b.id]!.compareTo(scores[a.id]!);
      return score != 0 ? score : a.name.compareTo(b.name);
    });
    final inSchool =
        (_scope == RankingScope.school || _scope == RankingScope.classroom) &&
        _school != null;
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backOneLevel();
      },
      child: PageLayout(
        eyebrow: 'Her hamle bir adım',
        title: 'Kendi çevrende yüksel.',
        subtitle: 'Okulunu, sınıfını veya grubunu seç; kendi yerini bul.',
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey('ranking-country-$_country'),
            initialValue: _country,
            decoration: const InputDecoration(labelText: 'Ülke'),
            isExpanded: true,
            items: [
              for (final n in CommunityDirectory.children(
                CommunityKind.country,
                null,
              ))
                DropdownMenuItem(value: n.id, child: Text(n.name)),
            ],
            onChanged: (id) {
              if (id != null) {
                setState(() {
                  _clearSearch();
                  _country = id;
                  _city = _school = _classroom = null;
                  if (_scope == RankingScope.classroom) {
                    _scope = RankingScope.school;
                  }
                });
              }
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in [
                RankingScope.country,
                RankingScope.city,
                RankingScope.school,
                RankingScope.group,
              ])
                ChoiceChip(
                  key: ValueKey('ranking-${s.name}'),
                  label: Text(s.label),
                  selected:
                      _scope == s ||
                      (s == RankingScope.school &&
                          _scope == RankingScope.classroom),
                  onSelected: (_) => setState(() => _selectScope(s)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _path.isEmpty ? _scope.label : _path,
                        key: const ValueKey('ranking-path'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('ranking-my-community'),
                      tooltip: 'Kendi okul ve sınıfımı göster',
                      onPressed: () =>
                          setState(() => _useMyCommunity(navigate: true)),
                      icon: const Icon(Icons.my_location, size: 20),
                    ),
                  ],
                ),
                if (repository.isDemo)
                  const DemoLabel(
                    text: 'Örnek sıralama · Canlı puanlar henüz açık değil',
                  ),
              ],
            ),
          ),
          if ((_scope == RankingScope.school ||
                  _scope == RankingScope.classroom) &&
              _city != null)
            TextButton(
              key: const ValueKey('ranking-all-schools'),
              onPressed: () => setState(() {
                _clearSearch();
                _scope = RankingScope.school;
                _city = _school = _classroom = null;
              }),
              child: const Text('Ülkedeki tüm okulları göster'),
            ),
          if (inSchool) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  key: const ValueKey('ranking-all-classes'),
                  label: const Text('Okuldaki oyuncular'),
                  selected: _scope == RankingScope.school,
                  onSelected: (_) => setState(() {
                    _scope = RankingScope.school;
                    _classroom = null;
                  }),
                ),
                ChoiceChip(
                  key: const ValueKey('ranking-school-classes'),
                  label: const Text('Sınıfların sıralaması'),
                  selected: _scope == RankingScope.classroom,
                  onSelected: (_) => setState(() {
                    _scope = RankingScope.classroom;
                    _classroom = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Sınıflar yalnızca seçili okulun içinde karşılaştırılır.',
              style: TextStyle(fontSize: 12),
            ),
          ],
          if (selectedId == null) ...[
            SectionTitle('${_scope.label} sıralaması'),
            Text(
              _scope == RankingScope.classroom
                  ? 'Sınıfının adına dokun; arkadaşların arasındaki sıralamayı gör.'
                  : 'Bir topluluk seç; içindeki oyuncuları gör.',
            ),
            const SizedBox(height: 4),
            Text(
              repository.isDemo
                  ? 'Ortalama örnek oyuncu puanına göre sıralanır.'
                  : 'Oyuncuların ortalama puanına göre sıralanır.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (communities.isEmpty)
              const SurfaceCard(child: Text('Bu aramada topluluk bulunamadı.')),
            if (_communityList.length > 12) ...[
              TextField(
                key: const ValueKey('ranking-community-search'),
                controller: _communitySearch,
                decoration: const InputDecoration(
                  hintText: 'Şehir, okul veya ilçe ara',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (query) => setState(() {
                  _communityQuery = query;
                  _visibleCommunities = 40;
                }),
              ),
              const SizedBox(height: 8),
              Text(
                '${communities.length} topluluk',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
            ],
            if (communities.isNotEmpty)
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (
                      var i = 0;
                      i < communities.length && i < _visibleCommunities;
                      i++
                    ) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        key: ValueKey(
                          _scope == RankingScope.classroom
                              ? 'ranking-class-${communities[i].id}'
                              : 'ranking-community-${communities[i].id}',
                        ),
                        leading: _RankBadge(rank: i + 1),
                        title: Text(communities[i].name),
                        subtitle: Text(
                          '${communities[i].location.isEmpty ? '' : '${communities[i].location} · '}${repository.entries(_scope, id: communities[i].id).isEmpty ? 'Henüz oyuncu yok' : '${repository.entries(_scope, id: communities[i].id).length} oyuncu · ${average(communities[i])} ortalama puan'}',
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => setState(() {
                          _clearSearch();
                          final node = communities[i];
                          switch (_scope) {
                            case RankingScope.city:
                              _city = node.id;
                              _school = _classroom = null;
                            case RankingScope.school:
                              _school = node.id;
                              _city = node.parentId;
                              _classroom = null;
                            case RankingScope.classroom:
                              _classroom = node.id;
                            case RankingScope.group:
                              _group = node.id;
                            default:
                              break;
                          }
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            if (communities.length > _visibleCommunities)
              TextButton(
                key: const ValueKey('ranking-show-more'),
                onPressed: () => setState(() => _visibleCommunities += 40),
                child: const Text('Daha fazla göster'),
              ),
          ] else ...[
            if (_scope != RankingScope.country)
              TextButton.icon(
                key: const ValueKey('ranking-back-to-list'),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text('${_scope.label} listesine dön'),
                onPressed: () => setState(_backToList),
              ),
            const SectionTitle('Tahtanın liderleri'),
            SurfaceCard(
              key: const ValueKey('ranking-own-position'),
              child: Row(
                children: [
                  const Icon(Icons.person_pin_circle_outlined, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          myIndex >= 0
                              ? 'Sen ${myIndex + 1}. sıradasın'
                              : 'Sıralaman henüz oluşmadı',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          myIndex >= 0
                              ? '${players[myIndex].rating} puan · ${players.length} oyuncu'
                              : repository.isDemo
                              ? 'Örnek listede kişisel puanın yer almıyor.'
                              : 'Bu topluluğun listesinde henüz puanın bulunmuyor.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (myIndex >= 0)
                    IconButton(
                      key: const ValueKey('ranking-find-me'),
                      tooltip: 'Sıramı bul',
                      icon: const Icon(Icons.my_location),
                      onPressed: () {
                        final target = _myRankKey.currentContext;
                        if (target != null) {
                          Scrollable.ensureVisible(
                            target,
                            alignment: .4,
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 280),
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (players.isEmpty)
              const SurfaceCard(child: Text('Burada henüz oyuncu yok.')),
            if (players.isNotEmpty)
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < players.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      Semantics(
                        selected: i == myIndex,
                        child: Container(
                          key: i == myIndex
                              ? _myRankKey
                              : ValueKey(
                                  'ranking-player-${players[i].playerId ?? i}',
                                ),
                          color: i == myIndex
                              ? Theme.of(context).colorScheme.primary
                                    .withValues(alpha: .08)
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              _RankBadge(rank: i + 1),
                              const SizedBox(width: 10),
                              CircleAvatar(
                                radius: 17,
                                child: Text(
                                  players[i].name.isEmpty
                                      ? '?'
                                      : players[i].name.substring(0, 1),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${players[i].name}${i == myIndex ? ' · Sen' : ''}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${players[i].games} oyun',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${players[i].rating}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/registration'),
            icon: const Icon(Icons.school_outlined),
            label: const Text('Ülke, şehir, okul ve grubumu seç'),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: rank <= 3
            ? const Color(0xFFB3905C).withValues(alpha: .12)
            : scheme.primary.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$rank',
        style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
      ),
    );
  }
}
