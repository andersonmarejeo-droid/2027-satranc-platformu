import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Her gün belirlenen saatte (varsayılan: saat 18:00 / akşam 6)
/// kullanıcıya "Hamle sırası sende!" yerel bildirimi gönderen servis.
class DailyReminderService {
  DailyReminderService._();
  static final DailyReminderService instance = DailyReminderService._();

  static const int reminderNotificationId = 600;
  static const String channelId = 'daily_reminder_channel';
  static const String channelName = 'Günlük Hatırlatıcı';
  static const String channelDescription =
      'Her gün oyuna davet eden günlük hatırlatıcı bildirimleri';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Servisi başlatır, zaman dilimini yükler ve bildirim iznini ister.
  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    try {
      // 1. Zaman dilimi yapılandırması
      tz.initializeTimeZones();
      try {
        final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      } catch (e) {
        debugPrint('Yerel saat dilimi alınamadı, fallback kullanılıyor: $e');
      }

      // 2. Android & iOS başlatma ayarları
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher_studio_v2',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Bildirime tıklandı: ${response.payload}');
        },
      );

      // 3. Android 13+ Bildirim İzni İste
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await androidImpl?.requestNotificationsPermission();
      }

      _initialized = true;
    } catch (e) {
      debugPrint('DailyReminderService başlatılamadı: $e');
    }
  }

  /// Bir sonraki belirtilen saati hesaplar (ör. saat 18:00)
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Günlük bildirimi kurar (Günde bir kez, her gün aynı saatte)
  Future<void> scheduleDailyReminder({
    int hour = 18,
    int minute = 0,
    String title = 'Hamle sırası sende!',
    String body = 'Günün satranç maçına hazır mısın? Tahta seni bekliyor, hemen oyna!',
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();

    try {
      // Önceki eski planı temizle
      await _notifications.cancel(reminderNotificationId);

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher_studio_v2',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      final scheduledTime = _nextInstanceOfTime(hour, minute);

      await _notifications.zonedSchedule(
        reminderNotificationId,
        title,
        body,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint(
        'Günlük bildirim planlandı: Her gün saat $hour:${minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      debugPrint('Günlük bildirim planlanırken hata oluştu: $e');
    }
  }

  /// Günlük bildirimi iptal eder
  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    try {
      await _notifications.cancel(reminderNotificationId);
      debugPrint('Günlük bildirim iptal edildi.');
    } catch (e) {
      debugPrint('Günlük bildirim iptal edilirken hata: $e');
    }
  }

  /// Tercihe göre bildirimi günceller
  Future<void> updateReminder(bool enabled, {int hour = 18, int minute = 0}) async {
    if (enabled) {
      await scheduleDailyReminder(hour: hour, minute: minute);
    } else {
      await cancelDailyReminder();
    }
  }
}
