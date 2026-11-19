import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

/// Owns the push-notification boundary. Permission is requested only when a
/// user opts into online reminders; app startup never shows a system prompt.
class NotificationService {
  NotificationService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;

  Future<NotificationRegistration?> enable({
    Future<void> Function(String token)? onToken,
    void Function(RemoteMessage message)? onForegroundMessage,
  }) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );
    final authorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!authorized) return null;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return null;
    await onToken?.call(token);
    await _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen((next) {
      if (next.isNotEmpty) unawaited(onToken?.call(next));
    });
    await _messageSubscription?.cancel();
    _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
      onForegroundMessage?.call(message);
    });
    return NotificationRegistration(token: token);
  }

  Future<void> disable() async {
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    _tokenSubscription = null;
    _messageSubscription = null;
  }

  Future<void> dispose() => disable();
}

class NotificationRegistration {
  const NotificationRegistration({required this.token});
  final String token;
}
