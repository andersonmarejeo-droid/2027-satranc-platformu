import 'package:flutter/material.dart';

import '../../../core/widgets/page_layout.dart';
import '../domain/community_preview.dart';

void showCommunitySheet(BuildContext context, CommunityPreview preview) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoLabel(text: 'Tasarım örneği · gerçek üyelik değil'),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _iconFor(preview.icon),
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preview.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preview.subtitle,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(preview.description),
              const SizedBox(height: 18),
              const SurfaceCard(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Okul üyeliği ve öğrenci görünürlüğü, doğrulanmış kurum ve yetkili hesaplar hazır olmadan açılmaz.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

IconData _iconFor(CommunityIcon icon) => switch (icon) {
  CommunityIcon.school => Icons.school_outlined,
  CommunityIcon.classroom => Icons.class_outlined,
  CommunityIcon.group => Icons.groups_outlined,
  CommunityIcon.lockedGroup => Icons.lock_outline,
};
