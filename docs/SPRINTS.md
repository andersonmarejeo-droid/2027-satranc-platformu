## Güncel tamamlanan sprint — 0.8.0+13

- Kompakt Benim okulum kartı, doğrudan şehir/okul/sınıf düzenleme ve özel eksik okul bildirimi.
- Hatırlanan oyun türü/süre/zorlukla ana sayfadan Oyna; yerel taslak korunur, hızlı eşleşme otomatik tahtayı açar.
- Kalıcı isteğe bağlı hesap, e-posta doğrulama/kurtarma, profil/okul geri yükleme ve ayrı sıralama katılımı.
- İki istemci sonuç mutabakatı, tekrarsız 3/1/0 puan; haftalık/aylık/tüm zamanlar ve sınıf/okul/şehir/ülke/ayrı grup filtreleri, gerçek kişisel sıra.
- Bağlantı göstergesi/yeniden deneme, 5 dakikalık eşleşme bekleme sınırı, maç sonrası temel olay incelemesi, hareket azaltma ve hafif 2D tahta.
- 38 maç/davet ve 47 hesap/puan/yetki canlı Firebase kontrolü geçti. Son uygulama testleri, önizlemeler ve imzalı paketler VERIFICATION.md / store/release-status.json ile kaydedilir. Emülatör açılmaz.

Kalan dış doğrulamalar: fiziksel iki telefonla davet/App Links ve performans; 0.8 veri güvenliği/hesap silme Play beyanları ve paket yüklemesi; gerçek kapalı test katılım süresi. Resmi rekabetçi puan, doğrulanmış okul üyeliği ve otomatik turnuva ağacı ayrı geliştirmelerdir. MEB veri yeniden kullanım izni değerlendirmesi kullanıcı isteğiyle ertelendi. iOS kayıt ve derlemesi doğrulanmadı.

## Önceki tamamlanan sprint — 0.7.0+10

Firebase Spark, Android kalıcı paket/imza, Hosting gizlilik/davet sayfası, App Links sertifikaları ve Play mağaza başlangıç ayarları kuruldu. 13+ misafirlerle gerçek arkadaş maçı, WhatsApp daveti, rakip arama, maça dönüş ve veri silme eklendi. 18 canlı Firebase kontrolü, 117 tam Flutter testi ve son ilgili 17 test geçti. Gerçek okul/grup sıralamaları demo kalır; arkadaş maçları puan değiştirmez. Son teslim/mağaza durumu store/release-status.json içinde.

Kalan sprintler:
1. Fiziksel Android doğrulaması: yeni kalıcı paketi telefona kurma; iki cihazda WhatsApp/App Links, bağlantı kaybı, saat, ses ve akıcı taş hareketleri. Son USB kontrolde telefon bağlı değil; emülatör açılmaz.
2. Kapalı test: gerçek katılımcıları ekleme, en az 12 kişinin 14 gün katılımı ve geri bildirim; ardından üretim başvurusu. Üretim erişimi şimdilik konsolda kapalı.
3. Sağlam çevrim içi akış: kuyruk süresi dolmasını ekranda otomatik sonlandırma, kotaya uygun okuma optimizasyonu, geçmiş sayfalama ve App Check entegrasyonu.
4. Rekabetçi oyun: yetkili sunucu satranç motoru, hile/puan denetimi, teslimiyet ve beraberlik anlaşması; ücretsiz plan sınırları korunarak kapsam kararı.
5. Topluluk: gerçek okul/şehir kataloğu, güvenli okul/sınıf ve grup üyelikleri, yetkili canlı puanlar. Küçükler için veli/öğretmen akışı olmadan çevrim içi yaş sınırı genişletilmez.
6. Hesap kurtarma ve iOS: gerçek kullanıcı hesabı/kurtarma, Apple kayıtları ve Universal Links; Windows'ta iOS build iddiası yok.

Aşağıdaki eski sprint kayıtları tarihçedir. Ayrıntılı güncel Firebase/Play durumu PLAY_FIREBASE_SETUP.md içindedir.

# Satranç Platformu — kalan işler için sprint planı

Bu plan, mevcut yerel başlangıç sürümünden gerçek çevrim içi ürüne giden yolu sıralar. Her sprint, ön koşulu hazır olduğunda uygulama ve dokümantasyonla tamamlanır. Gerçek hizmet uç noktası veya hesap gerektiren işler canlıymış gibi taklit edilmez. Android emülatörü bu çalışma sırasında başlatılmaz.

## Play Console ve Firebase — 4 Ekim 2026

- Doğrulandı: ZP GAMES Play Console ve Firebase hesaplarına erişim; Satranç Platformu için henüz kayıt/proje bulunmaması; önerilen kalıcı `com.zpgames.satrancplatformu` paketinin kullanılabilir olması.
- Hazırlandı: Türkçe, ücretsiz oyun kayıt formu; Firebase `satranc-platformu` proje formu, Analytics ve Gemini kapalı. Formların gönderimi yapılmadı.
- Hazırlandı: açık mağaza derlemesinde kalıcı paket ve yükleme imzasını zorunlu tutan Android ayarı; anahtar hazırlama, AAB derleme ve salt okunur durum kontrolü betikleri. Gerçek yükleme anahtarı/AAB henüz oluşturulmadı.
- Düzeltildi: eski Java klasörü yerine proje içinde SHA-256 doğrulanan Temurin Java 21; sistem ayarları değiştirilmeden hazırlık betiklerine bağlandı.
- Bekliyor: yeni Firebase/Play kayıtlarını oluşturmak için kullanıcı yetkisi; otomatik onay incelemesi Firebase projesi oluşturmayı bu yetki eksikliği nedeniyle reddetti. Play hukuk beyanları ve hedef yaş kullanıcıya soruldu.
- Ayrıntılı durum ve kalan işlemler [PLAY_FIREBASE_SETUP.md](PLAY_FIREBASE_SETUP.md) içinde. Firebase bağlantısı, imzalı mağaza paketi ve mağaza inceleme/yayın işlemleri tamamlanmış değildir.

## Tam ekran, taş sesi ve görünür rakip hamlesi — sürüm 0.6.1

- Uygulandı: oyun üst çubuğunda Tam ekran, Android sistem çubuklarını gizleme/geri açma, daha geniş tahta ve yatay yerleşim; ilk geri tuşunda oyundan ayrılmadan normal görünüme dönüş.
- Uygulandı: özgün düşük düzeyli sürükleme/yerleştirme sesi; Android SoundPool, yasal hamlede ses, maç içinde kapatma/açma.
- Uygulandı: 2D/üstten/3D kaymayı 380 ms gösterme; bilgisayarın 650 ms'den önce yanıtı uygulamaması ve iptal/geri alma korumaları.
- Doğrulandı: 116 farklı kontrol (son tam koşuda 113 geçiş; kalan test beklentileri düzeltildikten sonra ilgili 11 kontrol tekrar geçti), temiz kaynak analizi ve 0.6.1+8 ARM64 Android derlemesi. Yeni APK `releases/satranc-platformu-0.6.1-arm64.apk` dosyasında hazır.
- Doğrulandı: 0.6.1+8 güncellemesi fiziksel RMX3890 telefona mevcut kayıtları koruyarak yüklendi (Success); paket sürümü doğrulandı ve uygulama başarıyla açıldı. Fiziksel tam ekran, ses ve akıcılık için ayrıntılı dokunma/işitme kontrolü bekliyor. Emülatör açılmadı.
- Kaynaklar ve platform sınırları [GAME_PRESENTATION.md](GAME_PRESENTATION.md) içinde. Son doğrulama ve telefon sonucu [VERIFICATION.md](VERIFICATION.md) içinde kaydedilir.

## Marka, açılış, geri tuşu ve basit süreler — sürüm 0.6.0

- Uygulandı: Satranç Platformu adı; sakin taş yağmuru ve ZP GAMES açılışı, hareket azaltma desteği ve Android yerel açılış zemini.
- Uygulandı: açık pencereden başlayarak bir üst menüye geri dönüş, okul/sınıf basamakları ve yerel oyunun korunması; Ana Sayfa'da çıkış engellenir.
- Uygulandı: Süresiz → 1/2/3/5 dakika; uzun ve hamle sonrası ek süreli seçenekler Diğer süreler altında. 90 dakikalık kayıt saklama/parsing desteği.
- Üretildi: üç özgün simge. Kullanıcı seçimi ve launcher uygulaması bekliyor. [Görseller ve istemler](BRANDING.md).
- Doğrulandı: 107/107 kontrol, son açılış düzeltmesinden sonra ilgili 23 kontrol ve temiz analiz. 0.6.0+7 Android paketi fiziksel RMX3890 telefona mevcut kayıtları koruyarak yüklendi ve açıldı. Fiziksel geri tuşu/FPS ölçümü yapılmadı.
- Doğrulama ve yeni APK sonucu [VERIFICATION.md](VERIFICATION.md) içinde kaydedilir.

## Hamle ipuçları, okul/sınıf liderliği ve kartlar — sürüm 0.5.0

- Uygulandı: tahta altında kalıcı olası hamleleri göster/gizle seçeneği; bütün tahta görünümlerinde yasal oynama ve taş alma korunur.
- Uygulandı: saat/pozisyon/son hamleyi tek bildirimde güncelleme, bilgisayarı seçim ara karesi olmadan oynatma, 2D solma geçişini kaldırma ve 3D hızlı yanıt animasyonunu önceki hareketin sonuna bırakma.
- Uygulandı: Okullar → seçili okul → Sınıfların sıralaması → sınıftaki oyuncular. Kimlik eşleştirmesiyle kişisel sıra özeti ve satırı bulma hazır; gerçek kimlik/puan kaynağı bağlanana kadar demo misafire sıra uydurulmaz.
- Uygulandı: sıcak yüzey geçişleri, sakin gölgeler, tonlu simgeler ve kompakt sıra rozetleri.
- Doğrulandı: 86/86 kontrol, temiz analiz ve 0.5.0+6 ARM64 derlemesi. Fiziksel RMX3890 telefona güncelleme yüklendi, paket sürümü doğrulandı ve uygulama açıldı. Ayrıntılı fiziksel dokunma/FPS ölçümü yapılmadı.
- Doğrulama ve telefon paketinin sonucu [VERIFICATION.md](VERIFICATION.md) içinde kaydedilir.

## Bilgisayar rakibi — sürüm 0.4.0

- Uygulandı: Sen ve Bilgisayar girişi; Kolay, Orta, Zor ve Usta seçimi; farklı arama derinlikleri ve sınırlı hesap bütçeleri.
- Uygulandı: seviyenin oyun/taslak/geçmişte korunması; eski kayıtların Orta'ya geçmesi. Bilgisayarlı oyunda renk yerine oyuncu adlarıyla sıra, şah ve sonuç anlatımı.
- Uygulandı: daha küçük eylem kartları, oyuncu simgeleri ve tahta çevresindeki aralar; büyük yazıda üst bilgi satırının sarılması.
- Motorun gücü ve sınırları [COMPUTER_OPPONENT.md](COMPUTER_OPPONENT.md) içinde açıklanır.
- Doğrulandı: 76 kontrol ve temiz analiz; 0.4.0+5 paketi fiziksel telefona yüklendi. Kilit ekranı nedeniyle fiziksel dokunma kontrolü bekliyor; emülatör kullanılmadı.

## Kompakt arayüz — sürüm 0.3.1

- Uygulandı: ortak kart, sayfa, başlık ve alt menü ölçülerinin küçülmesi; okunaklı yazı ve dokunma alanları.
- Uygulandı: tek dokunuşlu kısa oyun seçenekleri; daha kısa ana sayfa görseli ve keşif kartları; kompakt profil, sosyal davet ve liderlik topluluk listeleri.
- Uygulandı: daha küçük tahta malzeme örnekleri; seçilen malzemenin açıklaması korunur.
- Doğrulama ve telefon paketinin sonucu [VERIFICATION.md](VERIFICATION.md) içinde kaydedilir.
- Doğrulandı: 71/71 test ve temiz analiz; 0.3.1+4 Android paketi bağlı fiziksel telefona güncellendi. Kilit ekranı nedeniyle fiziksel dokunma kontrolü bekliyor; emülatör kullanılmadı.

## Kullanıcı akışı — sürüm 0.3.0

- Uygulandı: tek dokunuşla bilgisayara karşı veya aynı telefonda iki kişilik oyun. Yerel oyun varsayılan olarak süresiz; saat seçenekleri toplam dakika ve hamle sonrası ek saniye şeklinde açıklanır.
- Uygulandı: başlangıç düzeyi çevrim dışı bilgisayar rakibi; geciken hamlenin geri alma/duraklatma/çıkıştan sonra uygulanmasını engelleme; rakip türünü saklayan taslak ve maç geçmişi.
- Uygulandı: ülke → şehir → okul → sınıf seçimlerinin cihazda saklanması ve bağımsız çoklu grup seçimi. Okul/sınıf seçimi isteğe bağlıdır. Üst basamak değişince alt basamaklar temizlenir.
- Uygulandı: şehir, okul ve grup örnek sıralamaları; seçilen toplulukta oyuncular. Sınıflar okulun altındadır; ülke çapında ortak 9-A kimliği yoktur.
- Uygulandı: iki özgün CC0 doku, altı ayrıntılı mobil taş geometrisi, tüm eski görünümlerin korunması. Kaynak ve lisans bilgileri ASSET_CREDITS.md içindedir.
- Bekliyor: gerçek hesap kaydı, tüm şehir/okul kataloğu, üyelik/okul doğrulaması, canlı puanlar ve oyun sunucusu.

## Görsel sprint — 2D, gerçekçi ve çocuk koleksiyonu

**Durum: uygulandı; fiziksel cihaz doğrulaması bekliyor.**

- Sade 2D, üstten gerçekçi ve gerçek hacimli taş geometrisiyle 3D masa; üç kamera açısı.
- Ceviz, meşe, Carrara mermer ve antrasit/pirinç malzemeleri; gerçekçi dokular projede saklanır.
- Çocuklar için Neşeli Bahçe, Şeker Bahçesi, Deniz Macerası ve Masal Masası; altı bağımsız taş seti.
- Profil'de görünüm seçimi, oyun/inceleme/çevrim içi tahta üzerinde palet düğmesi ve cihazda kalıcı tercihler.
- Oyun geçmişi ve saat korunarak görünüm değiştirme; 3D kare/taş dokunması ve ekran okuyucu bilgisi.
- Önizlemeler ve kaynak/istem kaydı: [BOARD_APPEARANCE.md](BOARD_APPEARANCE.md).
- Bekliyor: Android cihazda performans, dokunma ve SharedPreferences doğrulaması. Emülatör kullanılmaz.

## Sprint 1 — Çevrim içi omurga

**Durum: tamamlandı.**

- Ortak API istemcisi: platforma uygun taşıma, JSON, hata eşlemesi, zaman aşımı, isteğe bağlı Bearer oturumu.
- Sürüm kontrollü OpenAPI sözleşmesi: oturum, davet, eşleşme kuyruğu, maç hamleleri ve sıralama.
- API adresi ortam ayarını uygulama servislerine bağla; adres yoksa mevcut demo akışı aynen çalışsın.
- `API_BASE_URL` yapılandırılmışsa istemci oluşturulur; boşsa demo akışı korunur. HTTP yalnızca debug modunda loopback veya Android emülatör yerel ağ geçidi için kabul edilir; diğer adreslerde HTTPS zorunludur.
- `dart analyze lib/core/networking` Sprint 1'de temiz geçti. Tam uygulama analizi Sprint 2/3/4 sonunda temiz geçti.
- Android ARM64 release APK ve Flutter Web release kaynak kodla yeniden derlendi. Android derlemesi emülatör başlatmadı.
- Android ve web için aynı Dart API arayüzü ve ayrı HTTP taşıyıcıları hazır; canlı sunucuya bağlantı veya çevrim içi maç iddiası yok.

## Sprint 2 — Hesap, profil ve güvenlik

**Durum: yerel temel ve sağlayıcıdan bağımsız API oturum adaptörü tamamlandı; gerçek kimlik sağlayıcısı ve kullanıcı korumaları bekliyor.**

- Tamamlandı: cihazda kalıcı misafir profili, görünen ad düzenleme/doğrulama ve güvenli varsayılanlarla yerel gizlilik tercihleri.
- Tamamlandı: `AuthIdentityProvider` sözleşmesi; JWT akışını `/v1/auth/session` oyuncu kimliğine eşleyen API repository'si ve sağlayıcı/sunucu çıkış devri.
- Bekliyor: gerçek kimlik SDK'sı, hesap açma/giriş arayüzü ve bu sağlayıcının ana uygulamaya bağlanması.
- Bekliyor: yaş/veli izinleri, kullanıcı engelleme ve bildirme akışları.
- Ön koşul: hedef hesap sağlayıcısı ve yayıma uygun çocuk/veli politikaları.

## Sprint 3 — Gerçek davet ve bağlantılar

**Durum: istemci adaptörü hazır; canlı bağlantılar dış hizmet kurulumunu bekliyor.**

- Tamamlandı: API sözleşmesine bağlı davet repository adaptörü; kimlik, dakika tabanlı süre ve HTTPS paylaşım bağlantısı doğrulaması.
- Tamamlandı: API adresi ve oturum belirteci sağlayıcısı birlikte verilince adaptöre geçiş; diğer kurulumlarda yerel deneme akışı korunur.
- Tamamlandı: WhatsApp taslağı sunucunun verdiği HTTPS bağlantısını kullanır; 404 ve süresi dolmuş/kullanılmış davet yanıtları ayrıştırılır.
- Bekliyor: gerçek sunucu, kimlik sağlayıcısı, sahip olunan alan adı ve alan adı doğrulamalı bağlantı dosyaları.

- Bekliyor: sunucuda davet kabulü ve tek seferlik kullanım işlemi.
- Bekliyor: sahip olunan alan adında HTTPS davet sayfası; uygulama kurulu değilse web yedek akışı.
- Bekliyor: Android App Links ve iOS Universal Links alan adı doğrulaması.
- Ön koşul: sahip olunan alan adı, API/web barındırması, Android imza sertifikası ve Apple Team ID.

## Sprint 4 — Canlı maç ve eşleşme

**Durum: REST ve WebSocket maç istemcisi hazır; gerçek hizmet ve canlı doğrulama bekliyor.**

- Tamamlandı: kimlik sağlayıcısı ve API adresi verilince eşleştirme kuyruğuna girme, iki saniyelik durum sorgusu, iptal ve terminal durumları işleme.
- Tamamlandı: eşleşen maç sunucu FEN'iyle açılır; hamleler UCI ve beklenen ply ile, benzersiz `Idempotency-Key` başlığı kullanılarak sunucuya gider. Tahta yalnız sunucu yanıtı sonrasında güncellenir.
- Tamamlandı: maç görünümü durum, oyuncular, sunucu saat görüntüsü ve SAN geçmişini REST snapshot'ından gösterir; WebSocket olayları snapshot'ı yeniler, dört saniyelik REST yenilemesi yedek kalır.
- Tamamlandı: Android ve tarayıcı WebSocket taşıyıcıları eklendi. `match.sync` son olay numarasıyla gönderilir; yinelenen/eski olaylar atılır, yeniden bağlantıda yeni tek kullanımlık bilet alınır ve gecikme artarak yeniden denenir.
- Tamamlandı: Sprint 4 kaynaklarıyla Web ve ARM64 Android release derlendi; emülatör açılmadı.
- Tamamlandı: yerel tahta seçilen süreyi ve hamle artışını uygular; süre bitişini gösterir. Hamle geri alınınca saat durumu da geri alınır; saatsiz pratik seçeneği korunur.
- Tamamlandı: yerel oyunları elle kaydetme, aynı kaydı güncelleme ve son 100 oyunu cihazda saklama. Profil'den açılan maç geçmişi, hamleleri salt okunur tahtada ileri/geri inceleme ve PGN kopyalama sunar. Rok, geçerken alma, terfi, PGN yeniden okuma, bozuk kayıt, yazma hatası ve kayıt güncelleme kontrolleri eklendi. Bu kayıtlar canlı maç veya hesaplar arasında eşitleme değildir.
- Tamamlandı: son yerel tahtanın otomatik taslağı; Oyna ekranından tam hamle geçmişi, saat, geri alma ve yön ile devam etme. Arka plan ve tahtadan çıkış yerel oyunu duraklatır. Yeni tahtanın son taslağı değiştirmesi onaylanır. Kayıt işlemleri sırayla yürütülür; bozuk kayıt ve disk yazma hataları gösterilir. Yeniden başlatma, tekrar kuralı ve yeniden açılan oyunda saatli geri alma testleri eklendi. Gerçek Android yaşam döngüsü ve depolama kontrolü cihaz testini bekler.
- Bekliyor: gerçek kimlik sağlayıcısı ve API ortamı; ana uygulama başlangıcına oturum sağlayıcısının bağlanması.
- Bekliyor: dağıtılmış sunucuda iki oyunculu canlı doğrulama, akan saat gösterimi, beraberlik/terk işlemleri ve maç sonucu senkronizasyonu.

- Sunucu tarafında yetkili satranç hamlesi doğrulaması, saat ve maç sonucu.
- Sunucu eşleştirme puan aralığı politikası ve canlı iki oyuncu akış doğrulaması.
- İki cihazda eşzamanlı maç, terk, beraberlik, süre aşımı ve yinelenen hamle koruması.
- Ön koşul: dağıtılmış API ve kalıcı veri deposu.

## Sprint 5 — Okul ve topluluk

**Durum: istemci önizleme akışı tamamlandı; gerçek üyelik ve hizmetler bekliyor.**

- Tamamlandı: Sosyal ekranında arkadaş, okul/sınıf, grup ve turnuva bölümleri; okul/grup önizlemeleri yalnızca örnek olarak işaretlenir.
- Tamamlandı: Önizleme ayrıntılarında gerçek üyelik, öğrenci veya etkinlik bulunmadığı açıklanır; okul/öğretmen doğrulaması ve veli izinleri olmadan katılım açılmaz.
- Tamamlandı: Turnuva takvimi ve arkadaş listesi hizmet yokken boş durum gösterir; sahte çevrim içi kullanıcı, tarih, kayıt veya sonuç gösterilmez.
- Bekliyor: Okul/sınıf kataloğu, doğrulanmış öğretmen rolleri, arkadaşlık, gruplar ve turnuvalar için API ve kalıcı veri deposu.
- Bekliyor: Sunucu tarafında rol/izin modeli, öğrenci görünürlüğü ve moderasyon; gerçek okullar ve kullanıcılarla uçtan uca doğrulama.

- Ülke/şehir/okul/sınıf kayıtları ve doğrulanmış öğretmen rolleri.
- Arkadaşlar, gruplar, turnuvalar ve gerçek zamanlı liderlik.
- Öğrenci görünürlüğü ve erişim kuralları.
- Ön koşul: rol/izin modeli ve Sprint 2 güvenlik akışları.

## Sprint 6 — Yayın hazırlığı

- İzleme, hata raporlama, yedekleme, kötüye kullanım önleme ve yük kontrolleri.
- Gerçek Android cihaz testleri, iOS derlemesi, mağaza imzası ve gizlilik/hukuk metinleri.
- Erişilebilirlik, çevrim dışı/bağlantı hatası deneyimi ve mağaza görselleri.
- Ön koşul: üretim ortamı ve kullanıcının bağlayacağı gerçek cihaz/hesaplar.

## İleri aşama — Gemini destekli satranç koçu

**Durum: kapsam notu; temel hesap ve canlı maç hizmetlerinden bağımsızdır.**

- Tahta konumu ve oyuncunun açıkça istediği analiz, sunucu tarafındaki AI servisine gönderilir; Google Gemini API anahtarı Flutter uygulamasına eklenmez.
- Gemini açıklama ve çalışma önerisi sunabilir; yasal hamle, saat, oyuncu kimliği, eşleşme ve maç sonucu mevcut satranç kuralları ile yetkili maç sunucusunda kalır.
- Yaş/veli politikası ve veri minimizasyonu belirlenmeden oyuncu profili, okul/sınıf bilgisi veya sohbet geçmişi gönderilmez.
- Ön koşul: ayrı sunucu tarafı AI servisi, bütçe/kota sınırları ve gizlilik değerlendirmesi.

## Gerekli dış girdiler

Canlı davet/maç için bir API ortamı ve alan adı; hesaplar için kimlik sağlayıcı; yayın için kurumsal uygulama kimliği ve mağaza imzaları gerekecek. Bunlar seçilene kadar API temeli sağlayıcıdan bağımsız kalır ve demo modu korunur.
