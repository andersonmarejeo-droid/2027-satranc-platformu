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

## Güncel 0.8.0+13

Spark korunarak e-posta/şifre sağlayıcısı etkinleştirildi. Kalıcı hesap isteğe bağlıdır; misafir UID korunur. Özel profil/okul yedeği ve e-posta doğrulamasından sonra ayrı sıralama katılımı vardır. Misafirler puansız oynar; iki uygulamanın aynı sonuçta anlaştığı kalıcı hesap maçları 3/1/0 topluluk puanı verir. Bu puan Elo değildir; yetkili sunucu motoru veya resmi okul üyeliği doğrulaması yoktur.

Son kurallar ve üç sıralama indeksi gerçek projeye uygulandı. Davet/maç sisteminde 38, hesap/sonuç/puan/gizlilik sisteminde 47 canlı kontrol geçti. Test hesapları ve yalnız testlere ait belgeler temizlendi. Yeni özel koleksiyonlar playerAccounts, schoolSuggestions, onlineResults ve maç içi presence; açık katılımla okunan koleksiyon communityScores, tekrar önleyen kayıt scoreClaims. Hesap yedeği yüklenemezse yerel seçimler uzaktaki yedeğin üzerine yazılmaz. Sıralama temizliğinde önce katılım kapatılır; yarım kalan temizlik tekrar denenebilir.

Hosting gizlilik politikası hesap, e-posta, topluluk puanı, bağlantı yoklaması ve okul bildirimleri için güncellendi. Play Console bu turda değiştirilmedi. **0.8.0/13 konsola yüklenmedi:** yeni hesap/veri güvenliği ve hesap silme beyanları güncellenmeden mağazaya gönderilmez. Aşağıdaki Play durumu 4 Ekim 18:28 kontrolünün tarihsel kaydıdır. Güncel yerel paket/test teslimi store/release-status.json ve docs/VERIFICATION.md içindedir.

Fiziksel iki telefonla WhatsApp/App Links denemesi ve gerçek cihaz performansı bekler. Haftalık kupa puan sıralamasıdır; turnuva eleme ağacı değildir. Ayrıntılar [COMMUNITY_POINTS.md](COMMUNITY_POINTS.md).

## 0.7.1 kaynak güncellemesi

Ferah Turkuaz tema, siyah-beyaz tahta, kapalı varsayılan ipuçları, beraberlik, özel rövanş ve dört hazır maç sonu mesajı eklendi. Son Firebase kuralları gerçek projeye uygulandı; üç sıradan istemcide 38 kontrol geçti. Katılımcı kendi teklifini kabul edemez; üçüncü kişi özel rövanşa erişemez. Hazır mesajlar değişmez ve maç başına toplam 12 ile sınırlıdır. Verilerimi sil, alıcıya gönderilmiş bekleyen rövanşları da temizler. Gizlilik sayfası güncellendi. Kayıt releases/online-071-firebase-verification.log.

0.7.1 / 11 Android paketleri yerel teslim içindir; bu sürüm Play Console'a yüklenmedi. Aşağıdaki 0.7.0 / 10 dahili/Alpha bilgileri 4 Ekim 18:28 kontrolünün kaydıdır. Güncel paketler store/release-status.json ve docs/VERIFICATION.md içinde kaydedilir.

## Firebase — 0.7.0 tarihsel kayıt

Proje satranc-platformu (684650621962), Android App ID 1:684650621962:android:3f60f4c755b0722d5a43f3. Ücretsiz Spark planı; Blaze/faturalandırma açılmadı. Firestore Standard (default), Frankfurt europe-west3. Anonim Auth etkin. E-posta/şifre sağlayıcısı geleceğe hazır; mevcut uygulama e-posta/şifre istemez. Telefon/SMS, Analytics, Crashlytics ve Gemini yok.

Core, Authentication ve Firestore Android mağaza derlemesinde bağlı. 13+ ve veri açıklaması/onayı öncesinde misafir kimliği açılmaz; 6+ çevrim dışı oyun erişilebilir. Yerel profil/okul/şehir bilgisi sunucuya gönderilmez. Rastgele kimlik, davet, hamle ve saat verisi saklanır; serbest sohbet yok.

Kullanıcının açık onayıyla firebase/firestore.rules gerçek projeye uygulandı; derleme ve deployment başarılı. Diğer koleksiyonlar kapalı. Maçı yalnız iki katılımcı okuyabilir. Tek kullanımlı davet, sahiplik, sıra, değişmez geçmiş ve saat sınırları korunur. Tam satranç yasallığı her istemcide yeniden oynatılır; sunucuda rekabetçi hile önleme motoru olmadığı için maçlar sıralama puanı değiştirmez.

Üç bağımsız sıradan Firebase istemcisinde **18 canlı kontrol geçti**. Admin SDK veya emülatör kullanılmadı. Test belgeleri ve misafirleri temizlendi. Kayıt: releases/online-070-firebase-verification.log. Kontroller: eşzamanlı davette tek kazanan, katılımcı yetkisi, sıra, canlı dinleyici, iki istemcide hamle, değişmez geçmiş, sıralamaya yazmanın reddi, yeniden okuma, eşleşme kuyruğu, iptal ve verileri silme sorguları.

## Hosting ve App Links

- Web: https://satranc-platformu.web.app
- Gizlilik: https://satranc-platformu.web.app/privacy
- Silme talebi: https://satranc-platformu.web.app/privacy#delete-data
- Davet: https://satranc-platformu.web.app/challenge/<40-hex-kimlik>

Hosting yayımlandı. Android autoVerify manifesti ve /.well-known/assetlinks.json gerçek paket ile yükleme/Play sertifikalarını içerir. WhatsApp yalnız mesaj taslağı açar; alıcı ve gönderim kullanıcıdadır. Davet ekranında bağlantı yapıştırma alternatifi vardır. iOS Universal Links henüz kurulmadı.

## İmza ve derleme

Özel android/key.properties ve android/private/satranc-upload.p12 sürüm kontrolü dışında; anahtar/şifreler bu belgeye yazılmaz. Güvenli ayrı yedek gerekir.

Yükleme SHA-256: CF:73:38:E6:5A:79:AC:4A:E7:66:7D:0B:EC:85:0E:A8:35:63:96:27:BC:9E:F5:55:D5:A2:9A:EF:54:E9:96:6A.
Etkin Play SHA-256: 66:A7:D4:DB:60:BB:CC:D8:56:4F:DB:62:D0:38:38:47:43:E8:77:03:09:5D:41:4A:2E:8C:E6:33:1B:3D:F3:13.
Her ikisinin SHA-1/SHA-256 değerleri Firebase Android kaydında. Play anahtarı değiştirilmedi.

Proje Temurin Java 21 kullanır; sistem JAVA_HOME değiştirilmez. tool/build_play_bundle.ps1 gerçek upload imzası, kalıcı paket ve Firebase bayrağıyla AAB üretir ve çıktıyı denetler. 0.7.0+10 AAB: 61,9 MB; SHA-256 18AA70C3AD0F7679ED97A5B7C40C10B5DB32971B859E1043D74AA53679094AAA.

Varsayılan geliştirme paketi com.example.chess_platform yerel önizlemedir. Kalıcı mağaza paketi ayrı kurulumdur; eski yerel kayıtlar otomatik taşınmaz ve silinmez.

## Play Console

Uygulama ID 4973778407235444120, geliştirici ID 6350089341647884242. Türkçe, ücretsiz, Masa oyunu. Gizlilik, uygulama erişimi, reklam yok, sağlık/finans/devlet beyanları, 6+ yaş grupları ve mağaza grafikleri kaydedildi. IARC şartları açık kullanıcı onayıyla kabul edilip anket tamamlandı: PEGI 3 / Everyone / USK tüm yaşlar.

0.7 Veri Güvenliği formu kaydedildi: isteğe bağlı kullanıcı kimlikleri, oyun işlemleri ve güvenlikte kullanılan bağlantı kimlikleri; şifreli aktarım ve silme talebi URL'si. Firebase hizmet sağlayıcısı ve kullanıcı başlatımlı paylaşım muafiyetleri dikkate alındı. Reklam/analitik yok. Misafir erişimi kullanıcıya hesap/şifre oluşturma sunmaz.

0.7.0 / sürüm kodu 10 Play kitaplığına yüklendi. Dahili test 4 Ekim 2026 tarihinde kullanıma sunuldu; konsol "Dahili test kullanıcıları tarafından kullanılabilir" ve Etkin gösterdi. Yalnız geliştirici hesabının olduğu 1 kişilik liste seçili. Katılım: https://play.google.com/apps/internaltest/4700086157986741018.

Kapalı Alpha testine aynı paket eklendi. Türkiye kapsamı, mevcut "12" adlı 16 kişilik liste ve destek adresi kaydedildi. 15 değişiklik Google incelemesine gönderildi; konsol "İncelenmekte olan değişiklikler" ve "Değişiklikleriniz şu anda inceleniyor" gösterdi. Onay henüz alınmadı; yönetilen yayınlama kapalı olduğundan onaydan sonra kapalı test kullanıma sunulacak. Liste üyeliği gerçek test katılımı veya tamamlanmış süre demek değildir; kimseye mesaj gönderilmedi.

Yayın özetinin kontrolü eksik reklam kimliği beyanını gösterdi. Birleştirilmiş Android manifestlerinde AD_ID izni ve uygulama bağımlılıklarında reklam SDK'sı olmadığı doğrulandı; "Reklam kimliği kullanıyor mu? Hayır" kaydedildi. Engelleyici sorun kaldırıldı ve "15 değişikliği incelemeye gönder" düğmesi etkinleşti. Google otomatik kontrolleri tamamlandı. İncelemeye gönderme ve onay penceresindeki son gönderim uygulandı; gönderim alındı ve inceleme başladı.

Son mağaza/test durumu store/release-status.json içinde tutulur. Kaydetmek Google incelemesinin tamamlandığı veya herkese yayın anlamına gelmez. Üretim erişimi bu hesapta en az 12 gerçek kapalı test katılımcısının 14 gün kesintisiz katılımından sonra başvuru gerektirir; katılımcılar ve süre taklit edilmez.

## 0.7.0 dönemindeki sınırlar

İki fiziksel telefonda WhatsApp → App Link → hamle testi henüz yapılmadı; son USB kontrolde bağlı telefon yok. 18 canlı kontrol Firebase istemcileriyle yapıldı, telefon testi değildir. App Check zorunlu kılınmadı. Spark kotası aşılırsa hizmet kısıtlanabilir; ücretli plan otomatik açılmadı. Canlı okul/sınıf/grup puanları, kimlik kurtarma ve rekabetçi sunucu sonraki işlerdir.

[Firebase veri açıklaması](https://firebase.google.com/docs/android/play-data-disclosure) · [Play Veri Güvenliği](https://support.google.com/googleplay/android-developer/answer/10787469) · [12 katılımcı / 14 gün](https://support.google.com/googleplay/android-developer/answer/14151465).

## Masaüstü teslimi — 4 Ekim 2026

Son imzalı sürüm masaüstüne Satranc-Platformu-0.7.0.apk ve Satranc-Platformu-0.7.0.aab adlarıyla kopyalandı; iki dosyanın SHA-256 değerleri doğrulanan proje çıktılarıyla birebir eşleşti. Yeni kaynak değişikliği olmadığı için aynı başarılı derleme kullanıldı. Son fiziksel cihaz kontrolünde telefon bağlı değildi; emülatör başlatılmadı.

