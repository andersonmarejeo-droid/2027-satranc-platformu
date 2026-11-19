# Bilgisayar rakibi

Oyna ekranında **Sen ve Bilgisayar** girişi ve **Kolay / Orta / Zor / Usta** seçenekleri bulunur. Yeni oyunun varsayılanı Kolay'dır. Tahtada oyuncular Sen ve Bilgisayar olarak gösterilir; seçilen seviye üst bilgide, taslakta ve maç geçmişi özetinde korunur. Bilgisayar siyah taşları oynar. Seviye bir oyun boyunca sabittir; yeni oyun seçiminde değiştirilebilir.

Çevrim içi hızlı eşleşmede gerçek rakip 15 saniye içinde bulunamazsa kullanıcıya bilgisayara karşı başlama seçeneği sunulur. Bu seçenek açıkça bilgisayar antrenmanı olarak etiketlenir; bot gerçek oyuncu gibi gösterilmez ve bu maç çevrim içi sıralamaya eklenmez.

Yerel rakip ağ bağlantısı, bulut modeli veya API anahtarı kullanmaz. Android'de ayrı isolate içinde alpha-beta arama ve artan derinlik kullanır. Tamamlanmamış daha derin arama, son tamamlanan sonucun yerini almaz; ilk tur kesilirse yasal bir hamle yedeği vardır. Her dal `finally` ile geri alınır. Duraklatma, geri alma ve çıkış sonrası eski yanıtlar uygulanmaz.

| Seviye | Ana arama üst sınırı | Düğüm sınırı | Hesap süresi bütçesi | Alma devamı |
| --- | --- | --- | --- | --- |
| Kolay | 1 yarım hamle | 400 | 250 ms | Kapalı |
| Orta | 2 yarım hamle | 2.500 | 700 ms | Kapalı |
| Zor | 3 yarım hamle | 12.000 | 1.400 ms | En fazla 2 |
| Usta | 4 yarım hamle | 35.000 | 2.400 ms | En fazla 3 |

Bütçe dolunca son tamamlanan derinlik kullanılır; her telefonda üst sınıra ulaşılmaz. Güçlü seviyeler taş alışlarını ve şah tehdidinden çıkışı değerlendirme öncesi kısa süre uzatır. Hesap süresi bütçesi kullanıcıya hamle yapma süresi koymaz. Isolate başlatma ve son düğüm işlemi bütçeye eklenebilir.

Bu dört ad uygulama içi güç basamaklarıdır; Usta için resmi ustalık veya belirli bir Elo gücü iddiası yoktur. Motor halen malzeme, merkez ve gelişim değerlendiren yerel satranç rakibidir. Web'de Flutter `compute` aynı olay döngüsünde çalışabilir; gerçek Worker entegrasyonu ileride ele alınmalıdır.

`SavedGame.difficulty` JSON'da seviye adını taşır. Eski kayıtlarda alan yoksa Orta seçilir; önceki iki yarım hamlelik davranış korunur. Bilinmeyen kayıt değeri reddedilir. Taslak ile devam edildiğinde bağlantının yeni seviye parametresi kayıtlı değeri değiştirmez. PGN ve satranç kuralındaki beyaz/siyah anlamları standart olarak kalır; bilgisayarlı oyunun görünür durum metni oyuncu adlarını kullanır.
