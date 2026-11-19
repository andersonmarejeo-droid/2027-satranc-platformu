# Satranç Platformu — 6 Seviyeli Gelişim Sprinti

Bu plan mevcut feature-first Flutter yapısını korur. Yeni özellikler mevcut route, model ve repository sözleşmelerini kırmadan; adapter, versioned data ve feature flag yaklaşımıyla eklenir.

## Değişmez ürün ilkeleri

- Yerel oyun ve çevrim dışı akış her sürümde çalışır kalacak.
- Çevrim içi maçta ipucu, öneri oku ve analiz yardımı kapalı kalacak.
- Bot hiçbir ekranda gerçek oyuncu gibi gösterilmeyecek.
- Okul, sınıf ve grup verisi kullanıcıya kademeli ve arama destekli gösterilecek.
- Yeni görsel varlıklar erişilebilir kontrastı, düşük cihaz performansını ve açık temayı koruyacak.
- Riskli davranışlar önce feature flag arkasında, sonra kapalı testte açılacak.

## Sprint 0 — Koruma kalkanı ve ölçüm tabanı

**Amaç:** Mevcut yapıyı güvenceye almak.

**Adımlar**

1. `flutter analyze` ve tüm mevcut testleri temiz çalıştır.
2. Yerel oyun, çevrim içi tahta, meydan okuma, liderlik ve okul seçimi için duman testlerini sabitle.
3. Uygulama sürümünü; oyun, maç, katalog ve görsel varlık değişikliklerinden bağımsız takip edilecek şekilde kayıt altına al.
4. Online hata sınıflarını tek bir kullanıcı mesajı sözleşmesine bağla: bağlantı, yetki, sıra, saat ve sunucu reddi.
5. 2D/üstten/3D tahta için düşük cihaz fallback kararını belgeleyip ölç.

**Kabul kriteri:** Mevcut 14 hedefli oyun/akış testi ve `flutter analyze --no-pub` geçer; hiçbir mevcut route değişmez.

## Seviye 1 — Çevrim içi maç güvenilirliği

**Amaç:** Gerçek iki cihazda kopmayan, doğru saat ve doğru sıra ile oynanan maç.

**Adımlar**

1. İki fiziksel cihazla eşleşme, ilk hamle, karşı hamle ve maç bitiş akışını test et.
2. Uygulamayı arka plana alma, ağ kesme, yeniden bağlanma ve eski hamle gönderme senaryolarını test et.
3. Hamle, saat, sıra ve sonuç doğrulamasını transaction ve güvenlik kuralı seviyesinde denetle.
4. Beraberlik, rövanş, hızlı mesaj ve yeniden bağlanma durumlarını ayrı durum geçişleri olarak test et.
5. 3 dakikalık hamlesizlik kuralını kullanıcıya “Hamle sırası 3 dakika içinde oynanmalı” şeklinde açık göster.

**Görsel kalite dilimi**

- Tahta merkezde, oyuncu saatleri belirgin, alt kontroller tek satır olacak.
- Aktif saat ve son hamle vurgusu sakin turkuaz/turuncu tonlarla gösterilecek.
- Taş hareketi, yakalama ve sıra geçişi tek bir animasyon standardına bağlanacak.
- Tam ekran modunda yalnızca tahta, oyuncular ve küçük kontrol çubuğu kalacak.

**Kabul kriteri:** İki fiziksel cihazda 20 ardışık maç senaryosunda hamle kaybı, çift hamle veya yanlış sonuç görülmez.

## Seviye 2 — Eşleştirme, puan ve bot geçişi

**Amaç:** Rakip bulma ekranını adil ve anlaşılır hale getirmek.

**Adımlar**

1. Geçici kuyruk yerine beceri aralığı, süre seçimi ve bağlantı durumu kullanan eşleştirme sözleşmesi oluştur.
2. Yeni oyuncu için geçici yerleştirme puanı tanımla.
3. Bot fallback süresini kullanıcıya görünür yap; bot oyunlarını dereceli maçtan ayır.
4. Gerçek oyuncu, bot ve arkadaş daveti için ayrı sonuç türleri kullan.
5. Bağlantı kopması, terk ve yeniden katılma puan kurallarını belirle.

**Görsel kalite dilimi**

- Yaş seçimi gibi gereksiz ara ekranları kaldır; doğrudan “Rakip ara” akışı.
- Eşleşme durumunu tek kartta göster: aranıyor, rakip bulundu, bilgisayara geç.
- Bot seçimi kolay/orta/zor/usta olarak sade kalacak.

**Kabul kriteri:** Kullanıcı hangi rakiple ve hangi puan kuralıyla oynadığını maç başlamadan anlayabilir.

## Seviye 3 — Maç sonrası analiz ve arşiv

**Amaç:** Oyunu oynatmakla kalmayıp kullanıcıya gelişim sebebi vermek.

**Adımlar**

1. Oyun arşivine hamle listesi, sonuç, süre ve rakip türü ekle.
2. PGN dışa aktarma ve paylaşma ekle.
3. İlk sürümde yalnızca kritik hata, kaçırılan basit fırsat ve oyun sonu özeti üret.
4. Analiz ekranını canlı maçtan tamamen ayır; canlı maçta öneri gösterme.
5. Yerel analiz ile sunucu analizini repository arkasında soyutla.

**Görsel kalite dilimi**

- Sonuç ekranı üç kısa bloktan oluşacak: sonuç, iyi yaptığın şey, sonraki pratik.
- Eval çubuğu yalnızca analiz/review ekranında görünecek.
- Renkler hata için kırmızıya yüklenmeyecek; turuncu/amber ve açıklama metni kullanılacak.

**Kabul kriteri:** Her tamamlanan yerel ve çevrim içi maç açılabilir, tekrar oynatılabilir ve PGN olarak paylaşılabilir.

## Seviye 4 — Pratik, puzzle ve kişisel gelişim

**Amaç:** Kullanıcıyı her gün geri getirecek eğitim döngüsü.

**Adımlar**

1. Günlük tek görev: mat, taş kazanma, savunma veya oyun sonu.
2. Başlangıç için elle seçilmiş Türkçe puzzle paketi oluştur.
3. Kullanıcının kaçırdığı hamlelerden kişisel tekrar listesi üret.
4. Kolay/orta/zor/usta seviyelerini içerik zorluğuna bağla.
5. İlerleme, seri ve tamamlanan görevleri yerel olarak sakla; hesap açılınca senkronize et.

**Görsel kalite dilimi**

- Pratik kartı ana sayfada tek güçlü görsel ve tek CTA taşıyacak.
- İlerleme halkası küçük ve sakin olacak; ekranı oyunlaştırılmış sayaçlarla doldurmayacak.
- Çocuk modu için yumuşak renkli alternatif taş/tahta setleri korunacak.

**Kabul kriteri:** Yeni kullanıcı ilk 60 saniye içinde bir pratik görev başlatabilir ve tamamlanma durumunu görebilir.

## Seviye 5 — Okul, sınıf, grup ve turnuva araçları

**Amaç:** Uygulamanın asıl farklılaşmasını ürünleştirmek.

**Adımlar**

1. Okul, sınıf ve grup üyelik rollerini ayır: öğrenci, öğretmen, yönetici.
2. 20 kişilik sınıf/grup sınırını arayüzde önceden göster.
3. Öğretmen için sınıf oluşturma, davet, görev ve sonuç özeti ekle.
4. Sınıflar arası hızlı maç ve arena turnuvası ekle.
5. Liderlikte ülke → şehir → okul → sınıf/grup → oyuncu filtrelerini tek bir basamaklı akışta tut.
6. Puanın Elo olmadığını her ilgili ekranda açıkça belirt; topluluk puanı ile resmî oyun puanını ayır.

**Görsel kalite dilimi**

- Liderlik ekranında uzun kartlar yerine kompakt satır ve sıralama rozeti kullan.
- Okul ve sınıf seçiminde arama, alfabetik sıralama ve ilçe gruplaması kullan.
- Öğretmen ekranında veri yoğunluğu artabilir; oyuncu ekranında sade kalır.

**Kabul kriteri:** Bir öğretmen sınıf kurabilir, 20 öğrenciye kadar davet gönderebilir ve sınıf sıralamasını görebilir.

## Seviye 6 — Dünya kataloğu, dil ve sürdürülebilir yayın

**Amaç:** 177+ ülkeye açılırken APK’yı ve veri kalitesini kontrol etmek.

**Adımlar**

1. Ülke listesini uygulamada küçük tut; şehirleri ülke seçilince getir.
2. Okul kataloglarını ülke/şehir bazında uzaktan ve sürümlü yükle.
3. Arama, yerel ad, alternatif yazım ve alfabetik sıralama ekle.
4. İngilizceyi ikinci dil olarak tamamla; ardından okul terimlerini yerelleştir.
5. Okul verisi için kaynak, lisans, güncelleme tarihi ve silme/öneri süreci tut.
6. AAB, kapalı test, crash raporu ve sürüm notlarını CI sürecine bağla.

**Görsel kalite dilimi**

- Metinlerin uzamasına karşı tüm kartlar esnek tasarlanacak.
- Arapça ve uzun okul adları için taşma, satır yüksekliği ve RTL testi yapılacak.
- Görseller WebP/AVIF ve cihaz yoğunluğuna göre küçültülecek.

**Kabul kriteri:** Dil veya ülke değişimi ana oyun akışını bozmaz; okul katalogları APK boyutunu gereksiz büyütmez.

## Yatay görsel kalite hattı

Her seviyede şu kontroller yapılacak:

- açık tema varsayılan kalacak;
- 2D tahta düşük cihazlarda en güvenli mod olacak;
- 3D görünüm isteğe bağlı ve performans ölçümlü olacak;
- 44 dp dokunma alanı, ekran okuyucu etiketi ve renk körlüğü için alternatif vurgu sağlanacak;
- oyun ekranı kaydırma gerektirmeyecek;
- tek ekran tek ana eylem taşıyacak;
- animasyonlar kısa, tekrarlanabilir ve azaltılmış hareket ayarına duyarlı olacak;
- yeni görseller mevcut tahta malzemeleri ve turkuaz/turuncu paletle uyumlu kalacak.

## İlk uygulama dilimi

İlk kodlama adımı Seviye 1’in güvenilirlik temeli olacak:

1. Sprint planını proje içine eklemek.
2. Mevcut analiz ve test tabanını doğrulamak.
3. Online bağlantı, hamle ve sonuç durumları için test kapsamını genişletmek.
4. Online maçtaki bağlantı durumunu ve hata mesajlarını tek bir görsel bileşende birleştirmek.
5. Fiziksel cihazda çevrim içi maç doğrulaması yapmak; emülatör başlatmamak.

Bu sıra, görsel iyileştirmeyi ertelemez; oyun ekranı düzeni ve hareket standardı Seviye 1’in parçası olarak aynı anda ele alınır.
