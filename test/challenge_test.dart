import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/features/challenges/domain/challenge_invite.dart';
import 'package:chess_platform/features/challenges/data/whatsapp_share_service.dart';
import 'package:chess_platform/features/game/domain/time_control.dart';

void main() {
  test(
    'invite round-trips and WhatsApp preserves the Turkish text and link',
    () {
      final invite = ChallengeInvite(
        id: '0123456789abcdef0123456789abcdef',
        timeControl: const TimeControl(3, 2),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );
      final restored = ChallengeInvite.fromJson(invite.toJson());
      expect(restored.id, invite.id);
      expect(restored.timeControl.label, '3 + 2');
      expect(restored.demoLink.path, '/challenge/${invite.id}');
      final url = WhatsAppShareService().composeUri(restored);
      expect(url.host, 'wa.me');
      expect(url.queryParameters['text'], restored.shareText);
      expect(restored.isExpired, false);
    },
  );
  test('expired invites and malformed duration inputs are handled', () {
    final invite = ChallengeInvite(
      id: 'expired',
      timeControl: const TimeControl(10, 0),
      expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
    expect(invite.isExpired, true);
    expect(
      TimeControl.fromQuery({'minutes': '-9', 'increment': '1000'}).label,
      '1 + 60',
    );
    expect(TimeControl.fromQuery({'minutes': 'oops'}).minutes, 10);
  });
}
