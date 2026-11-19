# Satranç Platformu · marka ve açılış

Görünen ad Android, iOS, web, Flutter uygulama başlığı ve yerel PGN Site etiketinde Satranç Platformu oldu. Kaynak klasörü ChessPlatform, Dart paketi chess_platform korunur; Android mağaza kimliği com.zpgames.satrancplatformu olarak sabitlendi.

## Açılış

Flutter açılışı 2,4 saniye sürer. Sakin koyu yeşil yüzeyde porselen/pirinç tonlarında 12 satranç taşı üstten aşağı farklı başlangıçlarla süzülür. Ortada at ve uygulama adı, altta ZP GAMES belirir; son bölümde ana ekrana yumuşak geçiş olur. Her uygulama başlangıcında bir kez çalışır; sayfa veya tema değişince tekrarlanmaz. Alttaki yönlendirme ağacı yerinde kalır; davet bağlantısının hedefi kaybolmaz.

Hareket azaltma tercihinde taş yağmuru kaldırılır, sabit marka görünümü 650 ms gösterilir. Açılışta dokunmalar engellenir ve alttaki ekranın erişilebilirlik içeriği geçici gizlenir. Android'in Flutter öncesi yerel açılış zemini de yeşildir; Android 12+ için açık/koyu sistem temaları ayrı kapsanır.

[Açılışın orta karesi](../previews/brand-intro-50.png) ve 25/75 yüzdelik kareler Flutter render çıktılarıdır. Animasyonun telefon performansı ayrıca fiziksel cihazda doğrulanmalıdır.

## Özgün simgeler

Built-in imagegen ile üç bağımsız raster görsel üretildi. Her biri kare, yazısız, neon kullanmayan özgün bir premium satranç yorumu:

1. [Fildişi at](../design/icon-options/01-ivory-knight.png): koyu yeşil zemin, porselen at ve ince pirinç detay.
2. [Mermer şah](../design/icon-options/02-marble-king.png): sıcak mermer, küçük ceviz/krem tahta.
3. [Ahşap madalyon](../design/icon-options/03-walnut-emblem.png): ceviz üzerinde fildişi at kabartması.

Tam üretim istemleri [PROMPTS.md](../design/icon-options/PROMPTS.md) içinde. Bütün seçenekler projeye kopyalandı; dış üretim klasörüne bağımlılık yok. Kullanıcının tüm kalan yayın hazırlığına verdiği yetkiyle Fildişi at varsayılan seçildi. Android launcher yoğunlukları ve 512 px mağaza simgesi uygulandı; diğer iki seçenek kaynaklarda korunur.

## Süre anlatımı

İlk satır Süresiz, 1 dk, 2 dk, 3 dk, 5 dk olarak sadeleştirildi. Uzun seçenekler ve hamle sonrası ek süre Diğer süreler altında. Örnek: 15 dakika ve hamlede 10 saniye, her oyuncunun 15 dakikayla başladığı ve her hamleden sonra saatine 10 saniye eklendiği anlamına gelir.

[FIDE kuralları](https://handbook.fide.com/chapter/E012023), başlangıç süresine 60 hamlelik ek süreyi ekleyerek Blitz'i en fazla 10 dakika; Rapid'i 10 dakikadan uzun ve 60 dakikadan kısa olarak ayırır. Çok kısa 1/2 dakikalık seçenekler uygulamadaki pratik tercihleridir; bütün seçeneklerin resmi puanlı turnuva kontrolü olduğu iddia edilmez. 90 dakika + hamlede 30 saniye uzun oyun için sunulur; 40. hamlede ek süre gibi birden fazla dönemli turnuva kontrolü bu sürümde uygulanmadı.

## Zeka Parkuru tarzında yeni öneri — 5 Ekim 2026

Tasarım seçeneği 04: krem at, turkuaz kale ve dört kareli kaide. Yerleşik ImageGen ile üretildi. [512 piksel önizleme](../design/icon-options/04-studio-chess-512.png) · [Son istem ve kaynaklar](../design/icon-options/04-STUDIO-PROMPT.md). Henüz uygulama veya Play simgesine uygulanmadı.


## Tam alan simge — 0.8.4+17

Büyük tek krem at ve tam alan turkuaz zemin, yeni Android launcher simgesine uygulandı. Yerleşik ImageGen ile görsel ve alpha katmanı hazırlandı. [Ana görsel](../design/icon-options/05-full-chess-512.png) · [Yuvarlak/kare 48px önizleme](../design/icon-options/05-launcher-preview.png) · [İstemler](../design/icon-options/05-PROMPTS.md) · [Teknik simge belgesi](LAUNCHER_ICON.md). Eski seçenekler korunur; önceki seçenek 04 bu tasarımla değiştirildi. Play mağaza görseli ayrıca yüklenmelidir ve henüz değiştirilmedi.
