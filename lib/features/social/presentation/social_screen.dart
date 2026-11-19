import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_services.dart';
import '../../../core/widgets/page_layout.dart';
import '../../challenges/domain/online_challenge_repository.dart';
import '../../profile/domain/community_membership.dart';
import '../data/demo_community_catalog.dart';
import '../domain/community_preview.dart';
import 'community_sheet.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  var section = SocialSection.schools;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        services.membership,
        if (services.account != null) services.account!,
      ]),
      builder: (context, _) {
        final membership = services.membership.value;
        final hasLiveCommunity =
            membership.schoolId != null || membership.groupIds.isNotEmpty;
        return PageLayout(
          eyebrow: 'Birlikte daha güzel',
          title: 'Satranç çevren.',
          subtitle: 'Arkadaşların, okulun ve kulübün için tek bir yer.',
          children: [
            ActionCard(
              key: const ValueKey('social-create-challenge'),
              icon: Icons.send_outlined,
              title: 'Meydan oku',
              subtitle: 'Davetini WhatsApp üzerinden paylaş.',
              highlighted: true,
              onPressed: () => context.push('/challenges'),
            ),
            const SizedBox(height: 8),
            DemoLabel(
              text: hasLiveCommunity
                  ? 'Toplulukların · canlı üyelik açık'
                  : 'Topluluk alanları · örnek tasarım',
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final option in SocialSection.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        key: ValueKey('social-tab-${option.name}'),
                        label: Text(option.label),
                        selected: section == option,
                        onSelected: (_) => setState(() => section = option),
                      ),
                    ),
                ],
              ),
            ),
            SectionTitle(section.heading),
            _sectionContent(context, membership),
          ],
        );
      },
    );
  }

  Widget _sectionContent(
    BuildContext context,
    CommunityMembership membership,
  ) => switch (section) {
    SocialSection.friends => _friendsState(context),
    SocialSection.schools => _schoolsSection(context, membership),
    SocialSection.groups => _groupsSection(context, membership),
    SocialSection.tournaments => _emptyState(
      context,
      icon: Icons.emoji_events_outlined,
      title: SocialSection.tournaments.emptyTitle,
      message:
          'Tarih, katılım ve sonuçlar yalnızca turnuva hizmeti bağlandıktan sonra gösterilecek. Bu ekranda örnek etkinlik veya kayıt sayısı kullanılmıyor.',
    ),
  };

  Widget _friendsState(BuildContext context) {
    final services = AppScope.of(context);
    final isOnlineCapable = services.challenges is OnlineChallengeRepository;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _emptyState(
          context,
          icon: Icons.people_outline,
          title: 'Arkadaşlarınla davet bağlantısı üzerinden oyna.',
          message:
              'WhatsApp veya davet bağlantısı göndererek arkadaşınla hemen aynı tahtada buluşabilirsin. Kişi rehberi veya herkese açık çevrim içi liste paylaşılmaz.',
          action: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => context.push('/challenges'),
                icon: const Icon(Icons.link),
                label: const Text('Davet bağlantısı hazırla'),
              ),
              if (isOnlineCapable)
                OutlinedButton.icon(
                  key: const ValueKey('social-online-games'),
                  onPressed: () => context.push('/online-games'),
                  icon: const Icon(Icons.history),
                  label: const Text('Çevrim içi maçlarım'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _schoolsSection(
    BuildContext context,
    CommunityMembership membership,
  ) {
    final school = CommunityDirectory.find(membership.schoolId);
    final classroom = CommunityDirectory.find(membership.classId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (school != null)
          SurfaceCard(
            key: const ValueKey('social-selected-school'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            school.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            [
                              if (school.location.isNotEmpty) school.location,
                              if (classroom != null) 'Sınıf: ${classroom.name}',
                            ].join(' · '),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      key: const ValueKey('social-school-leaderboard'),
                      onPressed: () => context.go('/leaderboard'),
                      icon: const Icon(Icons.emoji_events_outlined, size: 18),
                      label: const Text('Okul sıralaması'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('social-edit-school'),
                      onPressed: () => context.push('/registration?edit=school'),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Okul / sınıf değiştir'),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          ActionCard(
            key: const ValueKey('social-select-school'),
            icon: Icons.school_outlined,
            title: 'Okulunu ve sınıfını seç',
            subtitle:
                'Okulunun ve şubenin puan tablosunda yer almak için kaydını tamamla.',
            onPressed: () => context.push('/registration?edit=school'),
          ),
        const SizedBox(height: 12),
        _previewList(context, DemoCommunityCatalog.schools),
      ],
    );
  }

  Widget _groupsSection(
    BuildContext context,
    CommunityMembership membership,
  ) {
    final selectedGroups = membership.groupIds
        .map(CommunityDirectory.find)
        .whereType<CommunityNode>()
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedGroups.isNotEmpty)
          SurfaceCard(
            key: const ValueKey('social-selected-groups'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Katıldığın satranç grupları',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final group in selectedGroups)
                      Chip(
                        avatar: const Icon(Icons.groups_outlined, size: 16),
                        label: Text(group.name),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => context.go('/leaderboard'),
                      icon: const Icon(Icons.emoji_events_outlined, size: 18),
                      label: const Text('Grup sıralaması'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('social-edit-groups'),
                      onPressed: () => context.push('/registration?edit=group'),
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('Grupları düzenle'),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          ActionCard(
            key: const ValueKey('social-select-groups'),
            icon: Icons.groups_outlined,
            title: 'Bir satranç grubuna katıl',
            subtitle: 'Ortak çalışma ve dostluk puanları için grup seç.',
            onPressed: () => context.push('/registration?edit=group'),
          ),
        const SizedBox(height: 12),
        _previewList(context, DemoCommunityCatalog.groups),
      ],
    );
  }

  Widget _previewList(BuildContext context, List<CommunityPreview> previews) =>
      Column(
        children: [
          for (var index = 0; index < previews.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            _previewCard(context, previews[index]),
          ],
        ],
      );

  Widget _previewCard(BuildContext context, CommunityPreview preview) =>
      SurfaceCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          key: ValueKey('community-preview-${preview.id}'),
          onTap: () => showCommunitySheet(context, preview),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _iconFor(preview.icon),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preview.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preview.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _emptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) => SurfaceCard(
    child: Column(
      children: [
        Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 16), action],
      ],
    ),
  );
}

IconData _iconFor(CommunityIcon icon) => switch (icon) {
  CommunityIcon.school => Icons.school_outlined,
  CommunityIcon.classroom => Icons.class_outlined,
  CommunityIcon.group => Icons.groups_outlined,
  CommunityIcon.lockedGroup => Icons.lock_outline,
};
