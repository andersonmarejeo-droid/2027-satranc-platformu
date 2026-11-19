import 'package:flutter/material.dart';

import '../../../settings/presentation/board_appearance_controls.dart';

/// Compact controls that keep a focused game readable while in immersive mode.
class FullscreenGameBar extends StatelessWidget {
  const FullscreenGameBar({
    super.key,
    required this.title,
    required this.onExit,
    required this.onFlip,
  });

  final String title;
  final VoidCallback onExit;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: .96),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: .12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('fullscreen-back'),
              tooltip: 'Tam ekrandan çık',
              onPressed: onExit,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const BoardAppearanceButton(),
            IconButton(
              tooltip: 'Tahtayı çevir',
              onPressed: onFlip,
              icon: const Icon(Icons.flip_camera_android_outlined),
            ),
            IconButton(
              key: const ValueKey('game-fullscreen'),
              tooltip: 'Tam ekrandan çık',
              onPressed: onExit,
              icon: const Icon(Icons.fullscreen_exit),
            ),
          ],
        ),
      ),
    );
  }
}
