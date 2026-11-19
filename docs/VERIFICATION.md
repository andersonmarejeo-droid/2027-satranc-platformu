## Güncel doğrulama özeti — 0.8.7+20 — 16 Ekim 2026

- `flutter test --reporter expanded`: **165/165 geçti**; `dart analyze lib`: temiz.
- İmzalı AAB ve APK üretimi başarılı; Firebase paket kimliği `com.zpgames.satrancplatformu` ile eşleşiyor.
- AAB SHA-256 `54C322385F6FF7C16DD69FE736CCB43843ADE772B817221886AC2920072EF244`; APK SHA-256 `CE4FC74926B61C7333D5BFB4C1621FFD1990D2DD5E3E6727D72F8EFE82E21E9E`.
- Fiziksel cihaz `5c76ad26` ADB üzerinden veriler korunarak güncellendi; `versionName=0.8.7`, `versionCode=20` doğrulandı. Emülatör başlatılmadı.
- Ayrıntılı 0.8.7 kaydı aşağıdaki bölümde; eski sürüm kayıtları tarihçe olarak korunur.
## Güncel 0.8.4+17 — 5 Ekim 2026

- Büyük tek at ve dolu turkuaz zemin, Android 26+ katmanlı simge/33+ tek renk katmanı ve 24/25 PNG boyutları. Eski dosyalar korunur. Alpha, güvenli bölge ve yuvarlak/kare önizleme doğrulandı; gerçek cihaz uygulama listesi henüz incelenmedi. Ayrıntı docs/LAUNCHER_ICON.md.
- 17/0.8.4 APK/AAB mevcut imzayla, gömülü katalog/lisans ve yeni simge kaynaklarıyla derlendi. Masaüstü eşitliği doğrulandı. APK SHA256 5C19DB1C355A959DA9C7D278A16220D62A216B9A01B4F5C729306FF2C72687DC; AAB SHA256 D4616A3077361A2E8DBE461875A3E94CB4E04D6E6D94BB7B04EB422AC92A58FD.
- 0.8.4+17 fiziksel RMX3890 telefona USB ile veriler silinmeden kuruldu; sürüm ve başarılı açılış doğrulandı. Uygulama listesindeki simge görünümü fiziksel olarak henüz incelenmedi. Emülatör açılmadı. Play simgesi/sürümü bu turda yüklenmedi; Firebase değiştirilmedi.
- İş mantığı aynı. 0.8.3'ün 164 testi/10 canlı kayıt kontrolü aşağıda tarihsel kanıt olarak kalır; yeni simge için tekrar koşulmadı.

## Güncel 0.8.3+16 — 5 Ekim 2026

- Hesabım formu Kayıt ol; minimum şifre 12. Misafir UID'siyle signUp ve aynı hesaba password oturumu: gizlilik korumasını kapatmadan kayıt/özel yedek çalışır. Açıklama docs/ACCOUNT_REGISTRATION.md.
- E-posta isteği Türkçe ve yedekten önce bağımsız; hata/yeniden gönderme ve bekleyen yedek görünür. Kayıt sonrası oturum hatası, yeniden kayıt yerine Giriş yap ile toparlanır.
- Temiz analiz, 164 tam uygulama testi (13 yeni kayıt testi dahil) ve 10 canlı sıradan istemci kontrolü geçti; geçici hesap/verisi silindi. Gerçek mail teslimi test edilmedi, doğrulama atlatılmadı. Önceki 0.8.2'nin 30 zaman kuralı kontrolü tarihsel kanıttır.
- 16/0.8.3 APK/AAB mevcut upload imzasıyla, katalog/lisans ve masaüstü eşitliğiyle doğrulandı. APK SHA256 43D34B3F65B47004CF1A32B64B0CE1029EF8E2AFD28E170FF450EC997CBDE1B1; AAB SHA256 AA87C7594292288411DB4615B52C3DDB44BA935D20BC06C7E381B4B7EF8A04CA.
- Yeni sürüm henüz telefona kurulmadı; son USB kontrolünde telefon bağlı değildi. Son doğrulanmış telefon sürümü tarihsel 0.8.1+14 kaydıdır. Emülatör açılmadı; yeni sürüm Play'e yüklenmedi. Spark ve sunucu kuralları değişmedi.
- Zeka Parkuru stilindeki ikon seçeneği 04 kaydedildi, mevcut simgeye uygulanmadı.

## Güncel 0.8.2+15 — 5 Ekim 2026

- Oyuncu başına varsayılan 10 dakika, ana 10/15/30/60 seçimleri; diğer süreler ve süresiz yerel pratik korundu.
- Yeni çevrim içi davet/maçlarda 180 saniye hamlesizlik rakibin galibiyetidir. Son kabul edilmiş hamle zamanı esas alınır; toplam saat erken biterse önce o geçerlidir. Davet/maç kuralı değiştirilemez, eşleştirme ayrı kuyruğu kullanır, eski maçlarda süre kuralı korunur. Ayrıntı docs/ONLINE_TIMING.md.
- Temiz kaynak analizi, 151 uygulama testi ve 30 canlı sıradan istemci sunucu kontrolü geçti. Gerçek üç dakika beklendi; test belgeleri/hesapları temizlendi. Kanıt releases/online-timing-082-verification.json. Önceki 77 kapasite/puan kontrolü bu sürümde yeniden koşulmadı.
- Firestore kuralları ve web açıklaması/gizlilik Spark planına uygulandı. İmzalı APK/AAB, paket 15/0.8.2, gömülü katalog/lisans ve masaüstü kopyaları doğrulandı. APK SHA256 373C0A478C3F4B5A4F8FC75AE4EBAFFD1C63D54E0C5565BDDEB2BCD443A37EF2; AAB SHA256 46ED6465017D8BF2F32D0FEDB84775B8927776A481B62B9FC1F32D88A7F6F897.
- Emülatör açılmadı. 0.8.2+15 için fiziksel telefona kurulum doğrulanmadı; telefon kaydı varsa releases/android-082-device-check.json içinde. Ayrıntılı dokunma/performans ve iki telefon daveti henüz doğrulanmadı.
- 0.8.2 Play'e yüklenmedi; önceki Play 0.8.1 kanıtı aşağıdadır. İnceleme hesabı bilgilerinin Google'a aktarımı için özel onay bekler.
- Topluluk puanları en az dört yarım hamle ve iki katılımcı onayını korur; rakip kapalıysa sonuç görünse bile puan mutabakatı bekleyebilir.

## Güncel 0.8.1+14 — 5 Ekim 2026

- Sınıf ve grup kapasitesi kalıcı hesaplarda 20. Sayaç, özel üyelik ve profil tek atomik işlemdir; sunucu 21. üyeyi engeller. Dolu takıma geçişte eski seçim korunur; ayrılma yer açar. Üst ülke/şehir/okul kapasitesi sınırlandırılmaz. Ayrıntı docs/SMALL_TEAMS.md.
- 143 tam uygulama testi, son kapasite hata dönüşümü sonrası 2 hedefli test ve temiz kaynak analizi geçti. Canlı sıradan HTTPS istemcileriyle 30 kapasite ve 47 mevcut hesap/puan/yetki kontrolü geçti. Başarılı süitin fixture hesapları/verileri temizlendi; final envanter kaydı releases/small-team-inventory.json. HTTP/2 taşıma denemesi tamamlanmadı, sertifika doğrulaması korunarak resmî Firestore Lite HTTPS kullanıldı.
- Spark projesine kurallar ve 0.8.1 gizlilik sayfası ücretsiz planla uygulandı; releases/firebase-081-deploy.log. APK/AAB paket ve mevcut upload imzası, katalog/lisans ve masaüstü eşitliği releases/android-081-package-verification.log ile doğrulandı.
- APK SHA256 A2D088409DBA4F61BA50A4E3141E7EB3EEF83681B471917612D41ADAF55005DD; AAB SHA256 A78A286D8DA5146128154F45572E2E38D5265928A797EF4D430B8B6F48B739A5.
- Dahili test 0.8.1+14 yayında. Yeni 0.8.1+14 Alpha sürümü kaydedildi; Google incelemesine gönderilmeden önce ayrı inceleme hesabının bilgilerinin aktarılması için kullanıcı onayı bekliyor. Play sonuçları releases/play-081-result.json; otomatik ön lansman: Play lansman öncesi raporu henüz oluşmadı; Türkçe test dili kaydedildi. Console, yapı yüklenince raporun otomatik oluşturulduğunu bildiriyor. Çalışan test veya başarı sonucu henüz doğrulanmadı.. 0 gerçek katılım gözlendi; test fixture'ları Play katılımcısı değildir.
- Veri Güvenliği'nde isteğe bağlı hesap, okul/grup seçimi ve okul bildirimi açıklaması güncellendi. Sabit sporculuk mesajları Google'ın oyun eylemleri/diyalog seçenekleri kapsamındaki Diğer işlemler kategorisinde; serbest sohbet olmadığı için mesaj kategorisi eklenmedi. Otomatik onay denetimi bu ayrı mesaj kategorisini mevcut kanıtla reddetti; güvenli sınıflandırma kullanıldı.
- Emülatör açılmadı; 0.8.1+14 USB ile fiziksel telefona kuruldu, sürüm ve başarılı açılış doğrulandı. Kurulum -r ile yapıldı; veri silme komutu çalıştırılmadı. Telefon kaydı releases/android-081-device-check.json. Önceki 0.8.0'ın 38 maç/davet, beş başsız önizleme ve telefon/App Links kanıtı tarihsel aşağıdaki bölümde kalır; 0.8.1 yeniden test sonucu değildir.

## Güncel 0.8.0+13 — 5 Ekim 2026

- Kompakt okul düzenleme/bildirim, hatırlanan hızlı oyun, gerçek topluluk puanı/kişisel sıra, isteğe bağlı hesap ve yedek, bağlantı toparlama, haftalık kupa sıralaması ve maç sonrası temel inceleme eklendi. Hamle ipuçları çevrim içi kapalı; standart satranç kuralları korunur.
- Temiz kaynak analizi, 141 uygulama testi ve beş başsız Flutter önizlemesi geçti. Testler başarısız hesap geri yüklemesinin uzaktaki yedeği değiştirmemesini, temizlik durumunun korunmasını, sıralama sorgu yarışı/gerçek kişisel sıra ve çevrim dışı hamle engellemeyi kapsar. Loglar releases/flutter-080-analysis.log, flutter-080-tests.log ve flutter-080-previews.log.
- Canlı Spark projesine son kurallar/üç indeks uygulandı; e-posta sağlayıcısı etkin. Üç normal istemciyle 38 maç/davet, ayrı üç normal istemciyle 47 hesap/sonuç/puan/yetki kontrolü geçti. Yalnız iki geçici example.invalid test kimliği owner API ile test için doğrulandı; e-posta gönderilmedi. Uygulama veri işlemleri normal istemcilerle yapıldı. Tüm fixture belgeleri/hesapları temizlendi.
- Hosting gizlilik ve assetlinks HTTP200, kaynak hash eşitliği ve davet sayfası HTTP200 doğrulandı. Güncel Hosting kayıt releases/firebase-080-public-web-verification.json.
- APK 67452789 bayt, SHA256 1D0AE7E4386F53A7A2A6812B21F27A93C4901378499DE1956F6D2C7B519DE914; AAB 66952596 bayt, SHA256 73797A2AC888D10D1979CF73F3B52054BFEC26131E61A446B2C0E8A12AE14B64. Paket com.zpgames.satrancplatformu, versionName0.8.0/code13, min24/target36; mevcut upload imzası, APK signature ve AAB jar verification geçti. İki pakette okul katalogları kaynakla aynı ve lisans mevcut; Desktop kopyaları birebir aynı. Paket kaydı releases/android-080-package-verification.log.
- Beş önizleme previews/080-home.png, previews/080-profile.png, previews/080-weekly-cup-fixture.png, previews/080-account.png, previews/080-review.png. Haftalık sıralamadaki oyuncular ve hesap oturumu yalnız görsel fixture'dır; gerçek oyuncu iddiası yoktur.
- Emülatör açılmadı. Bağlı fiziksel telefona yükleme doğrulandı; fiziksel arayüz kontrolü yapılmadı. İki telefon WhatsApp/App Links ve gerçek cihaz performansı bekler. Play Console bu turda değiştirilmedi; sürüm13 yüklenmedi. Yeni hesap/veri güvenliği/silme beyanları ve gerçek kapalı test koşulları tamamlanmadan herkese yayın yapılamaz.
- Puan iki uygulamanın mutabakatıdır; yetkili motor, resmi üyelik veya Elo iddiası yoktur. Haftalık kupa puan tablosudur, eleme turnuvası değildir. Spark kotaları ve ertelenen kaynak izin değerlendirmesi geçerlidir.

## Ferah tema ve maç seçenekleri — 0.7.1+11

- Ferah Turkuaz varsayılan paleti, Klasik Orman alternatifi ve ayrı açık/koyu tercihi doğrulandı. Siyah-beyaz tahta/taşlar üç görünümde seçilebilir.
- Eski açık ipuçları kapalıya taşınır; çevrim içi tahtanın ipuçları yerel ayardan bağımsız gizlidir. Şahı tehdit altında bırakan hamle reddedilmeye devam eder.
- Beraberlik kabul/red, saatlerin durması, kaydın yeniden açılması, geçmişi koruyan yerel rövanş ve hazır mesaj ekranı kontrol edildi. Maç sonu canlı güncellemeler hamle sayısı değişmeden alınır.
- Tam koşuda 121 uygulama testi geçti; son kaynaklarla dört odaklı maç/tema testi tekrar geçti. Son analiz temiz geçti (127,3 saniye). Yedi telefon boyutu önizlemesi dışa aktarılıp yeni açık/koyu tema, tahta, beraberlik ve maç sonu ekranları görsel olarak incelendi.
- Üç sıradan Firebase istemcisiyle 38 canlı kontrol geçti. Yeni kontroller kendi beraberlik teklifini kabul etmeyi, anlaşılmış beraberlikten sonra hamleyi, serbest metni, mesaj geçmişini değiştirmeyi, 12 mesaj sınırını aşmayı ve üçüncü kişinin rövanş erişimini reddetti. Aynı iki kişi rövanş açabildi; alıcı bekleyen özel davetini bulup silebildi. Test verileri ve misafirleri temizlendi. Kayıt: releases/online-071-firebase-verification.log.
- Güncel kurallar derlenip gerçek Spark projesine uygulandı; gizlilik sayfası hazır mesajlar ve özel rövanşla güncellendi. Ücretli plan açılmadı. Emülatör başlatılmadı. Son USB kontrolünde telefon bağlı değildi.
- Son kaynak AAB'si 129,1 saniyede, APK 44,1 saniyede başarıyla derlendi. İki paket gerçek upload sertifikasını taşır; APK imza doğrulaması geçti. Kalıcı paket com.zpgames.satrancplatformu, sürüm 0.7.1 / 11, minSdk 24, targetSdk 36 ve Satranç Platformu etiketi doğrulandı.
- AAB SHA-256 FFF19E080043634123D6EB9336FD63157143469EE94C0792017E7941CE3B1BBE; APK SHA-256 A92D34C55398BDA556935697A98ACBA1FF330A229CC8AC0B5F269FA9B6542DE5. Masaüstündeki Satranc-Platformu-0.7.1.apk ve Satranc-Platformu-0.7.1.aab kopyaları bu değerlerle eşleşti. Önceki 0.7.0 dosyaları korunur. Son USB kontrolünde cihaz yoktu; yeni APK telefona kurulmadı.
- İmzalı paketlerin son sonuçları ve masaüstü kopyaları store/release-status.json içinde tutulur. Play Console'da 0.7.0 / 10 dahili testi ve Google incelemesine gönderilmiş Alpha sürümü önceki kayıt olarak korunur; 0.7.1 / 11 bu çalışma sırasında konsola yüklenmedi.

## Önceki çevrim içi Firebase ve mağaza sürümü — 0.7.0+10

- Firebase erişim kuralları kullanıcı onayıyla gerçek satranc-platformu projesine başarıyla derlenip uygulandı.
- Son kaynak analizi temiz (9,9 saniye). Tam koşuda 117 kontrol geçti (94 saniye). Son küçük ekran/metin/saat değişikliklerinden sonra challenge_test, widget_test ve online_position_test içindeki 17 kontrol tekrar geçti (42 saniye).
- Üç sıradan Firebase istemcisinde 18 canlı kontrol geçti: davet, eşzamanlı kabul, katılımcı erişimi, sıra, canlı dinleyici, iki istemcide hamle, değişmez geçmiş, sıralamaya yazmayı reddetme, yeniden okuma, eşleşme kuyruğu, iptal ve silme sorguları. Admin SDK/emülatör yok; test belgeleri ve kimlikleri temizlendi. Log releases/online-070-firebase-verification.log.
- Hosting App Links JSON HTTP 200 / application/json, kalıcı paket ve iki sertifika; örnek davet sayfası HTTP 200 ve uygulamada açma bağlantısı doğrulandı. Gerçek fiziksel Android App Link davranışı henüz ölçülmedi.
- 0.7.0+10 AAB 693,1 saniyede derlendi, 61,9 MB; kalıcı manifest ve gerçek upload sertifikası kontrol edildi. SHA-256: 18AA70C3AD0F7679ED97A5B7C40C10B5DB32971B859E1043D74AA53679094AAA.
- APK 194,1 saniyede derlendi, 62,1 MB. Android apksigner doğrulaması başarılı; CN=Satranc Platformu Upload / ZP GAMES sertifikası. aapt: com.zpgames.satrancplatformu, 0.7.0 / 10, minSdk 24, targetSdk 36, Satranç Platformu. SHA-256: 86DF0D3EE86C2AEE012F6CFE4233307763447A4AEA2F81913A1F13F014566E2D.
- Dahili test 0.7.0 / 10 konsolda Etkin ve dahili test kullanıcıları tarafından kullanılabilir. Kapalı Alpha testi, Veri Güvenliği ve mağaza bilgileri dahil 15 değişiklik Google incelemesine gönderildi; konsolda İncelenmekte doğrulandı. Google onayı ve herkese üretim yayını henüz yok. Son durum store/release-status.json içinde.
- Son USB kontrolünde bağlı fiziksel telefon yok; 0.7 telefona yüklenmedi. İki telefon/WhatsApp alıcı akışı testi yapılmadı. Emülatör başlatılmadı. Masaüstündeki Satranc-Platformu-0.7.0.apk ve Satranc-Platformu-0.7.0.aab dosyaları proje çıktılarının SHA-256 değerleriyle eşleşti.
- KGP eklentilerinin gelecek Flutter uyumu ve SDK XML sürüm uyarıları derlemeyi durdurmadı. Mevcut başarılı sürümün uyarıları gelecekteki araç yükseltmesinde ele alınmalıdır.

Aşağıdaki kayıtlar eski sürümlerin tarihçesidir; eski bekleyen işlemler yukarıdaki güncel durumu geçersiz kılmaz.

# Doğrulama — 4 Ekim 2026

Windows 11, Flutter 3.47.0 stable, Dart 3.13.0, Android SDK 36.1. Güncel proje araçları Temurin Java 21 kullanır; önceki 3 Ekim Android kontrolleri Android Studio JBR 25 ortamındaydı.

## Play Console / Firebase hazırlığı ve Java ortamı — 4 Ekim 2026

- ZP GAMES Play Console hesabı ve Firebase proje listesi tarayıcıdan okundu. Satranç Platformu kaydı bulunmadı. Play formu Türkçe / ücretsiz oyun ve `com.zpgames.satrancplatformu` ile hazırlandı; konsol paket kullanılabilir sonucunu gösterdi.
- Firebase `Satranc Platformu` / `satranc-platformu` oluşturma formu, Analytics ve Gemini kapalı biçimde hazırlandı. Proje oluşturma eylemi otomatik onay incelemesince yeni kayıt için açık yetki eksikliği gerekçesiyle reddedildi. Başka yöntemle oluşturma denenmedi; Play hukuk beyanları onaylanmadı veya gönderilmedi. Kullanıcı onayı ve hedef yaş sorusu bekliyor.
- Yerel mağaza modu, kalıcı uygulama kimliği ve ayrı yükleme imzasını zorunlu tutacak şekilde eklendi. Dört PowerShell hazırlık betiğinin sözdizimi, hazırlık modunun anahtar üretmemesi ve imzasız AAB betiğinin erken durması doğrulandı.
- İlk Java kontrolünde eski Android Studio JBR klasörünün bulunmadığı görüldü. Resmi Adoptium Java 21 LTS arşivi SHA-256 ile doğrulandı; tüm ZIP girdilerinin hedef proje araç klasörü içinde kalması denetlendi ve `java -version` Temurin 21.0.12.1+1-LTS olarak geçti. Kaynak ve SHA-256 [kurulum kaydında](PLAY_FIREBASE_SETUP.md). Sistemdeki JAVA_HOME değiştirilmedi; proje betikleri proje Java'sını seçer.
- Bu Java ile `gradlew help --offline --console=plain` BUILD SUCCESSFUL döndürdü (2 dakika 32 saniye); Kotlin Gradle kaynağı derlendi, Android yapılandırması yüklendi. Yalnız mevcut Flutter/AGP kullanımdan kaldırma uyarıları görüldü.
- Aynı kaynaklarda `gradlew help -PchessStoreBuild=true --offline --console=plain`, eksik yükleme imzası için beklenen Play upload signing is missing hatasıyla durdu. Mağaza yapılandırmasının deneme imzasına düşmemesi doğrulandı.
- Yeni yükleme anahtarı, gerçek AAB ve Firebase SDK bağlantısı henüz oluşturulmadı. Yeni telefon paketi yüklenmedi; telefon için son başarılı teslim aşağıdaki 0.6.1 kaydıdır. Emülatör başlatılmadı.

## Tam ekran, taş sesi ve görünür rakip hamlesi — sürüm 0.6.1+8

- Son tam koşuda 116 kontrolün 113'ü geçti. İki hareket testi eğrinin tam orta nokta yerine ara bir konumda olduğunu hesaba katacak şekilde düzeltildi; bir görsel önizlemenin uygulama anahtarı düğme anahtarıyla çakıştığı için ayrıldı. Bu üçü test/önizleme düzeltmesidir; son tam koşudan sonra üretim kaynakları değişmedi. Ardından 9 yeni oyun sunumu testi ve 2 görsel önizleme kontrolü birlikte geçti: 11/11 (57 saniye). Böylece 116 farklı kontrolün tümü doğrulandı; tek bir 116/116 tam koşu yapıldığı iddia edilmez.
- `flutter analyze lib test tool/visual_preview_test.dart tool/test_assets.dart` son kaynaklarda temiz geçti (289,1 saniye).
- Tam ekranın 390 × 844, 320 × 740 ve 844 × 390 px / 1,3 kat yazı boyutunda taşmaması; normal/tam ekran geçişinde hamle, yön, saat ve ses tercihinin korunması kontrol edildi. İlk geri tuşu yalnız tam ekrandan çıkar; ikinci geri dönüş oyunu koruyarak Oyna menüsüne gider.
- Sesin yalnız gerçekleşen yasal hamlede bir kez çalması, geçersiz seçimlerde çalmaması ve kapatma/açma davranışı kontrol edildi. Android'e özgün 300 ms, 24 kHz, 16 bit, mono PCM taş sürükleme/yerleştirme sesi eklendi. APK'de 14.444 baytlık WAV kaynağı sıkıştırılmadan bulunur; SoundPool kaynak yüklemesi için biçim ve paketleme doğrulandı. Bu özellik dokunarak yapılan hamlenin hareket sesidir; sürükle-bırak giriş yöntemi eklenmedi.
- Bilgisayarın hızlı yanıtı için en az 650 ms bekleme, 380 ms görünür taş kayması, 2D/üstten ters yön, hareket azaltma ve geciken yanıtın geri alma/ayrılmada iptali kontrol edildi. Çevrim içi tahtanın FEN yenilemesiyle hareket ve ses davranışı sahte maç deposuyla doğrulandı; gerçek iki cihazlı çevrim içi maç yapılmadı.
- Açık/koyu tam ekran önizlemeleri `previews/game-fullscreen.png` ve `game-fullscreen-dark.png` görsel olarak incelendi. Bunlar başsız Flutter çıktılarıdır, fiziksel telefon görüntüsü değildir.
- Android ARM64 release paket 863,2 saniyede derlendi (`--no-shrink`, deneme imzası). Yeni dosya `releases/satranc-platformu-0.6.1-arm64.apk`: 26.920.681 bayt (yaklaşık 25,7 MiB); SHA-256 `81C56575C7A4E32CC074BE769B644D094A66DBF69A97D1B612A886AD6BBB0AA6`. Önceki 0.6.0 APK ayrı dosyada korundu.
- Paket kaynaklarında application-label=Satranç Platformu, versionName=0.6.1, versionCode=8, minSdk=24 ve targetSdk=36 doğrulandı; Kotlin tam ekran/ses köprüsü Android derlemesinden geçti.
- Telefon yeniden bağlandıktan sonra fiziksel RMX3890 cihaza mevcut kurulumu ve kayıtları koruyan 0.6.1+8 güncellemesi yüklendi (Success). Paket versionName=0.6.1 / versionCode=8 olarak doğrulandı. Başlatma Status: ok, COLD, 934 ms döndürdü; uygulamanın MainActivity ekranı ön plandaydı. Yalnız uygulamanın kendi günlüklerinde açılış hatası görülmedi. Tam ekranın sistem çubukları, sesin duyulması ve animasyon performansı fiziksel dokunma/işitme kontrolü bekliyor. Emülatör başlatılmadı.
- Üç özgün simgenin kullanıcı seçimi hâlâ bekliyor; mevcut uygulama simgesi korundu. [Platform davranışı ve kaynaklar](GAME_PRESENTATION.md).

## Satranç Platformu, açılış ve geri dönüş — sürüm 0.6.0+7

- Tam koşuda 105 uygulama testi ve 2 görsel önizleme kontrolü birlikte geçti: 107/107 (188 saniye). Açılışta Material metin bağlamı düzeltildikten sonra ilgili 21 uygulama testi ile 2 görsel önizleme testi tekrar geçti: 23/23 (39 saniye).
- `flutter analyze lib test tool/visual_preview_test.dart tool/test_assets.dart` temiz geçti (64,7 saniye). Son Material düzeltmesinden sonra açılış dosyasının Dart analizi de temiz geçti.
- Ana menülerin Ana Sayfa'ya dönüşü, doğrudan alt sayfaların üst menüsü, geçersiz bağlantı, geçmiş/inceleme, okul/sınıf basamakları, açık pencerenin önce kapanması ve Ana Sayfa'da uygulamanın kapanmaması doğrulandı. Tahtadan geri dönüş hamleyi ve taslağı korur; tekrar devam etme de kontrol edildi.
- Süresiz → 1/2/3/5 dakika, uzun seçenekler, 320 × 740 px / 1,3 kat yazıda 90 dakika + hamlede 30 saniye seçimi ve kayıt yeniden yükleme kontrol edildi. Bunlar bütün oyun için oyuncu başına sürelerdir.
- Satranç Platformu adı; 2,4 saniyelik taş yağmuru ve ZP GAMES açılışı; hareket azaltmada 650 ms sabit görünüm ve menü değişince açılışın tekrarlanmaması kontrol edildi. Son açılış PNG'si ile kısa/uzun süre ekranları görsel olarak incelendi. [Marka ve simge kaynakları](BRANDING.md).
- Android ARM64 release paket 294 saniyede derlendi (`--no-shrink`, deneme imzası). Yeni dosya `releases/satranc-platformu-android-arm64.apk`: 26.905.641 bayt (yaklaşık 25,7 MiB); SHA-256 `6502EB2BAC2CC9AD3AF5A4F4FE48B79B3A738CE23CFBF9B7BC0B863C6BDFE10F`. Eski 0.5.0 paketi önceki dosya adında korundu.
- Paket kaynaklarında application-label=Satranç Platformu, versionName=0.6.0, versionCode=7, minSdk=24 ve targetSdk=36 doğrulandı. Android 12+ için açık/koyu yerel açılış kaynakları derlemeden geçti.
- Fiziksel RMX3890 telefona mevcut kurulum ve kayıtları koruyan güncelleme yüklendi (Success). Telefon paket sürümü 0.6.0/7; başlatma Status: ok, COLD, 702 ms; MainActivity ön planda ve ekran kilidi açık olarak doğrulandı. Kendi uygulama günlüklerinde açılış hatası görülmedi.
- Telefonda oyun tahtası açıkken kendi uygulamasının ekranı ve erişilebilirlik ağacı alındı: `previews/android-game-060.png`, `android-ui-060.xml`. Aktif tahtaya hamle yapılmadı veya ayarlar değiştirilmedi. Fiziksel geri tuşu ve animasyon FPS ölçümü yapılmadı; bunlar başsız kontrollerle karıştırılmaz. Emülatör başlatılmadı.
- Üç özgün simge imagegen ile üretildi ve projeye kopyalandı; kullanıcı seçimi henüz gelmedi. Yeni launcher simgesi bu APK'ye uygulanmadı. [Üretim istemleri](../design/icon-options/PROMPTS.md).

## Hamle görünümü, kararlı sıra geçişi ve sınıf listeleri — sürüm 0.5.0+6

- Son tam koşuda 84 uygulama testi ve 2 görsel önizleme kontrolü birlikte geçti: 86/86. Son kaynak analizi temiz geçti (8,7 saniye).
- Tercihin saklanıp yeniden yüklenmesi; üç görünümde hamle işaretlerini kapatma/açma; kapalıyken yasal dokunma ve üç kamera açısında 3D taş alma doğrulandı. Eski tercih kayıtlarında işaretler açık kalır.
- Saat açık/kapalı iken her hamle, geri alma ve sıfırlamada yalnız bir tutarlı pozisyon/saat/son hamle bildirimi; bilgisayarı seçim ara karesi olmadan oynatma doğrulandı. Hızlı 3D yanıt, insan hamlesinin kayma süresi boyunca uygulanmaz.
- 320 px / 1,3 kat yazıda kayıt sürerken ve tamamlanınca düğmelerin konumu aynı kaldı; saat alanlarının yatay konumu sıra değişiminde korunur. Kayıt hataları ve yeniden deneme kontrolleri de geçti.
- Seçili okulun sınıflarının ortalama puanla sıralanması, farklı okulun aynı adlı sınıfının dışarıda kalması, sınıftaki oyuncular ve listeye geri dönüş; kayıtlı topluluğa geçiş doğrulandı. Aynı adlı iki oyuncuda sıra kimlikle eşleşir ve Sıramı bul ilgili satırı görünür yapar. Demo kaynağı misafire hayali sıra vermez.
- Sıcak yüzey geçişleri, tonlu simgeler, ölçülü gölgeler ve pirinç vurgularla açık/koyu ekran önizlemeleri yenilendi. Oyna, koyu ana sayfa, sınıf sıralaması, sınıftaki oyuncular, hamle işaretleri açık/kapalı ve tahta altı seçenekler görsel olarak incelendi. Bunlar başsız Flutter çıktılarıdır; fiziksel cihaz ölçümü değildir.

- Son kaynaklarla Android ARM64 release paket 89,7 saniyede derlendi (`--no-shrink`, deneme imzası). `releases/chess-platform-android-arm64.apk`: 26.837.529 bayt; SHA-256 `900D683E85F0D21DCBD85A0905F50D8F326D9317733BA4AD5798782E7D784AD7`.
- APK içindeki 6.947.720 baytlık ARM64 `libapp.so` dosyasında yeni hamle seçeneği, sınıf sıralaması ve sabit kayıt açıklaması UTF-16 metinleri; `showLegalMoves` tercih anahtarı doğrulandı.
- Telefon yeniden bağlandıktan sonra fiziksel RMX3890 cihaza mevcut kayıtları koruyan güncelleme yüklendi (Success). Paket versionName=0.5.0 / versionCode=6 / minSdk=24 / targetSdk=36 olarak doğrulandı; başlatma Status: ok döndürdü (soğuk açılış 633 ms), ön plandaki etkinlik uygulamanın MainActivity ekranıydı. Kendi uygulama kayıtlarında açılış hatası görülmedi. Emülatör kullanılmadı. Yeni sürümde ayrıntılı dokunma veya fiziksel FPS ölçümü yapılmadı; başsız testler telefon ekranındaki titremeyi ölçmez.

## Zorluk seviyeleri ve oyuncu adları — sürüm 0.4.0+5

- 74 uygulama testi ve 2 görsel önizleme kontrolü doğrulandı. Tam koşuda 75 kontrol geçti; eski oyun başlığını bekleyen tek test yeni metne güncellendi ve tek başına yeniden geçti. Son kaynaklarda 76 kontrolün tamamı geçerli.
- Dört seviyenin yasal hamle ve doğrudan mat seçimi; Orta'nın Kolay'ın kaçırdığı karşı alıştan kaçınması; bütçe kesilince yasal yedek hamle; eski kaydın Orta'ya geçmesi ve bilinmeyen kayıt seviyesinin reddi doğrulandı.
- 320 × 740 px / 1,3 kat yazıda dört seviye seçimi, Sen/Bilgisayar adları ve Usta ile tahta açılışı geçti. Üst bilgi sarılarak taşma giderildi.
- Seçilen Zor seviyesinin hamle isteğine gönderilmesi, taslak deposu yeniden oluşturulunca korunması, devam bağlantısındaki yeni parametrenin kayıtlı seviyeyi değiştirmemesi ve geciken yanıt/geri alma kontrolleri geçti.
- Yeni Oyna ekranı ile açık/koyu Usta tahta önizlemeleri üretildi ve görsel olarak incelendi. Bunlar başsız Flutter çıktılarıdır.
- Son analiz `flutter analyze lib test tool/visual_preview_test.dart tool/test_assets.dart`: sorun yok (15,9 saniye).
- Android ARM64 release paket 188,2 saniyede derlendi (`--no-shrink`, deneme imzası). `releases/chess-platform-android-arm64.apk`: 26.771.869 bayt; SHA-256 `6F93337BFE4A6E2DFCBE7BE6608CF74F3CF09C858F0AAE7DCEAF0449201C3C49`. Paket içindeki 6.882.184 baytlık `libapp.so` içinde yeni oyuncu adları, zorluk seçimi ve `_ComputerSearch` motoru doğrulandı.
- Fiziksel RMX3890 telefona mevcut kurulumu koruyan güncelleme yüklendi (`Success`). `versionName=0.4.0`, `versionCode=5` doğrulandı; başlatma isteği `Status: ok` döndürdü ve kendi uygulama kayıtlarında açılış hatası görülmedi. Emülatör kullanılmadı.
- Telefon kilitli kaldığı için gerçek ekranda dokunma kontrolü bekliyor. Ekran ve zorluk kontrolleri başsız testler ile yapıldı; telefonda motor performansı ölçülmedi. Aşağıdaki kayıt önceki sürüme aittir.

## Kompakt ekranlar — sürüm 0.3.1+4

- 69 uygulama testi ve 2 görsel önizleme testi birlikte geçti: 71/71. Tüm ana sayfalar için 320 × 740 px / 1,3 kat yazı boyutu; ayrıca küçük ekranda 3D görünüm seçimi taşma vermedi.
- Son analiz `flutter analyze lib test tool/visual_preview_test.dart tool/test_assets.dart`: sorun yok (179,1 saniye).
- 390 × 844 px başsız Flutter önizlemelerinde Ana Sayfa, Oyna, Profil, Liderlik ve Sosyal görsel olarak incelendi. Oyna ve Profil seçenekleri normal yazı boyutunda ilk ekranda görülebiliyor. Uzun liderlik listesi kaydırılabilir kalır.
- Ortak boşluklar ve başlıklar küçüldü; kısa eylem kartları, profil düzenleme simgesi, birleşik liderlik topluluk listesi ve küçük malzeme örnekleri kontrol edildi. Yerel hamle, saat, taslak, kalıcılık, rakip ve gezinme testleri geçti.
- Önizlemeler `previews/play-simple.png`, `profile-compact.png`, `social-compact.png`, `home-light.png`, `leaderboard-light.png` dosyalarında. Bunlar telefon ekran görüntüsü değildir.
- Android ARM64 release paket 246,9 saniyede derlendi (`--no-shrink`, deneme imzası). `releases/chess-platform-android-arm64.apk`: 26.771.869 bayt, SHA-256 `532EB52E3D85FB048054CC81C48EBE8E360A1212259C137211817C402E358689`.
- Fiziksel RMX3890 telefona mevcut kurulumu koruyan güncelleme yüklendi (`Success`); paket bilgisi `versionName=0.3.1`, `versionCode=4` doğrulandı. Başlatma isteği `Status: ok` döndürdü; kendi uygulama kayıtlarında açılış hatası görülmedi. Emülatör kullanılmadı.
- Telefon kilitli kaldığı için gerçek ekranda dokunma kontrolü yapılamadı. Ekran düzeni kontrolleri yukarıdaki başsız Flutter çıktılarıyla yapıldı. Aşağıdaki 0.3.0 kaydı önceki sürüme aittir.

## Yeni akışlar ve telefon yüklemesi — sürüm 0.3.0+3

- 69/69 uygulama testi geçti; 2 görsel önizleme testi de geçti. Son analiz `flutter analyze lib test tool/visual_preview_test.dart tool/test_assets.dart`: sorun yok.
- Android ARM64 release paket 472,6 saniyede başarıyla derlendi (`--no-shrink`, deneme imzası). Son APK `releases/chess-platform-android-arm64.apk`: 26.771.877 bayt (yaklaşık 25,5 MiB), SHA-256 `E20B4EB58326E72F20BAAE51D81FB65527D6E82B540B2091909DA78B5BACBFBA`.
- APK içinde 191.897 baytlık ayrıntılı model ve 305.029/633.330 baytlık özgün doku dosyaları doğrulandı. Kaynaklar: [ASSET_CREDITS.md](ASSET_CREDITS.md).
- USB ile bağlı fiziksel RMX3890 / Android 15 (API 35) telefona mevcut kurulumu koruyan güncelleme yüklendi; yükleme `Success` döndürdü. Telefonda paket bilgisi `versionName=0.3.0`, `versionCode=3`, `minSdk=24`, `targetSdk=36` olarak doğrulandı. Emülatör kullanılmadı.
- Bilgisayar rakibinin yasal yanıt, mat ve terfi seçimi test edildi. Ekran testinde kullanıcı hamlesinden sonra bilgisayar yanıtı, geri alma sırasında geciken yanıtın atılması, varsayılan süresiz oyun ve rakip türünü koruyarak yeni servislerle oyuna devam etme doğrulandı.
- Üst basamak değişince alt seçimlerin temizlenmesi, farklı okulların 9-A sınıflarının karışmaması, ülke/şehir/okul ve okuldan bağımsız grup filtreleri; seçimlerin yeniden yüklenmesi ve yazma hatasının önceki değeri koruması test edildi. Profil ve liderlik gezinme testleri geçti.
- Ayrıntılı model dosyasının altı taş geometrisi, sonlu koordinatlar/normaller, mobil geometri bütçesi ve bozuk/kesilmiş dosya reddi doğrulandı. Gerçek model ile 3D e2–e4 dokunması geçti. Başsız görsel testler aynı kaynak baytlarını dosya asset adaptörüyle okur; bu testlerde telefonun platform asset kanalı kullanılmaz.
- 12 seçenekli koleksiyon, Oyma Staunton ile ceviz/mermer oyun ekranları, basit Oyna ve basamaklı kayıt ekranı PNG'leri incelendi. Bunlar başsız Flutter çıktılarıdır, fiziksel telefon görüntüsü değildir.
- Uygulama başlatma isteği `Status: ok` döndürdü ve kendi hata kayıtlarında açılış hatası görülmedi. Telefon kilitli olduğundan gerçek ekran, dokunma ve uygulamayı yeniden açarak kalıcılık kontrolü kullanıcı kilidi açınca tamamlanacak. Fiziksel telefon FPS/batarya/uzun süreli performans ölçümü yapılmadı.
- Canlı çevrim içi maç, gerçek hesap ve okul üyeliği doğrulaması bu sürümde etkin değildir; kullanıcı arayüzü bunu açıkça belirtir.

## Tahta koleksiyonu — sürüm 0.2.0+2

- Android ARM64 release APK son kaynaklarla 104,2 saniyede başarıyla derlendi (`--no-shrink`, deneme imzası); `releases/chess-platform-android-arm64.apk` güncellendi. 25.671.333 bayt (yaklaşık 24.5 MB); SHA-256 `6115E076805E870AD6E844BFFE06DF284CA404698A062F1E1AD3511711DDACB0`. APK içindeki iki doku dosyası kaynaklarla aynı boyuttadır; ARM64 `libapp.so` yeni `appearance.board.v1` anahtarını içerir. Derlemede JBR native-access ve mevcut Android SDK XML araç sürümü uyarıları oluştu; derleme başarılıdır.
- `flutter test test tool/visual_preview_test.dart --concurrency=2`: 59/59 geçti (57 uygulama testi + 2 görsel önizleme testi).
- `flutter analyze lib test tool/visual_preview_test.dart`: sorun yok.
- Sade 2D, üstten gerçekçi ve 3D masa içinde e2–e4 / çevrilmiş e7–e5 hamleleri doğrulandı. Görünüm veya taş seti değiştirilince hamleler, FEN ve yön korunur.
- Üç kamera açısı ve iki tahta yönünde 64 kare projeksiyonu doğrulandı. Taş başına dokunarak kendi karesini seçme ve düşük açıda komşu e3 karesine hamle yapma kontrol edildi. Üç açıda karşı taşın başına dokunarak yasal alma hamlesi test edildi; alma hedefi taş tabanının çevresinde halka olarak görünür.
- Gerçek hacimli altı taş geometrisi, yüz yönleri ve atın eğimli kenarları kontrol edildi. Görünen üçgenler toplu çizilir; bu testler telefon FPS ölçümü değildir.
- Renkli 3D görünüm oyun ekranındaki paletten seçildi; maç incelemesi aynı tercihi kullanırken salt okunur kaldı. 320 px ekran / büyük yazıda malzeme, taş, kamera ve sıfırlama kontrolleri doğrulandı.
- Tercih deposu yeniden oluşturulunca tüm görünüm alanları korundu; bozuk JSON/sürüm, hızlı seçimlerin birleşmesi, yazma hatası ve yeniden deneme kontrol edildi. Depo testleri aynı JSON adaptörünü bellek deposuyla kullanır.
- Ahşap/mermer dokuları projeye kopyalandı. Dokuzlu tahta koleksiyonu, açık/koyu 3D oyun, renkli 2D oyun ve görünüm ekranı PNG'leri üretildi ve görsel olarak incelendi; emülatör/telefon görüntüsü değildir.
- Emülatör veya gerçek cihaz başlatılmadı. Fiziksel Android cihaz performansı, gerçek dokunma ve SharedPreferences testi bekliyor. Koleksiyon ayrıntıları ve imagegen istemleri: [BOARD_APPEARANCE.md](BOARD_APPEARANCE.md).

## Önceki otomatik yerel kayıt ve oyuna devam etme

- Android ARM64 release APK güncel kaynaklarla 182,6 saniyede başarıyla derlendi (`--no-shrink`, deneme imzası) ve `releases/chess-platform-android-arm64.apk` güncellendi. 21.396.310 bayt (yaklaşık 20.4 MB); SHA-256 `D6A2FB2286B4DA3EE8D49E0E1676C24ECD45556A1DA21920FD0ADDD517E852B2`. APK içindeki ARM64 `libapp.so` yeni otomatik kayıt anahtarını ve taslak sürüm doğrulamasını içerir.
- `flutter test test tool/visual_preview_test.dart --concurrency=2`: 45/45 geçti (44 uygulama testi + 1 görsel önizleme testi).
- `flutter analyze lib test tool/visual_preview_test.dart`: sorun yok.
- Uygulamanın arka plana geçmesini temsil eden widget yaşam döngüsü testi, saatin durmasını ve ön plana gelince kendiliğinden başlamamasını doğruladı. Tahtadan çıkış, Oyna kartı ve yeni servislerle uygulamayı yeniden oluşturup aynı oyun kimliğiyle devam etme test edildi.
- Taşlar, tam SAN geçmişi, milisaniye cinsinden saatler, saatli geri alma anlık görüntüleri, son hamle kareleri ve yön JSON'dan geri yüklendi. Geri alma, üç konum tekrarı ve süre dolmuş oyunun yeniden başlamaması doğrulandı.
- Eski yazmanın yeni oyun kaydını geri çevirmemesi için sıralı yazma/temizleme test edildi. Disk yazma/temizleme hatasında bellekteki tahta tutulur; hata görünür ve yeniden deneme çalışır. Yeni oyunun mevcut taslağı değiştirmesinde vazgeçme ve onaylama widget testiyle doğrulandı.
- Bozuk JSON, desteklenmeyen sürüm, eksik saat geçmişi, saat/hamle sırası uyuşmazlığı ve olmayan devam kaydı ele alındı. Dar ekran/büyük yazı testinde devam kartı ve yeniden açılan tahta da kullanıldı.
- Açık/koyu devam etme kartı ve duraklatılmış tahta önizlemeleri üretildi. Flutter render çıktılarıdır; emülatör veya telefon görüntüsü değildir.
- Emülatör ya da fiziksel cihaz başlatılmadı. Android SharedPreferences kalıcılığı ve gerçek işletim sistemi yaşam döngüsü cihaz testini bekler. Ani kapatmada son tamamlanmış yazma geri yüklenir; işletim sistemi bekleyen yazmayı tamamlamadan süreci sonlandırabilir.

## Önceki yerel maç geçmişi ve oyun incelemesi

- Android ARM64 release APK güncel kaynaklarla 71,5 saniyede başarıyla derlendi (`--no-shrink`, deneme imzası) ve `releases/chess-platform-android-arm64.apk` dosyası güncellendi. 21.396.250 bayt (yaklaşık 20.4 MB); SHA-256 `F2232EA99E2ECC019D3CF003BF18BFBA0DB62977C84B7CDFDC8F9E13F307F703`.
- `flutter test test tool/visual_preview_test.dart --concurrency=2`: 31/31 geçti (30 uygulama testi + 1 görsel önizleme testi).
- `flutter analyze lib test tool/visual_preview_test.dart`: sorun yok.
- Kaydetme, aynı kaydı güncelleme, Profil üzerinden geçmişi açma, hamleleri ileri/geri izleme ve kaydı değiştirmeden inceleme widget testiyle doğrulandı.
- Depo yeniden oluşturulunca kayıtların korunması, eşzamanlı yazma, son 100 kaydı tutma, yazma hatasının kullanıcıya ulaşması ve sonraki denemenin çalışması test edildi.
- Rok, geçerken alma ve at terfisi özel başlangıç konumlarından yeniden oynatıldı; PGN çıktıları tekrar okunarak son konumla eşleşti. Sonuç ve süre kontrolü PGN etiketleri doğrulandı.
- Boş geçmiş, bilinmeyen kimlik ve geçersiz hamle kaydı uygulamayı kapatmadan açıklama gösterir. 320 px ekran ve büyük yazıda yeni geçmiş/inceleme ekranları kontrol edildi.
- Açık geçmiş ile açık/koyu oyun incelemesi PNG'leri üretildi ve görsel olarak kontrol edildi; Flutter render çıktılarıdır, Android cihaz görüntüsü değildir.
- Emülatör veya gerçek Android cihaz başlatılmadı. Kalıcılık testleri aynı JSON kayıt adaptörünü bellek deposuyla kullanır; Android SharedPreferences cihaz testi henüz yapılmadı.

## Önceki auth adaptörü doğrulaması

Taşınan `StudioProjects/ChessPlatform` çalışma klasöründe yeni auth repository testleri eklendikten sonra `flutter test`: 20/20 geçti; `flutter analyze lib test`: sorun yok. Güncel kaynaklarla Android ARM64 release APK yeniden derlendi: 21.330.334 bayt (yaklaşık 20.3 MB), SHA-256 `BD506DDBED81EEB4ED9A283EF111D370765E99D9B64EBF2AE41AA52BCB4C0CDF`. Derleme 218 saniyede tamamlandı; Android SDK XML v4 uyarısı verdi ancak başarılı oldu. Emülatör başlatılmadı.

Sosyal topluluk önizlemesi ve yerel saat eklendikten sonra `flutter analyze lib test`: sorun yok; `flutter test`: 17/17 geçti. Android ARM64 release APK güncel kaynaklarla yeniden derlendi (`--no-shrink`, deneme imzası; 21.330.334 bayt / yaklaşık 20.3 MB). Proje `releases/` klasörüne ve teslim klasörüne kopyalandı. SHA-256: `A622DE76E160A72747DC9AB6266D11916D27FE461CEBE2566D418F9B2EC3B0FE`. SDK derlemesi tamamlanırken eski Android SDK araçlarının SDK XML v4 uyarısı verdi; derlemeyi engellemedi. Emülatör başlatılmadı.

## Önceki doğrulama — 2 Ekim 2026

- Sunucu yetkili maç istemcisi sonrasında `dart analyze lib`: sorun yok.
- Güncel sürümde sosyal önizleme ve saat testleri dahil `flutter test`: 17/17 geçti.
- Ayrı görsel önizleme testi: geçti. Açık/koyu ana sayfa, oyun ve liderlik PNG dosyaları oluşturuldu ve kontrol edildi.
- Android x64 debug APK başarıyla derlendi.
- WebSocket istemcisi eklendikten sonra Android ARM64 release APK başarıyla derlendi; 21.330.114 bayt (yaklaşık 20.3 MB). Deneme imzası kullanılır; mağaza yayını için üretim imzası gerekir.
- Güncel kaynaklarla Flutter Web release başarıyla derlendi; tarayıcı WebSocket taşıyıcısı Dart2JS derlemesinden geçti. Yerel CanvasKit ve font kaynakları hazır. Windows sistem kaynağı baskısı nedeniyle `--optimization-level=1 --no-wasm-dry-run --no-web-resources-cdn` kullanıldı.
- Tarayıcıda beş menü, yasal e2–e4 hamlesi ve sıra değişimi, okul sıralamasına geçiş, davet oluşturma/kopyalama ve koyu tema doğrulandı. Tema sistem tercihine geri alındı.
- Android cihaz testi tamamlanmadı. Kullanıcının talebiyle emülatör kapalı bırakıldı; son sürüm Android cihazda başlatılmadı.
- Güncel tarayıcı önizlemesinde misafir profili ve güvenlik/gizlilik tercihleri açıldı; Oyna ekranında sunucu/oturum yokken yerel pratik açıklamasının gösterildiği doğrulandı.
- Çevrim içi maç ekranı yeni bir sunucu veya oturum olmadan uçtan uca çalıştırılmadı; REST ve WebSocket adaptörleri statik analiz ve Android/Web derlemesinden geçti. Canlı olay, tekrar bağlantı ve gerçek sunucuya hamle gönderimi doğrulanmadı.
- Bu çalışma sırasında Android emülatörü başlatılmadı ve uygulama cihazda çalıştırılmadı.

[Emülatörün disk gereksinimi](https://developer.android.com/studio/run/emulator-troubleshooting).

PNG önizlemeleri Flutter render çıktılarıdır. `web-*.jpg` dosyaları canlı tarayıcı ekran görüntüleridir; Android cihaz görüntüsü olarak sunulmaz. WhatsApp paylaşım URI'si test edildi; alıcıya mesaj gönderilmedi. iOS build Windows üzerinde yapılmadı.

Release üretiminde varsayılan pub adımı kullanıldı. SDK'nın üretim eklenti kayıtlarını yenilemesiyle integration_test'in Java kayıt hatası giderildi; üretilen dosyaya elle müdahale edilmedi. Derleme belleği 1.5 GB, işçi sayısı 1 olarak ayarlandı.

Flutter doctor, Android lisans durumunu unknown raporladı. cmdline-tools 23, SDK manager'ı yeni Android CLI'a yönlendiriyor ve --licenses seçeneğinin artık gerekli olmadığını bildiriyor. Gerçek Android derlemeleri başarılıdır. Windows masaüstü Visual Studio eksikliği bu Android hedefini engellemez.

Önceki Sprint 4 APK'sinin SHA-256 değeri:

9A6B7AA8D47DA5A3EAB8AE90C494A691B251D861DE8F3ABEBC7095020BD6C01F

Önceki, sosyal önizleme ve yerel saat içeren APK'nin SHA-256 değeri:

A622DE76E160A72747DC9AB6266D11916D27FE461CEBE2566D418F9B2EC3B0FE

3 Ekim 2026'da taşınan projeden yeniden üretilen güncel APK'nin SHA-256 değeri:

BD506DDBED81EEB4ED9A283EF111D370765E99D9B64EBF2AE41AA52BCB4C0CDF




## Türkiye okul rehberi — 0.7.2+12 — 4 Ekim 2026

- 81 ilde 55.117 kamu rehberi kurumu + 12.619 resmî özel okul, toplam 67.736 okul/kurum çevrimdışı katalog olarak eklendi; kaynak commit ve ham veri SHA256 doğrulandı. Giresun 393 kayıt. Resmî özel okul rehberinin 81 ilde bütün sayfaları ve bildirilen satır sayıları doğrulandı; 12.620 satırdan 1 tam tekrar çıkarıldı. 99 il dışı kayıt ayrıldı. Kaynak tarihi 31 Ağustos 2026; tüm devlet/özel okulların eksiksiz güncel kapsamı doğrulanmış değildir.
- Yeni aramalı şehir/okul ve okul altında sınıf-şube seçimi, eski kimlikler, yeni kayıtların yeniden yüklenmesi, okullar arasında sınıf ayrımı, Latin klavyeyle Türkçe arama ve 320px/1.3 metin ölçeği geçti. Büyük liderlik listesi 40 satırlık gösterim ve arama kullanır.
- Temiz kaynak analizi; 127 uygulama testi; dört 390×844 telefon boyutu önizlemesi geçti ve görsel olarak incelendi. Loglar releases/flutter-072-analysis.log ve flutter-072-tests.log içindedir.
- APK ve AAB sürüm 0.7.2/code12, mevcut upload imzası, APK doğrulaması ve AAB jar signature kontrolü geçti. Her iki Android paketinde katalog SHA256 kaynakla aynı; MIT kaynak lisansı mevcut. Desktop Satranc-Platformu-0.7.2.apk/.aab kopyaları kaynak hash değerleriyle aynı. Paket kontrolü releases/android-072-package-verification.log içindedir.
- Firebase/ağ işlevleri veya kurallar bu değişiklikte değiştirilmedi; önceki sürümün 38 canlı kontrolü tarihsel kanıt olarak korunur. Canlı Firebase testi yeniden çalıştırılmadı. Emülatör başlatılmadı, fiziksel telefona yükleme yapılmadı. Play Console'a yükleme ve MEB kaynak yeniden kullanım izni değerlendirmesi yapılmadı; izin işi kullanıcı talebiyle sonraya bırakıldı.
## Güncel 0.8.7+20 — 16 Ekim 2026

- Sprint 1 release kalite kapısı kaynakta tanımlandı: `tool/quality_gate.ps1` biçim, analyze, test ve mağaza paketini tek akışta durdurur; emulator başlatmaz.
- Firebase App Check, Crashlytics, Performance ve FCM entegrasyonları Android girişine eklendi. FCM tokenları yalnız sahibi okuyup değiştirebileceği `notificationTokens/{uid}` belgelerinde tutulur; izin isteği uygulama başlangıcında açılmaz.
- Sunucu otoriteli hamle için callable sözleşmesi ve idempotency istemcisi hazırlandı: [SERVER_AUTHORITY.md](api/SERVER_AUTHORITY.md). Spark planı nedeniyle Functions dağıtımı ve App Check enforcement bu yerel sprintte açılmadı.
- `dart analyze lib`: temiz. Flutter testleri: **165/165 geçti**. Doğrudan Gradle `bundleRelease` ve `assembleRelease`: başarılı. Emülatör başlatılmadı; fiziksel cihaz `5c76ad26` sürüm 0.8.7+20 ile güncellendi.
- İmzalı AAB: `releases/satranc-platformu-play-0.8.7+20.aab`, 75.065.536 bayt, SHA-256 `54C322385F6FF7C16DD69FE736CCB43843ADE772B817221886AC2920072EF244`; upload sertifikası CN=Satranc Platformu Upload.
- İmzalı test APK: `releases/satranc-platformu-0.8.7+20.apk`, 75.374.669 bayt, SHA-256 `CE4FC74926B61C7333D5BFB4C1621FFD1990D2DD5E3E6727D72F8EFE82E21E9E`; Android apksigner v2 doğrulaması başarılı.
- Firebase yapılandırma kontrolü, `google-services.json` içindeki paket kimliğiyle boşluklardan etkilenmeyecek şekilde düzeltildi. KGP/SDK XML uyarıları derlemeyi durdurmadı; gelecek Flutter/AGP yükseltmesinde ele alınacak.
- Yeni `notificationTokens/{uid}` sahiplik kuralları `satranc-platformu` projesine derlenip yayınlandı; kayıt: [firebase-087-rules-deploy.log](../releases/firebase-087-rules-deploy.log).
- Bildir/engelle güvenlik adapterı ve append-only moderasyon kuyruğu sözleşmesi eklendi. `blockedPlayers` belgeleri sahiplerine özel, `safetyReports` oyunculara kapalıdır; aynı Firebase rules deploy kaydında derleme ve yayın doğrulandı.


## Güncel doğrulama özeti — 0.8.7+20 — 16 Ekim 2026

- `flutter test --reporter expanded`: **165/165 geçti**; `dart analyze lib`: temiz.
- İmzalı AAB üretimi ve imzalı APK üretimi başarılı; Firebase paket kimliği `com.zpgames.satrancplatformu` ile eşleşiyor.
- AAB SHA-256 `54C322385F6FF7C16DD69FE736CCB43843ADE772B817221886AC2920072EF244`; APK SHA-256 `CE4FC74926B61C7333D5BFB4C1621FFD1990D2DD5E3E6727D72F8EFE82E21E9E`.
- Fiziksel cihaz `5c76ad26` ADB'de bağlı; bu turda kurulum yapılmadı. Emülatör başlatılmadı.
- Ayrıntılı 0.8.7 kaydı aşağıdaki bölümde; eski sürüm kayıtları tarihçe olarak korunur.




