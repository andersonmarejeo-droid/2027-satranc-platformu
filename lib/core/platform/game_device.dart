import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native Android game presentation; no network or microphone is used.
class GameDevice {
  static const channel = MethodChannel('com.zpgames.chess/game_device');
  static Future<void> fullscreen(bool enabled) async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await channel.invokeMethod<void>('fullscreen', enabled);
      } else {
        await SystemChrome.setEnabledSystemUIMode(
          enabled ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
        );
      }
    } on MissingPluginException {
      // Headless tests and unsupported hosts retain the focused layout.
    } on PlatformException {
      // A platform restriction must not interrupt an active game.
    }
  }

  static Future<void> slideSound() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await channel.invokeMethod<void>('slideSound');
    } on MissingPluginException {
      // Native audio is optional on hosts without the Android bridge.
    } on PlatformException {
      // A silent device still has a fully playable board.
    }
  }
}
