# Satranç Platformu — 0.8.7+20

Sakin, profesyonel Türkçe Flutter satranç uygulaması. Proje: C:\Users\GiresuN\StudioProjects\ChessPlatform. Kalıcı Android paket: **com.zpgames.satrancplatformu**. Dart paketi chess_platform.

## Çalışan özellikler

- Ana Sayfa, Oyna, Liderlik, Sosyal, Profil; bir üst menüye geri dönüş.
- Varsayılan Ferah Turkuaz ve Klasik Orman paletleri; açık/koyu/sistem teması, kompakt kartlar ve cihazda kalıcı tercihler.
- Bilgisayara karşı Kolay/Orta/Zor/Usta veya aynı cihazda iki kişilik oyun.
- Süresiz yerel oyun; oyuncu başına varsayılan 10 dakika, ana 10/15/30/60 seçimleri, diğer kısa/uzun/ek saniyeli süreler. Yeni çevrim içi maçlarda 3 dakika hamlesizlik kaybı, hamle geri sayımı ve açık sonuç mesajı. Eski maçların süre kuralı korunur.
- Ahşap, mermer, siyah-beyaz, koyu ve çocuklara uygun renkli tahtalar; 2D, üstten ve 3D taş geometrileri.
- Tam ekran, varsayılan kapalı yerel hamle ipuçları, yumuşak taş kayması, kapatılabilir Android taş sesi. Çevrim içi maçlarda ipuçları her zaman kapalıdır; standart kurallar korunur.
- Taş yağmuru ve ZP GAMES açılışı, tam alan turkuaz zeminde büyük fildişi at Android launcher simgesi, hareket azaltma.
- Yerel oyuna devam etme, geçmiş, hamle inceleme ve PGN.
- **Android mağaza sürümünde gerçek Firebase arkadaş maçı, WhatsApp HTTPS daveti, rakip arama ve çevrim içi maça dönme.** 13+ ve veri açıklaması/onayıyla rastgele misafir kimliği açılır. Serbest sohbet yok. Doğrulanmış kalıcı hesaplar ayrı seçimle gerçek topluluk puanına katılır.
- Oyun altında beraberlik teklif/kabul/red, maç sonunda aynı rakiple özel rövanş ve dört hazır sporculuk mesajı. Mesajlar maç başına toplam 12 ile sınırlıdır. Yeni çevrim içi seçenekler için iki oyuncunun da 0.7.1 veya daha yeni sürümü kullanması gerekir.
- Profil → Güvenlik ve gizlilik altında çevrim içi kimliği/davetleri/maçları silme.
- Türkiye hazır seçilir; aramalı şehir → okul → sınıf/şube akışı ve ayrı gruplar yerel seçimdir. 81 ilde 55.117 kamu rehberi kurumu ve resmî özel okul tablolarındaki 12.619 okul, toplam 67.736 okul/kurum çevrimdışı rehberdedir. Giresun 393 kayıttır. Kamu kaynak görüntüsü 31 Ağustos 2026, özel okul tablolarının alınışı 4 Ekim 2026; kapsam ve sonraya bırakılan izin değerlendirmesi [katalog belgesinde](docs/SCHOOL_CATALOG.md). Mağaza sürümünde gerçek haftalık/aylık/tüm zamanlar puanı, okul/sınıf/şehir/ülke ve ayrı grup filtresi, Benim sıram vardır. Okul/sınıf seçimi beyana dayanır; resmi üyelik doğrulanmaz.

- Son seçilen oyun türünü/süreyi/zorluğu hatırlayan ana sayfa Oyna düğmesi; yerel yarım oyun korunur, hızlı çevrim içi eşleşme tahtaya otomatik geçer.
- İsteğe bağlı e-posta/şifre hesabına UID korunarak bağlama, profil/okul yedeği, doğrulama ve kurtarma; hesap değişince aynı özel profil geri yüklenir.
- Sonuç mutabakatı ve tek seferlik 3/1/0 puan, haftalık kupa sıralaması, gerçek yer hesabı; demo oyuncular mağaza sıralamasına karışmaz.
- Bağlantı yoklaması/yeniden deneme, maç sonrası olay incelemesi, azaltılmış animasyon ve hafif 2D tahta.
- Eksik/hatalı okul için özel bildirim ve tek adım düzenleme.

## Teslim ve doğrulama

[Play AAB](releases/satranc-platformu-play-0.8.7+20.aab) ve [test APK](releases/satranc-platformu-0.8.7+20.apk) **0.8.7+20** olarak mevcut upload imzasıyla derlendi. Paket kimliği ve imzalar kalite kanıtında doğrulandı: [quality-gate-0.8.7+20.json](releases/quality-gate-0.8.7+20.json). Bu dosyalar Play Console'a otomatik yüklenmez.

Yeni büyük krem satranç atı ve tam alan turkuaz zemin Android launcher simgesidir. 26+ katmanlı simge, 33+ tek renk ve eski Android PNG boyutları hazır. [Yuvarlak/kare önizleme](design/icon-options/05-launcher-preview.png) arayüz simülasyonudur. Taş görünen alanın yaklaşık %87'si yüksekliğinde; alpha ve güvenli bölge doğrulandı. [Simge belgesi](docs/LAUNCHER_ICON.md), [ImageGen istemleri](design/icon-options/05-PROMPTS.md).

İş mantığı değişmedi; önceki 0.8.3'ün temiz analizi, **164 uygulama testi ve 10 canlı kayıt/yedekleme kontrolü** tarihsel kanıttır, bu turda yeniden koşulmadı. Kayıt ol ve 12 karakter şifre düzeltmeleri korunur. Gerçek e-posta teslimi henüz test edilmedi.

0.8.4+17 fiziksel RMX3890 telefona USB ile veriler silinmeden kuruldu; sürüm ve başarılı açılış doğrulandı. Uygulama listesindeki simge görünümü fiziksel olarak henüz incelenmedi. Emülatör açılmadı. **0.8.4 Play Console'a yüklenmedi**; mağaza için 512px yeni görsel hazır, mevcut çevrim içi mağaza simgesi değiştirilmedi. Son Play kaydı ve inceleme hesabı aktarımı onayının beklemesi değişmedi. Firebase Spark yapılandırması/kuralları bu turda değişmedi.

[Doğrulama](docs/VERIFICATION.md) · [Firebase/Play durumu](docs/PLAY_FIREBASE_SETUP.md) · [Sprintler](docs/SPRINTS.md) · [App Links](docs/LINKS.md).
[Web ve destek](https://satranc-platformu.web.app) · [Gizlilik](https://satranc-platformu.web.app/privacy).

## Derleme ve geliştirme

Android Studio'da bu kök klasörü açın; giriş lib/main.dart. Mağaza AAB için:

~~~powershell
.\tool\build_play_bundle.ps1
~~~

Tam release kalite kapısı (emulator başlatmadan):

~~~powershell
.\tool\quality_gate.ps1
~~~

Betik proje içindeki Java 21'i, kalıcı paketi, Firebase bayrağını ve upload imzasını seçer; sistem JAVA_HOME ayarını değiştirmez. Özel android/key.properties ve android/private/satranc-upload.p12 sürüm kontrolü dışındadır; güvenli yedek alın.

Doğrudan Android derlemede CHESS_FIREBASE_ENABLED=true ile chessStoreBuild=true ve chessStoreApplicationId=com.zpgames.satrancplatformu birlikte gerekir. Varsayılan Flutter run / web önizleme yerel demo sağlayıcısını kullanır; Firebase sadece Android mağaza bayrağıyla başlatılır. Varsayılan geliştirme paketi com.example.chess_platform.

~~~powershell
flutter analyze
flutter test
flutter build apk --release --dart-define=CHESS_FIREBASE_ENABLED=true --android-project-arg=chessStoreBuild=true --android-project-arg=chessStoreApplicationId=com.zpgames.satrancplatformu
~~~

Bu makinede flutter.bat yerine mevcut Dart / flutter_tools.snapshot ve proje Java 21'i kullanmak gerekebilir. Ayrıntılar tool/build_play_bundle.ps1 içinde. Test/debug sonrasında release build'de --no-pub kullanmayın; paket adımı eklenti kayıtlarını yeniler.

Canlı Firebase doğrulama betiği tool/verify_online_firebase.mjs sıradan istemciler kullanır. Yalnız kendi oluşturduğu test verilerini temizler; test kuyruğu önceden varsa değiştirmeyi reddeder.

## Mimari

lib/app servisleri birleştirir. lib/core altında constants, theme, routing, networking ve widgets bulunur. lib/features altında auth, home, game, matchmaking, challenges, leaderboard, schools, classes, groups, friends/social, tournaments, profile, settings, legal/safety katmanları vardır. Feature domain/data/presentation ayrımı korunur. FirebaseChessService var olan repository sözleşmelerine bağlanır; yerel ve REST adaptörleri korunur.

[Tahta koleksiyonu](docs/BOARD_APPEARANCE.md) · [Marka](docs/BRANDING.md) · [Oyun sunumu](docs/GAME_PRESENTATION.md) · [Maç seçenekleri](docs/MATCH_ACTIONS.md) · [Kaynak lisansları](docs/ASSET_CREDITS.md) · [Mimari](docs/ARCHITECTURE.md).

## Yayın sınırları

Spark ücretsiz kota sınırları geçerlidir; ücretli plan açılmadı. Firestore erişim/sıra/geçmiş kuralları uygulanır, tam satranç yasallığı istemcilerde yeniden oynatılır. Topluluk puanı iki istemcinin aynı sonuç üzerinde anlaşmasına dayanır ve Elo değildir. Hileye dayanıklı resmi derece için yetkili motor gerekir. [Puan mimarisi](docs/COMMUNITY_POINTS.md). iOS Firebase/Universal Links ve iOS derleme henüz doğrulanmadı. Play üretim erişimi için bu hesapta 12 gerçek kapalı test katılımcısı ve 14 gün gerekir; mağaza hazırlığı herkese yayın değildir.
