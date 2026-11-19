# Tahta ve taş koleksiyonu

Sürüm 0.3.0 ile koleksiyon 10 tahtaya çıktı: Usta Cevizi ve Krem Mermer özgün CC0 dokularını kullanır. 3D masa → Taş modeli altında Klasik veya Oyma Staunton seçilebilir; model ve renk paleti ayrı tercihlerdir. Oyma model küçük oyuncuların renkleriyle de çalışır. Kaynaklar ve mobil sadeleştirme ayrıntıları [ASSET_CREDITS.md](ASSET_CREDITS.md) içindedir. Eski görünüm JSON'larında `shape` alanı yoksa klasik model korunur.

Tahta üzerindeki palet düğmesinden veya Profil → Görünüm ve tema ekranından seçim yapılır. Yerel oyun, çevrim içi maç istemcisi ve maç incelemesi aynı cihaz tercihini kullanır. Değişiklik hamleleri, taslağı veya saatleri değiştirmez; inceleme tahtası salt okunur kalır.

| Görünüm | Davranış |
|---|---|
| Sade 2D | Düz renkler, belirgin taş şekilleri, üstten kareler |
| Üstten gerçekçi | Ahşap/mermer dokusu, gölgeli vektör taşlar, üstten kareler |
| 3D masa | Hacimli taş geometrisi, perspektif, yönlü ışık, temas gölgesi ve kısa hamle hareketi |

3D kamera seçenekleri masa hizası (38°), dengeli (52°) ve yukarıdan (68°). Tahta çevirme, kamera ve dokunma hesabı aynı projeksiyonu kullanır. Görünen taş yüzeyine dokunmak o taşı seçer; boş kareler tahta düzleminden bulunur. Ekran okuyucu için 64 karede taş adı, renk, seçim ve yasal hamle bilgisi bulunur. Sistem animasyonları azaltınca hareket atlanır.

## Koleksiyon

| Tahta | Önerilen takım renkleri |
|---|---|
| Ceviz & Fildişi | Fildişi & Abanoz |
| Doğal Meşe | Fildişi & Abanoz |
| Carrara Mermer | Porselen & Lacivert |
| Antrasit & Pirinç | Gümüş & Bronz |
| Neşeli Bahçe | Ahududu & Petrol |
| Şeker Bahçesi | Mercan & Mavi |
| Deniz Macerası | Mercan & Mavi |
| Masal Masası | Güneş & Mor |

Tahta seçimi uyumlu taş setini getirir; oyuncu sonra altı taş setinden başka birini seçebilir. Küçük oyuncuların masaları neon içermez. Her takımın tek ana rengi ve altı tanınabilir taş şekli vardır. Beyaz/siyah oyun kuralları ve oyuncu etiketleri korunur. Bu görünüm seçimi yaş veya hesap rolü belirlemez.

Tercihler `appearance.board.v1` altında cihazda JSON olarak saklanır. Yazmalar sırayla birleşir; başarısız yazma mevcut görünümü değiştirmez ve yeniden denenebilir. Bozuk veya gelecekteki tercih sürümü klasik görünüme döner.

## Görsel kaynaklar

Taşlar Flutter Canvas için uygulamaya ait üç boyutlu meshlerden üretilir: dönel yüzeyler, kral haçı/kale mazgalları ve üçgenlenmiş, kenarları eğimli at gövdesi. Kamera projeksiyonu, yüz ayıklama, derinlik sırası ve aydınlatma uygulama içinde hesaplanır. Görünen taş üçgenleri tek çizim çağrısında toplanır. Tahta dokuları bir kez 512 piksel genişliğe çözülüp paylaşılır. Saniyelik saat güncellemesi değişmeyen tahtayı tekrar boyamaz.

Bu bir Unity/Unreal entegrasyonu veya PBR oyun motoru değildir. Gerçek hacimli geometri ve malzeme dokularıyla hafif bir Flutter çizicisidir. Cihaz performansı, gerçek Android dokunması ve depolama doğrulaması fiziksel cihaz testini bekler. Emülatör başlatılmadı.

Dokular yerleşik **imagegen** aracıyla, her malzeme için ayrı bir çağrıda üretildi. CLI kullanılmadı. Kaynak görseller projeye kopyalandı; üretim klasöründeki asıllar korundu.

- `assets/textures/wood-walnut-v1.png` — doğal ceviz albedo dokusu.
- `assets/textures/marble-carrara-v1.png` — ince damarlı Carrara mermer albedo dokusu.
- `previews/board-collection.png` — dokuz görünümün Flutter render karşılaştırması.
- `previews/game-walnut-3d.png`, `game-marble-3d.png`, `game-candy-3d.png`, `game-candy-flat.png`, `game-marble-overhead.png` — mobil oyun önizlemeleri.
- `previews/game-walnut-3d-dark.png`, `game-candy-3d-dark.png` — koyu tema önizlemeleri.
- `previews/appearance-3d.png` — görünüm seçme ekranı.

## Üretim istemleri

### Ceviz

Use case: photorealistic-natural. Asset type: seamless game material texture, opaque square bitmap. Primary request: premium natural walnut wood surface scanned material, fine straight grain and subtle pores, warm taupe brown neutral tone. Entire frame contains only flat wood grain material viewed exactly perpendicular from above, no furniture, no chessboard, no pieces, no edges, no labels, no text. Even diffuse albedo lighting, no cast shadows, no glossy hotspots, no vignette, no perspective. Small-scale consistent grain detail suitable for applying to many individual chessboard squares. Seamless tileable edges, high-resolution realistic PBR-style albedo.

### Mermer

Use case: photorealistic-natural. Asset type: seamless game material texture, opaque square bitmap. Primary request: premium softly honed white Carrara marble scanned material with sparse thin warm-gray flowing natural veins, mostly pearl off-white field, restrained delicate geology, very fine mineral detail. Entire frame is only flat marble surface viewed exactly perpendicular from above, no chessboard, no pieces, no furniture, no edges, no labels, no text. Even diffuse albedo lighting, no cast shadows, no specular glare, no vignette, no perspective. Calm material for a premium chessboard. Seamless tileable edges, high-resolution realistic PBR-style albedo.
