# Satranç Platformu — Dünya Standardı 10 Adımlı Gelişim Sprinti

Tarih: 16 Ekim 2026  
Kapsam: mevcut Flutter feature-first yapısını koruyarak çevrim içi satranç, Firebase ve Google Play yayın kalitesini yükseltmek.  
Durum: **Onaylandı ve uygulanıyor.** İlk kalite/gözlemlenebilirlik dalgası tamamlandı; dış sistemlerde geri dönüşü zor adımlar kanıt kapısında tutuluyor.

## 1. Mevcut durum ve doğrulanmış güçlü taraflar

- Flutter projesi feature-first yapı, repository sözleşmeleri ve `go_router` kullanıyor. Firebase adaptörü ile yerel/REST adaptörleri ayrılmış durumda.
- Çevrim içi davet, WhatsApp HTTPS bağlantısı, Android App Links, süre, 180 saniye hamlesizlik, beraberlik teklifi, rövanş ve kısa maç sonu mesajları için istemci ve Firestore kuralları mevcut.
- Sınıf ve grup üyeliklerinde 20 kişi sınırı Firestore transaction kurallarıyla korunuyor.
- Firestore kuralları, indeksleri ve Hosting dağıtımı daha önce başarılı olarak kaydedilmiş; Spark planı kullanılıyor.
- 25 Dart test dosyası ve 1 integration test dosyası var. Geçmiş doğrulama kayıtlarında 165 teste kadar temiz sonuç bulunuyor.
- Açık/koyu tema, ferah renk paleti, farklı tahta/taş görünümleri, 3B varlıklar, azaltılmış hareket ve temel erişilebilirlik tercihleri bulunuyor.

## 2. Tespit edilen eksikler

### P0 — Yayına ve rekabetçi oyuna doğrudan engel olanlar

1. **Sunucu tarafı satranç otoritesi yok.** Firestore, hamleyi UCI biçiminde ve sıra/saat geçmişiyle doğruluyor; hamlenin gerçekten yasal bir satranç hamlesi olduğunu tam olarak doğrulayan güvenilir sunucu motoru yok. Değiştirilmiş istemci teorik olarak sahte yasal hamle yazabilir.
2. **Firebase App Check kapalı.** Firebase durum kaydında `appCheckEnforced: false`. Bu nedenle Firestore ve Auth istekleri uygulamanın gerçek mağaza binary’sinden geliyor mu kontrol edilmiyor.
3. **Play Integrity yok.** Maç hamlesi, puan ve davet işlemlerinde mağazadan kurulmuş değiştirilmemiş uygulama/cihaz sinyali kullanılmıyor.
4. **Gözlemlenebilirlik kapalı.** Analytics ve Crashlytics kapalı; ANR, çökme, kritik akış hatası, ağ gecikmesi ve sürüm bazlı hata oranı için canlı ölçüm/uyarı yok.
5. **Play Console yayına hazırlık kanıtı eksik.** Canlı Alpha kanalı 19 / 0.8.6 olarak etkin ve bir ülke/bölgeye açık. Kapalı test listelerinde 17, 2 ve 20 kişilik listeler var; ancak 12 gerçek test kullanıcısının kesintisiz 14 günlük katılımı, üretim erişimi başvurusu ve lansman öncesi rapor başarı durumu bu incelemede tamamlanmış görünmüyor.

### P1 — Ürün kalitesi ve işletim eksikleri

6. **Eşleşme ve yeniden bağlanma dayanıklılığı sınırlı.** Firestore snapshot ve 20 saniyelik presence yenilemesi var; uygulama arka plana geçişi, ağ değişimi, tekrar bağlanma, aynı hamlenin iki kez gönderilmesi ve eski olayların sıralanması için üretim düzeyi senaryo matrisi eksik.
7. **Bildirim katmanı yok.** WhatsApp paylaşımı var; ancak davet kabulü, rakip bulundu, hamle sırası, rövanş ve maç sonucu için FCM bildirimi/izin akışı yok.
8. **Sıralama ve topluluk verisi hâlâ sınırlı.** Bazı ekranlar demo sıralama kaynağına düşebiliyor; puan sistemi iki istemci onayına dayanıyor, yetkili Elo ve sunucu tarafı anti-cheat yok. Okul/kurs/grup üyeliği kullanıcı beyanı; okul katalog kaynak izinleri hâlâ incelenmemiş.
9. **Güvenlik ve çocuk güvenliği işletimi eksik.** Raporla/engelle, kötüye kullanım oran sınırlaması, moderasyon kuyruğu, denetim kaydı ve yaşa göre iletişim politikası uçtan uca bağlı değil. Hesap silme akışı var; gerçek doğrulama e-postası teslimi ve geri dönüş süresi henüz gerçek posta kutusunda doğrulanmadı.
10. **Kalite kapısı ve çoklu cihaz kanıtı eksik.** CI üzerinde otomatik `analyze`, unit/widget/integration test, coverage eşiği, release imza kontrolü, düşük seviye Android cihaz profili, dönüş/yeniden bağlanma ve gerçek iki telefon WhatsApp/App Links testi tek bir zorunlu yayın kapısında birleşmiyor. iOS Universal Links/iOS Firebase kurulumu da doğrulanmadı.

## 3. Onay sonrası uygulanacak 10 adımlı sprint

Her adımın sonunda kod, test, Firebase/Play değişikliği ve kanıt dosyası birlikte teslim edilecek. Bir adımın güvenlik veya veri sözleşmesi değişikliği varsa sonraki adıma geçmeden önce test kapısı çalıştırılacak.

### Sprint 1 — Ürün sözleşmesi ve release temeli

**Amaç:** Tek kaynaklı sürüm, ortam ve sözleşme yapısı kurmak.

- `dev`, `staging`, `production` ayrımını ve Firebase proje kimliği kontrolünü netleştir.
- Sürüm kodu, AAB/APK üretimi, upload imzası, changelog ve checksum manifestini tek komuta bağla.
- Gizli anahtarların kaynak ağacına girmediğini kontrol et; Play upload anahtarının güvenli yedeğini ve erişim listesini belgelemeyi zorunlu kıl.
- CI kalite kapısını ekle: format, analyze, test, integration test derleme, release imza ve paket adı doğrulaması.

**Kabul ölçütü:** Aynı commit’ten tekrarlanabilir AAB çıkar; test veya imza kontrolü başarısızsa yayın paketi oluşmaz.

### Sprint 2 — Kimlik, hesap ve yaş/izin akışı

**Amaç:** Misafirden kalıcı hesaba geçişi ve veri/yaş izinlerini standartlaştırmak.

- Misafir UID’sini koruyan hesap bağlama akışını; kayıt, giriş, doğrulama, parola yenileme ve hesap silmeyi tek durum makinesine taşı.
- Yaş seçimi, çevrim içi onay, sıralama katılımı ve okul/grup görünürlüğünü ayrı, denetlenebilir izinler olarak sakla.
- E-posta teslimi için gerçek posta kutusu test senaryosu, yeniden gönderme bekleme süresi ve kullanıcıya açık hata durumu ekle.
- Parola politikasını ürün kararı olarak sabitle; mevcut 12 karakter zorunluluğu ile kullanıcıların daha kısa parola beklentisini aynı belgede açıkla.

**Kabul ölçütü:** Hesap bağlama, e-posta doğrulama, silme ve geri yükleme gerçek Android cihazda tekrarlanabilir; silinen hesabın Firebase belgeleri ve takım yerleri temizlenir.

### Sprint 3 — Firebase şema ve güvenlik kuralları v2

**Amaç:** Firestore kurallarını üretim sözleşmesi olarak test edilebilir hale getirmek.

- Koleksiyon/alan şemalarını ve veri saklama sürelerini tek bir sözleşmede tanımla.
- Kurallar için Firebase Rules Unit Testing veya izole emülatör CI senaryoları ekle; mevcut canlı kontrolleri de koru.
- Sorgu kısıtlarını, indeksleri, alan değişmezliğini, silme ve idempotency davranışını test et.
- App Check geçişi için önce ölçüm, sonra enforcement planı hazırla; eski sürümlerin kontrollü geri dönüşünü belgelemeyi unutma.

**Kabul ölçütü:** Yetkisiz okuma/yazma, üçüncü oyuncu erişimi, tekrar hamle, takım kapasitesi aşımı ve veri silme ihlalleri otomatik testte reddedilir.

### Sprint 4 — Sunucu otoriteli satranç ve maç sonucu

**Amaç:** Rekabetçi çevrim içi maçta hamle, saat ve sonuç kaynağını güvenilir sunucuya taşımak.

- Cloud Functions 2nd gen veya Cloud Run üzerinde küçük bir maç otoritesi kur; Firebase Auth tokenını ve App Check/Integrity sinyallerini doğrula.
- FEN/UCI geçmişini sunucuda yeniden oynatıp yasal hamle, şah güvenliği, terfi, rok, geçerken alma, mat/pat ve üç tekrar durumunu doğrula.
- Saat hesabını sunucu zamanına bağla; gecikme toleransı, tek kullanımlı idempotency anahtarı ve tekrar deneme davranışı ekle.
- Firestore’u istemcinin doğrudan sonuç yazdığı yer olmaktan çıkar; maç özeti ve puan mutabakatını yetkili işlemler yazsın.

**Kabul ölçütü:** Değiştirilmiş istemciden gelen yasadışı hamle, sahte sonuç ve çift puan yazımı reddedilir; iki gerçek telefon aynı maçta aynı sonuca ulaşır.

### Sprint 5 — App Check, Play Integrity ve kötüye kullanım sınırları

**Amaç:** Gerçek uygulama dışı istekleri ve otomatik kötüye kullanımı azaltmak.

- Flutter `firebase_app_check` ekle; Android’de Play Integrity provider ile debug/staging ayrımı kur.
- Firebase App Check metriklerini gözlemledikten sonra Auth/Firestore için kademeli enforcement uygula.
- Yüksek değerli işlemler için Play Integrity standard request ve sunucu doğrulaması ekle; request hash ile hamle/puan isteğini bağla.
- Davet, eşleşme, hamle, puan ve hesap kurtarma için kullanıcı/IP/cihaz bazlı oran sınırları ve güvenli hata yanıtları ekle.

**Kabul ölçütü:** Yetkisiz binary ve aşırı istekler sınırlanır; gerçek Play kurulumu normal kullanıcı akışını bozmaz; debug build açıkça ayrı provider kullanır.

### Sprint 6 — Eşleşme, yeniden bağlanma ve bildirimler

**Amaç:** Rakip bulma ve maç sürdürmeyi ağ koşullarından bağımsızlaştırmak.

- Eşleşme kuyruğuna atomik rezervasyon, iptal, süre aşımı, bot fallback etiketi ve tekrar bağlanma durumlarını ekle.
- WebSocket/Firestore olaylarında son sıra numarası, eksik olay yenileme ve tek kaynaktan snapshot birleştirme uygula.
- FCM ile davet kabulü, rakip bulundu, sıra sende, rövanş ve sonuç bildirimlerini bağla; bildirim iznini ilk ihtiyaç anında iste.
- WhatsApp bağlantısını Android App Links ile soğuk başlangıç, açık uygulama ve tarayıcı geri dönüşü senaryolarında doğrula.

**Kabul ölçütü:** Telefon uçak modundan döndüğünde maç tek kez ve doğru snapshot ile devam eder; üçüncü kişi daveti veya maç verisini göremez.

### Sprint 7 — Gerçek puan, okul/sınıf/grup ve turnuva doğruluğu

**Amaç:** Demo veriyi üretim verisinden ayırıp hiyerarşik sıralamayı güvenilir yapmak.

- Ülke → şehir → ilçe → okul → sınıf/grup kapsamlarını tek kimlik şemasıyla sunucu tarafında doğrula.
- Yetkili puan güncelleme, Elo/puan dönemleri, beraberlik, terk, hamlesizlik ve itiraz durumlarını tanımla.
- Sınıf/grup 20 kişi kuralını koru; okul ve sınıfın aynı isimli kayıtlarını benzersiz ID ile ayır.
- Okul katalog kaynağı, güncelleme tarihi, lisans/izin durumu ve kullanıcı önerisi akışını belgele; onaysız katalog verisini mağaza iddiası gibi sunma.

**Kabul ölçütü:** Seçilen okulun sınıfları ve seçilen grubun oyuncuları doğru filtrelenir; demo oyuncu gerçek sıralama gibi gösterilmez.

### Sprint 8 — Gizlilik, çocuk güvenliği ve moderasyon

**Amaç:** 177 ülkeye açılabilecek veri ve güvenlik operasyonunu kurmak.

- Veri envanterini Firebase SDK’ları, cihaz kimlikleri, maç/presence, e-posta ve okul verileriyle güncelle.
- Gizlilik politikası, Play Data Safety, hesap silme, veri saklama süreleri ve destek iletişimini aynı sürümden üret.
- Raporla/engelle, taciz önleme, hızlı mesaj sınırı, moderasyon olay kaydı ve itiraz akışı ekle.
- Çocuk/ergen kullanıcılar için yaşa uygun iletişim, reklam yok beyanı, veli/ülke gereksinimleri ve ülke bazlı hukuki inceleme kontrol listesi hazırla.

**Kabul ölçütü:** Kullanıcı hangi verinin neden saklandığını görür; silme talebi ve raporlanan kötüye kullanım için izlenebilir durum oluşur.

### Sprint 9 — İzleme, performans, erişilebilirlik ve görsel kalite

**Amaç:** Premium görsel hedefi ölçülebilir ürün kalitesine çevirmek.

- Crashlytics ve Performance Monitoring’i sürüm/cihaz/ülke kırılımıyla kur; fatal, non-fatal ve ANR için uyarı eşikleri belirle.
- İlk açılış, tahta çizim süresi, hamle gecikmesi, ağ yanıtı, bellek ve pil için hedefler belirle.
- Düşük seviye Android cihaz, farklı ekran oranı, yazı büyütme, ekran okuyucu, kontrast, azaltılmış hareket ve karanlık/açık tema testlerini ekle.
- 2B/3B tahta, siyah-beyaz tahta, çocuk teması ve tam ekran oyun ekranı için görsel altın testleri ve gerçek cihaz kareleri üret.

**Kabul ölçütü:** Kritik akışlarda çökme/ANR görünür; performans hedefleri ve erişilebilirlik kontrolleri raporlanır; görsel değişiklikler mevcut işlevleri bozmaz.

### Sprint 10 — Play Console üretim kapısı

**Amaç:** AAB’yi güvenli biçimde kapalı testten üretime hazırlamak.

- Güncel AAB’yi yeni sürüm koduyla Alpha/Kapalı teste yükle; mağaza açıklaması, ekran görüntüleri, ikon, gizlilik URL’si ve Data Safety formunu 0.8.6 sonrası gerçek SDK davranışıyla eşleştir.
- 12 gerçek test kullanıcısının kesintisiz 14 günlük katılımını Play Console kanıtıyla takip et; fixture hesaplarını gerçek testçi yerine kullanma.
- Lansman öncesi raporu, cihaz uyumluluğunu, Android vitals/Crashlytics durumunu ve uygulama erişimi inceleme hesabını tamamla.
- Play App Signing sertifikası ile Firebase Android SHA’larını, App Links `assetlinks.json` dosyasını ve üretim paket kimliğini tekrar doğrula.
- Üretim erişim başvurusundan önce geri dönüş planı, önceki AAB, release notes ve destek adresini hazırla.

**Kabul ölçütü:** Play Console’da sürüm, veri güvenliği, içerik, test, App Links ve inceleme erişimi için açık uyarı kalmaz; üretim başvurusu kullanıcı onayı olmadan gönderilmez.

## 4. Uygulama sırası ve onay noktası

1. Bu belge onaylanmadan kod, Firebase kuralı, App Check enforcement, Play yüklemesi veya mağaza formu değiştirilmez.
2. Onaydan sonra Sprint 1–3 güvenlik ve release temelini kurar.
3. Sprint 4–6 canlı maç otoritesi, kötüye kullanım koruması, eşleşme ve bildirimleri tamamlar.
4. Sprint 7–9 ürün verisi, çocuk güvenliği, izleme, performans ve görsel kaliteyi tamamlar.
5. Sprint 10 yalnızca tüm önceki kabul ölçütleri ve gerçek cihaz kanıtları tamamlandıktan sonra çalıştırılır.
6. Firebase rules/App Check enforcement, Play Console form gönderimi ve üretim erişim başvurusu ayrı dış sistem etkileridir; her biri uygulanmadan önce sonucu raporlanır.

## 5. Resmî standart dayanakları

- Flutter, UI/data ayrımı, repository, ViewModel, dependency injection, unidirectional data flow ve birim/widget/integration testlerini ölçeklenebilir uygulama için öneriyor: [Flutter app architecture](https://docs.flutter.dev/app-architecture/recommendations), [Flutter testing](https://docs.flutter.dev/testing/overview).
- Firebase, mobil istemcilerde Authentication + Firestore Rules + App Check kullanılmasını; App Check enforcement öncesi metrik izlenmesini öneriyor: [Firestore security](https://firebase.google.com/docs/firestore/security/overview), [Flutter App Check](https://firebase.google.com/docs/app-check/flutter/default-providers).
- Crashlytics, Flutter’da hata yakalama, ANR ve ilk test raporunun doğrulanmasını; Performance Monitoring ise açılış, ağ ve ekran performansının ölçülmesini sağlıyor: [Crashlytics Flutter](https://firebase.google.com/docs/crashlytics/flutter/get-started), [Performance Monitoring](https://firebase.google.com/docs/perf-mon).
- Play Integrity, yüksek değerli istekleri gerçek Play binary’si ve cihaz bütünlüğüyle ilişkilendirmek için sunucu doğrulaması ve request hash kullanımını öneriyor: [Play Integrity overview](https://developer.android.com/google/play/integrity/overview), [standard requests](https://developer.android.com/google/play/integrity/standard).
- Yeni kişisel Play geliştirici hesapları için kapalı testte en az 12 test kullanıcısının 14 gün kesintisiz katılımı üretim erişiminden önce gerekiyor: [Play testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465).
- Play Data Safety formu kapalı test ve üretim dahil yayınlanan uygulamalar için doğru ve SDK’larla uyumlu doldurulmalı: [Play Data Safety](https://support.google.com/googleplay/android-developer/answer/10787469).

## 6. Uygulama durumu

Plan kullanıcı tarafından onaylandı. Adımlar **Sprint 1’den başlayarak sırayla** uygulanıyor; her adım kalite kapısı ve kanıt dosyası ile işaretleniyor. Play Console’da üretim başvurusu ve Firebase App Check enforcement gibi dış sistemde geri dönüşü zor işlemler, gerekli gerçek cihaz ve canlı trafik kanıtı oluşmadan otomatik gönderilmiyor.

### Uygulanan ilk dalga

- Release sürümü `0.8.7+20` olarak ilerletildi.
- `tool/quality_gate.ps1` ile biçim, analyze, test ve imzalı AAB adımları tek kalite kapısına bağlandı; emulator başlatılmaz.
- Play build'i App Check ve Crashlytics/Performance toplamasını açık derleme tanımlarıyla üretir; server authority bayrağı varsayılan olarak kapalıdır.
- Firebase App Check, Crashlytics, Performance ve FCM sınırları Android girişinde kuruldu; başlangıçta bildirim izni sorulmaz.
- FCM token'ları özel `notificationTokens` belgelerine yazmak için istemci ve Firestore sahiplik kuralları eklendi.
- Sunucu otoriteli hamle sözleşmesi ve idempotency istemcisi eklendi; Spark planı nedeniyle endpoint dağıtımı ve enforcement için ayrı canlı sistem kapısı bırakıldı.
- Uygulama ve backend sözleşmesi için [SERVER_AUTHORITY.md](api/SERVER_AUTHORITY.md) eklendi.
- Firebase/Play snapshotı [store/release-status-0.8.7.json](../store/release-status-0.8.7.json) olarak kaydedildi; Play Console'daki etkin Alpha hattı ve üretim başvurusu bu sprintte değiştirilmedi.
- Güvenlik sprintinin ilk işletim parçası olarak sahip özel engelleme, append-only rapor ve moderasyon kuyruğu veri sözleşmesi eklendi ve Firestore'a yayınlandı.
