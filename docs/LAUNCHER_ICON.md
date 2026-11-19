# Dolu alan satranç simgesi — 0.8.4+17

Yeni tasarım, Zeka Parkuru görsel ailesinden krem mermer at, küçük altın bant ve turkuaz zemini kullanır. Büyük tek taş, küçük boyutta okunabilir. Kare ana görsele yuvarlak köşe, çerçeve veya beyaz kenar çizilmedi. Arka plan tüm simge alanını doldurur; ana görsel ve alpha katmanı yerleşik ImageGen ile hazırlandı. [Tam istemler](../design/icon-options/05-PROMPTS.md).

Android manifesti yeni `@mipmap/ic_launcher_studio_v2` kaynağına bağlandı; eski simge dosyaları korunur. API24/25 için 48/72/96/144/192 px dolu PNG, 26+ için arka ve ön katman, 33+ için tek renk katmanı vardır. Mağaza için 512px öneri `store/graphics/app-icon-512-v2.png`; Play Console görseli ayrıca yüklenmelidir ve bu işlemde değiştirilmedi.

[Android'in resmî simge kılavuzu](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive) ayrı katmanlar, 108dp düzlem, 66dp güvenli bölge ve sistemin uyguladığı kesim biçimini açıklar. Dış kesim sistem tarafından yapılır. Uygulama simgesine önceden kesim çizilmez.

Yeni ön katmanda %18,5 iç pay kullanılır. Bu, 72dp görünen alanda yaklaşık %87,3 yüksekliğinde taş verir. Yalnız 108dp katman ölçüsüne bakıp fazladan boşluk eklenmedi. Alpha en az 64 olan piksellerin 108dp içindeki sınırları `[33.93, 21.97, 73.14, 84.83]`; `[21, 21, 87, 87]` güvenli alanının içindedir. Kontrol, gerçek alpha şeffaflığını ve tüm boyutları kaydeder: `releases/icon-084-verification.json`.

[Yuvarlak/kare ve 48px önizleme](../design/icon-options/05-launcher-preview.png), Android katmanlarının hesaplanan arayüz simülasyonudur; fiziksel telefon ekran görüntüsü değildir. Fiziksel telefonun uygulama listesinde kontrolü henüz yapılmadı. Emülatör başlatılmaz.

İş mantığında değişiklik yoktur. Kayıt, 12 karakter şifre şartı ve bağımsız doğrulama/yedekleme düzeltmeleri 0.8.3'ten korunur. Önceki 164 uygulama testi/10 canlı kayıt kontrolü yeni simge için yeniden koşulmuş sayılmaz. Bu değişiklik için Android paket derlemesi, simge kaynaklarının pakette bulunması, alpha ve maske önizlemeleri uygun kontrollerdir.
