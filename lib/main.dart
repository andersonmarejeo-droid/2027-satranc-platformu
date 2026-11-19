import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

import 'app/chess_app.dart';
import 'app/app_services.dart';
import 'core/ads/ad_service.dart';
import 'core/constants/app_config.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sarı / kırmızı ekran ("Yellow Screen of Death") ve beklenmedik render çökmelerini önleme
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // Geliştirme esnasında detay konsola basılır
      FlutterError.dumpErrorToConsole(details);
    }
    return Material(
      color: const Color(0xFF141815),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 40),
              const SizedBox(height: 10),
              const Text(
                'Görünüm yüklenirken bir sorun oluştu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                kDebugMode
                    ? details.exceptionAsString()
                    : 'Lütfen önceki menüye dönüp tekrar deneyin.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  };

  // The registered Android store build includes google-services.json, so
  // Firebase-backed matchmaking should be available by default. Keep an
  // explicit define override for preview or offline builds when needed.
  if (const bool.fromEnvironment(
        'CHESS_FIREBASE_ENABLED',
        defaultValue: true,
      ) &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      if (AppConfig.appCheckEnabled) {
        try {
          await FirebaseAppCheck.instance.activate(
            providerAndroid: kDebugMode
                ? const AndroidDebugProvider()
                : const AndroidPlayIntegrityProvider(),
          );
        } catch (e) {
          debugPrint('AppCheck başlatılamadı: $e');
        }
      }
      final collectTelemetry = AppConfig.telemetryEnabled && !kDebugMode;
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        collectTelemetry,
      );
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(
        collectTelemetry,
      );
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        unawaited(
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
        );
        return true;
      };
    } catch (e) {
      debugPrint('Firebase başlatılamadı, yerel modda devam ediliyor: $e');
    }
  }
  // Reklam servisini (AdMob & Aileye uygunluk yapılandırması) başlat
  await AdService.instance.initialize();

  final services = await AppServices.create();
  runApp(ChessApp(services: services, showIntro: true));
}
