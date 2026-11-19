# Tam ekran, taş sesi ve görünür hamleler

## Tam ekran

Oyun başladığında üst çubukta Tam ekran düğmesi görünür. Normal görünümde açıklamalar, seçenekler ve hamle geçmişi bulunur. Tam ekranda tahta, iki oyuncu/saat, sıra bilgisi, duraklatma ve ses düğmesi görünür; yatay telefonda bilgiler tahtanın yanında yer alır. Tahta görünümü ve çevirme üstten kullanılabilir.

Yerel oyunda ilk geri hareketi tam ekrandan çıkar; ikinci geri hareketi mevcut kaydet/duraklat akışıyla bir üst sayfaya döner. Açık pencere önce kapanır. Tam ekran açıp kapatma aynı oyun ve saat denetleyicilerini kullanır; taş konumu, hamle geçmişi ve saat sıfırlanmaz. Sayfadan ayrılırken sistem çubukları geri açılır.

Android'de durum/navigasyon çubuklarını gizleme için [resmi WindowInsetsControllerCompat yaklaşımı](https://developer.android.com/develop/ui/views/layout/immersive) kullanılır. Kenardan kaydırınca sistem çubukları geçici görünür. [Flutter API'sinin Android 36 sınırı](https://api.flutter.dev/flutter/services/SystemChrome/setEnabledSystemUIMode.html) nedeniyle yalnız SystemChrome modu değiştirmeye dayanmıyoruz; edge-to-edge yerleşim korunarak yerel çubuk görünürlüğü değiştirilir. Gerçek Android 16 cihaz kontrolü ayrıca gerekir.

## Taş sesi

Özgün, kısa ve düşük düzeyli ahşap sürtünme/yerleştirme sesi `android/app/src/main/res/raw/chess_slide.wav` dosyasındadır. Deterministik filtreli gürültü, yumuşak genlik zarfı ve kısa sönümlü 420 Hz temas tonu ile üretildi; dış ses kaynağı, mikrofon, ağ veya lisans bağımlılığı yoktur. PCM WAV, 24 kHz, tek kanal, 16 bit, 300 ms.

Android SoundPool ilk yasal hamlede sesi yükler; sonraki hareketlerde aynı örnek kullanılır. Medya ses düzeyine uyar. Taş seçimi, geçersiz hamle, saat yenileme, geri alma ve eski oyunu yükleme yeni hamle sesi üretmez. Yerel/bilgisayarlı oyunda yasal hareket, çevrim içi istemcide yeni sunucu hamlesi sesi tetikler. Taş sesleri normal ekranda anahtarla veya tam ekranın altındaki ses düğmesiyle kapatılabilir; tercih mevcut maç ekranı boyunca korunur.

Ses köprüsü bu sürümde Android içindir. Diğer platformlarda oyun ve görsel hareketler çalışır; aynı ses için yerel oynatıcı bağlantısı henüz eklenmedi.

## Hareket ve bilgisayar

2D, üstten ve 3D görünümde taş kayması 380 ms sürer. 2D/üstten görünümde son karedeki taş, başlangıç karesinden hedefe kayan tek taş görünümüyle gösterilir; anlamsal/yasal tahta güncel konumu kullanır. Geri alma veya aynı konumun saat yenilemesi yeni hareket başlatmaz. Hareket azaltma tercihinde 2D/üstten kayma kaldırılır.

Bilgisayarın yanıtı hamle hesabı başlangıcından en az 650 ms sonra uygulanır. Böylece insanın kayması tamamlanır, kısa bir düşünme aralığı olur ve rakibin geliş hareketi izlenir. Hesap daha uzun sürerse hazır yanıt beklenir. Saat hesap/bekleme boyunca çalışır; süre dolması, geri alma, duraklatma veya çıkışta geç kalan yanıtı reddetme korunur. Çevrim içi sunucu hamlesine yapay gecikme eklenmez; gelen son hamle animasyonla gösterilir.

Çevrim içi arayüzün kontrolü sahte test deposuyla yapılır; gerçek iki cihazlı maç sunucusu hâlâ yapılandırılmadı.
