import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_services.dart';
import '../../../core/widgets/page_layout.dart';
import '../domain/community_membership.dart';

class MyCommunityCard extends StatelessWidget {
  const MyCommunityCard({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).membership;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final value = controller.value;
        return SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.school_outlined, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Benim okulum',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('edit-membership'),
                    tooltip: 'Topluluğumu düzenle',
                    onPressed: () => context.push('/registration'),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                ],
              ),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final entry in {
                    CommunityKind.city: value.cityId,
                    CommunityKind.school: value.schoolId,
                    CommunityKind.classroom: value.classId,
                  }.entries)
                    TextButton(
                      onPressed: () =>
                          context.push('/registration?edit=${entry.key.name}'),
                      child: Text(
                        CommunityDirectory.find(entry.value)?.name ??
                            switch (entry.key) {
                              CommunityKind.city => 'Şehir seç',
                              CommunityKind.school => 'Okul seç',
                              _ => 'Sınıf seç',
                            },
                      ),
                    ),
                ],
              ),
              TextButton.icon(
                onPressed: () => context.go('/leaderboard'),
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('Benim sıram'),
              ),
            ],
          ),
        );
      },
    );
  }
}
