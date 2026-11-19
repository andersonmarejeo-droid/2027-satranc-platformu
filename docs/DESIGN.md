# Görsel yön

Neon yok. Ceviz, fildişi, koyu orman yeşili ve ölçülü pirinç vurguları. Açık tema sıcak kırık beyaz; koyu tema sakin yeşil/siyah yüzeyler. Seçim vurgusu 160 ms, 3D taş hareketi 220 ms sürer. 2D taş güncellemesinde solup yeniden belirme kaldırıldı.

## Sakin kart yüzeyleri ve kararlı tahta — 0.5.0

Ortak kartlarda sıcak ve çok hafif renk geçişi, ince çerçeve ve düşük opaklıklı gölge kullanılır. Eylem simgeleri küçük tonlu alanlarda; ana oyun kartı koyu orman yeşili ve ölçülü pirinç kenarıyla ayrılır. Bölüm başlıklarında küçük pirinç işareti, liderlikte kompakt sıra rozetleri vardır. Mevcut kart ölçüleri korunur; parlayan veya hareketli arka plan kullanılmaz.

Saat, pozisyon, son hamle ve seçili taş tek tutarlı bildirimde güncellenir. Bilgisayar hamlesi önce seçim göstermek yerine doğrudan uygulanır. 3D'de çok hızlı yanıt, insan hamlesinin kayması bitmeden ikinci animasyonu başlatmaz. Saat güncellemeleri değişmeyen 3D çizimini yeniden boyamaz; doku ve model Future önbellekleri korunur.

Otomatik kayıt açıklaması kayıt başlarken/biterken uzayıp kısalmaz. Sıra metni, mevcut genişlik ve yazı büyütmesine göre iki oyuncunun metnini de alacak kadar yer ayırır; normal yazıda tek satır kalır. Aktif oyuncu noktasının boş yeri korunur, saat alanları sıra geçişinde sağa/sola kaymaz.

Tahta altındaki Olası hamleleri göster anahtarı 2D, üstten görünüm ve 3D için ortak ve kalıcıdır. Kapalıyken hedef işaretleri ve erişilebilirlikte hamle ipucu gizlenir; yasal hedefler hesaplanmaya devam eder ve dokunarak oynama/taş alma etkilenmez.

Oyun tahtası üç görünüm sunar: sade 2D, üstten gerçekçi ve hacimli taş geometrisiyle 3D masa. Doğal ahşap/mermer dokuları, kontrollü ışık, temas gölgeleri ve ayırt edilebilir Staunton şekilleri kullanılır. 3D kamera üç açıdan seçilir. [Tahta koleksiyonu, malzeme kaynakları ve üretim istemleri](BOARD_APPEARANCE.md).

## Kompakt ekran düzeni — 0.3.1

Sayfa kenarları 16 px, kart içleri 10 px ve bölüm araları 10 px kullanır. Başlık 26 px, bölüm başlığı 18 px; alt menü 64 px yüksekliğindedir. Yazılar sistemin büyütme ayarına uyar, içerik sabit yüksekliğe sıkıştırılmaz. Eylem kartlarının tamamına dokunulur; ana düğmelerin en az 48 px, seçenek kartlarının en az 64 px yüksekliği korunur (0.4.0 ölçüleri).

Oyna ekranı başlık/açıklama/düğme tekrarını üç kısa seçenekte birleştirir. Ana sayfa görseli kısalır; keşif bağlantıları yatay içerikli kart olur. Profilde ad düzenleme simgesi isimle aynı sıradadır. Liderlik toplulukları ayrı boşluklu kartlar yerine bölücülü liste kullanır. Malzeme kartları ad ve küçük renk örneği gösterir; seçilen malzemenin tam açıklaması tahta önizlemesinin altında kalır.

## Ana ekran görseli

Dosya: assets/images/chess_hero.png. Yerleşik **imagegen** aracı kullanıldı; CLI/API anahtarı kullanılmadı. Son üretim istemi:

```text
Use case: stylized-concept
Asset type: premium chess mobile app home hero background, landscape 3:2
Primary request: An exquisitely realistic Unreal-quality studio render of a traditional Staunton ivory chess knight and king, with a dark walnut opposing king, standing on a high-end walnut and ivory chessboard. Rich natural wood grain, subtly matte polished ivory surfaces, carefully restrained realistic ambient occlusion and contact shadows, tactile sculpted pieces. Calm professional mood.
Composition: pieces clustered in the right half; left half is quiet shadowed warm dark green/walnut negative space for UI copy that will be overlaid by code. Low three-quarter camera view with shallow depth of field. Board extends along bottom, cropped naturally. Soft light from upper left, soft warm highlights, no harsh reflections.
Colors: deep forest green near-black background, warm walnut, soft ivory, muted brass accents. No neon, no saturated gaming colors, no glow, no text, no logos, no watermark. Only still chess product rendering.
```

Bu sürümün 3D görünümü klasik meshleri ve Poly Haven'ın CC0 Oyma Staunton geometrisini Flutter Canvas ile projekte eder. Ayrıntılı model telefon için sadeleştirilir ve bir kez yüklenir; önbellekten gelen model/dokular yeniden seçimde doğrudan gösterilir. Kaynak normal, roughness ve PBR malzeme haritaları kullanılmaz; kontrollü uygulama ışığı ve altı renk paleti uygulanır. Çizici ileride bir PBR motoruna taşınabilir; oyun davranışı görünümden bağımsızdır. Mevcut 3D taşlar tek üçgen çiziminde toplanır; bu yaklaşım belirli bir telefon FPS değerini garanti etmez. [Özgün varlıklar ve lisanslar](ASSET_CREDITS.md).

Roboto 400/500/700 yazı tipleri Flutter SDK içinden yerel pakete alındı; lisans `assets/fonts/roboto_license.txt` içindedir. Ana sayfa görseli kullanılabilir genişliği doldurur. Web açılışı ilk Flutter karesi gelene kadar sakin bir gösterge sunar. Başlatma akışı [Flutter'ın resmi web başlatma API'sini](https://docs.flutter.dev/platform-integration/web/initialization) kullanır.

