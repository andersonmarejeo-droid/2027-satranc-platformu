import 'package:flutter/material.dart';

import '../../../../core/widgets/page_layout.dart';
import '../../domain/match_interactions.dart';
import '../../domain/match_snapshot.dart';
import '../online_game_controller.dart';

class QuickMessages extends StatelessWidget {
  const QuickMessages({super.key, required this.onSend, this.enabled = true});
  final ValueChanged<QuickMessageCode> onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 4,
    children: [
      for (final code in QuickMessageCode.values)
        ActionChip(
          key: ValueKey('quick-message-${code.name}'),
          label: Text(code.label),
          onPressed: enabled ? () => onSend(code) : null,
        ),
    ],
  );
}

class OnlineMatchActions extends StatelessWidget {
  const OnlineMatchActions({super.key, required this.controller});
  final OnlineGameController controller;

  @override
  Widget build(BuildContext context) {
    final match = controller.snapshot;
    if (match == null || !controller.supportsInteractions) {
      return const SizedBox.shrink();
    }
    final actions = match.interactions;
    final busy = controller.isSubmitting;
    final incomingDraw =
        actions.drawOfferedBy != null &&
        actions.drawOfferedBy != controller.playerId;
    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (match.status == MatchStatus.active) ...[
            if (incomingDraw) ...[
              const Text('Rakibin beraberlik teklif etti.'),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    key: const ValueKey('accept-draw'),
                    onPressed: busy
                        ? null
                        : () => controller.respondToDraw(true),
                    child: const Text('Kabul et'),
                  ),
                  TextButton(
                    key: const ValueKey('decline-draw'),
                    onPressed: busy
                        ? null
                        : () => controller.respondToDraw(false),
                    child: const Text('Devam et'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (!incomingDraw)
                  OutlinedButton.icon(
                    key: const ValueKey('offer-draw'),
                    onPressed: busy || actions.drawOfferedBy != null
                        ? null
                        : controller.offerDraw,
                    icon: const Icon(Icons.handshake_outlined, size: 18),
                    label: Text(
                      actions.drawOfferedBy != null
                          ? 'Beraberlik yanıtı bekleniyor'
                          : 'Beraberlik teklif et',
                    ),
                  ),
                OutlinedButton.icon(
                  key: const ValueKey('resign-game'),
                  onPressed: busy ? null : () => _confirmResign(context),
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: const Text('Oyunu terk et'),
                ),
              ],
            ),
          ] else if (match.status == MatchStatus.completed) ...[
            const Text(
              'Güzel oyundu.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (actions.rematchOfferedBy == null)
              FilledButton.icon(
                key: const ValueKey('request-rematch'),
                onPressed: busy ? null : controller.requestRematch,
                icon: const Icon(Icons.replay),
                label: const Text('Rövanş oyna'),
              )
            else if (actions.rematchOfferedBy == controller.playerId)
              const Text('Rövanş teklifi gönderildi · Rakibin bekleniyor')
            else
              FilledButton.icon(
                key: const ValueKey('accept-rematch'),
                onPressed: busy
                    ? null
                    : () async {
                        await controller.acceptRematch();
                        await controller.refresh();
                      },
                icon: const Icon(Icons.replay),
                label: const Text('Rövanşı kabul et'),
              ),
            const SizedBox(height: 8),
            QuickMessages(
              enabled: !busy && actions.messages.length < 12,
              onSend: controller.sendQuickMessage,
            ),
            for (final message in actions.messages.skip(
              actions.messages.length > 4 ? actions.messages.length - 4 : 0,
            ))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${message.senderId == controller.playerId ? 'Sen' : 'Rakibin'} · ${message.code.label}',
                ),
              ),
            if (actions.messages.length >= 12)
              const Text('Bu maçın mesaj sınırına ulaşıldı.'),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmResign(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oyunu terk et?'),
        content: const Text(
          'Maç sona erecek ve bu oyunu rakibin kazanmış sayılacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const ValueKey('confirm-resign'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Terk et'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.resign();
    }
  }
}
