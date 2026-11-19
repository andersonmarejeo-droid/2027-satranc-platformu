import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/notifications/daily_reminder_service.dart';

/// Günlük oyun hatırlatma bildiriminin ayarlarını ve durumunu yöneten denetleyici.
/// Varsayılan olarak AÇIK'tır ve her gün saat 18:00'de (akşam 6) tetiklenir.
class DailyReminderController extends ChangeNotifier {
  DailyReminderController(this.preferences);

  final SharedPreferencesAsync preferences;
  bool isDailyReminderEnabled = true;
  int reminderHour = 18;

  Future<void> load() async {
    isDailyReminderEnabled =
        await preferences.getBool('notifications.dailyReminder') ?? true;
    reminderHour =
        await preferences.getInt('notifications.reminderHour') ?? 18;

    // Servis başlatıldıktan sonra ayara göre planlamayı tazele
    await DailyReminderService.instance.initialize();
    if (isDailyReminderEnabled) {
      await DailyReminderService.instance.scheduleDailyReminder(
        hour: reminderHour,
      );
    } else {
      await DailyReminderService.instance.cancelDailyReminder();
    }
  }

  Future<void> setDailyReminder(bool enabled) async {
    isDailyReminderEnabled = enabled;
    await preferences.setBool('notifications.dailyReminder', enabled);
    await DailyReminderService.instance.updateReminder(
      enabled,
      hour: reminderHour,
    );
    notifyListeners();
  }

  Future<void> setReminderHour(int hour) async {
    reminderHour = hour;
    await preferences.setInt('notifications.reminderHour', hour);
    if (isDailyReminderEnabled) {
      await DailyReminderService.instance.scheduleDailyReminder(hour: hour);
    }
    notifyListeners();
  }
}
