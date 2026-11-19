import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google AdMob reklam servisi.
///
/// Aile ve çocuk politikalarına (%100 aileye uygun / COPPA / G derecelendirmesi)
/// tam uyumlu şekilde banner ve tam ekran (interstitial) reklamları yönetir.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  DateTime? _lastInterstitialShownTime;

  /// Gerçek reklam yayınına geçildiğinde AdMob konsolundan alınan
  /// gerçek kimlikleri buraya tanımlayabilirsiniz.
  /// Boş bırakıldığında Google'ın resmi test kimlikleri kullanılır (güvenli mod).
  static const String _customAndroidBannerId = 'ca-app-pub-5780525320889526/5104559302';
  static const String? _customIosBannerId = null;
  static const String _customAndroidInterstitialId = 'ca-app-pub-5780525320889526/2536133492';
  static const String? _customIosInterstitialId = null;

  /// Banner Reklam Birimi Kimliği (Ad Unit ID)
  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _customAndroidBannerId;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _customIosBannerId ?? 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  /// Tam Ekran (Interstitial) Reklam Birimi Kimliği
  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _customAndroidInterstitialId;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _customIosInterstitialId ?? 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }

  /// Reklam servisini başlatır ve aileye uygunluk yapılandırmasını uygular.
  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    try {
      // Reklam envanterinin geniş olması ve reklamların dolması (fill rate) için
      // morris_world projesindeki gibi Genç/Genel (t) ve unspecified ayarlanır.
      final requestConfiguration = RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.t,
        ageRestrictedTreatment: AgeRestrictedTreatment.unspecified,
      );
      await MobileAds.instance.updateRequestConfiguration(requestConfiguration);
      await MobileAds.instance.initialize();

      _initialized = true;

      // İlk tam ekran reklamı arka planda hazırla
      loadInterstitialAd();
    } catch (e) {
      debugPrint('AdService başlatılırken hata oluştu: $e');
    }
  }

  /// Arka planda tam ekran (interstitial) reklamı yükler.
  void loadInterstitialAd() {
    if (!_initialized || kIsWeb || _isInterstitialLoading || _interstitialAd != null) {
      return;
    }

    final adUnitId = interstitialAdUnitId;
    if (adUnitId.isEmpty) return;

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              // Reklam kapatıldıktan sonra bir sonraki oyun bitimi için yenisini yükle
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial yüklenemedi: kod=${error.code}, mesaj=${error.message}');
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  /// Oyun bittiğinde tam ekran reklamı gösterir.
  /// Spam ve kötü kullanıcı deneyimini önlemek için arka arkaya hızlı açılışları sınırlar.
  Future<void> showGameOverInterstitial({Duration cooldown = const Duration(seconds: 25)}) async {
    if (!_initialized || kIsWeb) return;

    final now = DateTime.now();
    if (_lastInterstitialShownTime != null &&
        now.difference(_lastInterstitialShownTime!) < cooldown) {
      // Çok kısa sürede peş peşe oyun bittiyse kullanıcıyı sıkmamak için reklam atlanır.
      return;
    }

    if (_interstitialAd != null) {
      _lastInterstitialShownTime = now;
      await _interstitialAd!.show();
    } else {
      // Eğer henüz hazır değilse hemen bir sonraki için yükleme tetiklenir
      loadInterstitialAd();
    }
  }

  /// Kaynakları temizler
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
