import 'package:flutter/material.dart';

/// Compact, high-contrast connection status used during live games.
///
/// Keeping this separate from the game body lets the portrait, landscape and
/// fullscreen layouts use the same visual language without duplicating the
/// connection copy or its accessibility label.
class OnlineConnectionPill extends StatelessWidget {
  const OnlineConnectionPill({
    super.key,
    required this.connected,
    required this.label,
  });

  final bool connected;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = connected
        ? scheme.primaryContainer
        : scheme.errorContainer;
    final foreground = connected
        ? scheme.onPrimaryContainer
        : scheme.onErrorContainer;
    return Semantics(
      container: true,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              size: 15,
              color: foreground,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
