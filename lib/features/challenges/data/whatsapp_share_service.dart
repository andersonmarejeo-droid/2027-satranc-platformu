import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/challenge_invite.dart';

class WhatsAppShareService {
  Uri composeUri(ChallengeInvite invite) =>
      Uri.https('wa.me', '/', {'text': invite.shareText});
  Future<bool> openComposer(ChallengeInvite invite) async {
    try {
      return await launchUrl(
        composeUri(invite),
        mode: LaunchMode.externalApplication,
      );
    } on PlatformException {
      return false;
    }
  }
}
