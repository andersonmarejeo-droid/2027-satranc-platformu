# Türkiye okul/kurum rehberi — 0.7.2+12

Kaynak: https://github.com/dalgali/MEB-okul-listesi
Sabit kaynak commit: `0f2b3e6af008f283c1f9b43bdcbd1556eab8da1f`.
MEB kaynak sayfası: https://www.meb.gov.tr/baglantilar/okullar/
Kaynak veri tarihi: 31 Ağustos 2026. İçe aktarma: 4 Ekim 2026.

Ek resmî kaynak: https://ookgm.meb.gov.tr/kurumlar.php (Özel Okullar).
4 Ekim 2026'da bütün 81 il ve her ildeki bütün sayfalama bağlantıları alındı.
Her ilde alınan satır sayısı kaynağın bildirdiği kurum sayısıyla doğrulandı.
12.620 özel okul satırındaki tam yinelenen 1 kayıt çıkarıldı; 12.619 benzersiz
özel okul eklendi. Kamu rehberiyle aynı il/ilçe/ad kaydı bulunmadı.
Birleşik toplam **67.736 okul/kurum**; Giresun **393** (374 + 19 özel okul).
Kaynak URL'leri, güncelleme tarihleri ve SHA256 değerleri `PRIVATE_SOURCE.json`
ve `private-schools.json` içinde kayıtlıdır. Özel okul tablolarının bildirdiği
güncelleme tarihi 18 Eylül 2026'dır; uygulamadaki özel okul tarih etiketi
4 Ekim 2026 içe aktarma tarihini gösterir.

Kaynakta 55.216 okul/kurum kaydı var. 81 Türkiye iline bağlı 55.117 kayıt
uygulamanın çevrimdışı rehberinde yer alıyor. 99 Bakanlık/yurt dışı kaydı Türkiye
şehri olmadığı için şehir seçimlerine eklenmedi. Giresun'da 374 kayıt var.
Bu liste kaynağın kamuya açık MEB okul/kurum siteleri anlık görüntüsüdür;
Türkiye'deki bütün devlet/özel okulların eksiksiz veya güncel resmî sicili
olduğu doğrulanmış değildir. Üniversiteler bu kaynak kapsamında değildir.

Yalnızca kurum kodu, okul/kurum adı, il, ilçe ve kaynağın isimden tahmin ettiği
kurum türü tutulur. Öğrenci/öğretmen bilgileri, telefon, konum, logo, fotoğraf
aktarılmaz. Kurum kodları kalıcı kimliklerdir. Önceki Giresun Fen Lisesi ve
Giresun Lisesi kimlikleri (`gfl`, `gl`) sırasıyla 962238 ve 150926 ile eşlenir;
önceden kaydedilen okul ve sınıf seçimleri korunur.

Özel okul kaynağı kurum kodu sunmadığından özel okullara MEB kodu uydurulmaz;
`institutionCode` boş kalır. Uygulama kimliği il/ilçe/ad/tür ve aynı adlı
kampüsleri ayırmak için adresin özet değerinden türetilir; adres uygulamaya
aktarılmaz. Kaynak okul adı veya adresi değişirse bu kimlik değişebilir;
sonraki rehber güncellemesinde eski seçimler için eşleme ayrıca kontrol edilmelidir.

Türkiye hazır seçilir. Aranabilir şehir listesi → yalnızca o şehrin okulları →
sınıf/şube seçimi açılır. İlçe ek bir zorunlu adım değildir; okul listesinde
görünür ve okul aramasında kullanılabilir. Türkçe harfler Latin klavyeyle de
aranabilir. Okul ve sınıf isteğe bağlı, gruplar ayrı ve açılır bir bölümdedir.

Sınıf seçimi, 1–12. sınıf ve şubeden öğrencinin beyan ettiği okul kapsamında
benzersiz bir kimlik üretir. Bu sınıflar resmî okul şube listesi veya doğrulanmış
üyelik değildir. MEB öğrenci/sınıf kayıtları alınmamıştır. Mevcut örnek oyuncu
sıralamaları örnek etiketi taşımaya devam eder; gerçek okul kataloğu, canlı
üyelik veya puan sistemi anlamına gelmez.

55 bin satırın tek ekranda widget'a dönüşmemesi için kayıt seçim listeleri
tembel yüklenir; sıralama listesinde arama ve 40 satırlık kademeli gösterim
kullanılır. Katalog JSON dosyası uygulamayla gelir; ücretsiz Firebase okuma
kotası tüketmeden internet yokken de seçilebilir. Katalog yerel üyelik
okunmadan önce yüklenir; böylece yeni okul kimlikleri yeniden açılışta tanınır.

## Lisans ve izin durumu

Depo MIT lisanslıdır. Lisans metni ve kaynak bilgisi
`assets/data/schools/LICENSE.txt` ve `SOURCE.json` içinde korunur. Bu depo lisansı
MEB'in kaynak veri üzerindeki hakları için izin alındığının kanıtı değildir;
resmî özel okul tablolarına da bir MIT kullanım izni verdiği söylenmez.
MEB'in güncel koşulları: https://www.meb.gov.tr/gizlilik-kullanim-ve-telif-haklari/duyuru/28029/tr

Kullanıcının talebiyle yerel uygulamaya ekleme tamamlanır; MEB yeniden kullanım
izni/lisansının ayrıca değerlendirilmesi sonraya bırakılmıştır. İzin alınmış,
MEB onaylı veya MEB ile ortak uygulama olduğuna dair bir ifade kullanılmaz.
Bu sürümün katalog eklenmiş dağıtımı Play Console'a otomatik yüklenmez.

Tam kaynak dosya SHA256:
`46a0529079d43c6b29062e33c03e29c8d6315ecbc4272006e177d327b10ec2a3`.
İçe aktarma dönüştürücüsü `tool/import_school_catalog.mjs` dosyasıdır.

Yeniden üretim: kaynak commit içindeki `data/meb-okullar.json`, `LICENSE` ve
GitHub commit cevabını `source-commit.json` adıyla ayrı bir kaynak klasöründe
tutun; `node tool/import_school_catalog.mjs <proje-klasörü> <kaynak-klasörü>`
çalıştırın. Dönüştürücü beklenen kaynak/kapsam sayıları değişirse durur; yeni
veri sürümü ancak kapsam ve kaynak incelemesinden sonra kabul edilmelidir.

Özel okullar için `node tool/fetch_private_school_catalog.mjs <kaynak-klasörü>
<proje-klasörü>` ve ardından `node tool/import_private_school_catalog.mjs
<proje-klasörü> <kaynak-klasörü>` kullanılır. İlk araç en fazla iki eşzamanlı
istek ve bekleme aralıkları kullanır; kimlik doğrulaması veya kapalı öğrenci
modüllerine erişmez. Bütün il/sayfa sayıları tutmadan içe aktarma dosyası üretmez.
