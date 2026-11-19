# Topluluk puanı — 0.8.0

Android mağaza yapılandırması Firebase Spark kullanır. Ücretli plan, Cloud Functions veya yeni ücretli API açılmadı.

## Gerçek sonuçlar

Her uygulama UCI geçmişini standart satranç kurallarıyla yeniden oynatır. Maç bittiğinde `onlineResults` belgesine kendi sonucunu bildirir. İkinci katılımcı aynı hamle sayısı, zaman damgası ve sonucu onaylamadan puan yazılamaz. Hamle/sonuç belgeleri yalnız iki katılımcıya açıktır. İki taraf onayladığında yeni hamle reddedilir.

Sunucuda tam satranç motoru yoktur. Kurallar sahipliği, sıra/geçmiş/saat sınırlarını, sonuç mutabakatını ve puan aritmetiğini denetler; iki değiştirilmiş istemcinin anlaşarak uydurduğu matı saptayamaz. Bu nedenle puan **Elo veya sunucu tarafından doğrulanmış rekabetçi derece** olarak sunulmaz. Okul ve sınıf üyeliği beyana dayanır. Hileye dayanıklı resmi turnuva için yetkili motor ve üyelik doğrulaması ayrıca gerekir.

## Hesap ve görünürlük

Misafir UID e-posta/şifre kimliğine bağlanır; mevcut maç sahipliği korunur. E-posta doğrulaması olmadan sıralamaya katılım açılamaz. Özel `playerAccounts` belgesinde görünen ad ve seçili topluluk yedeklenir; e-posta Firebase Authentication'dadır, kamuya açık skorlarda bulunmaz. Şifre uygulama tercihleri veya Firestore'a kaydedilmez.

Sıralamaya katılım varsayılan kapalıdır. Açıldığında takma ad ve seçilen toplulukların puanları giriş yapmış oyuncular tarafından okunabilir. Maçın katılımcı profili bitişte sabitlenir: sonraki okul değişikliği geçmiş puanları yeni okula taşımaz. Eski sonuç için seçili topluluk kartı korunur; yeni maç yeni topluluğa yazılır. Gruplar okul hiyerarşisinden bağımsızdır. Bir okulun resmi üyeliği veya okul/MEB ortaklığı iddia edilmez.

## Tekrarsız puan ve dönemler

Galibiyet 3, beraberlik 1, mağlubiyet 0 puandır. En az dört yarım hamle içeren sonuçlar sayılır. Her sonuç ve kullanıcı/topluluk/dönem için değişmez `scoreClaims` belgesi vardır; sayaçla aynı işlemde oluşturulur. Kurallar yeni belge olmadan sayaç artışını, yanlış topluluğu, yanlış dönemi, fazla puanı ve tekrar yazmayı reddeder.

Ülke, şehir, okul, sınıf ve seçili gruplar için ayrı kartlar tutulur. Tüm zamanlar, Türkiye saatiyle ay ve pazartesi 00:00'da başlayan hafta vardır. Haftalık kupa bu dönem sıralamasıdır; otomatik turnuva eşleştirmesi veya eleme ağacı değildir. İlk 100 kişi listelenir; kişinin sırası tüm sonuç kartlarında yüksek puan ve eşit puandaki UID sırası üzerinden sayılır. Liste yenileme düğmesiyle veya aşağı çekilerek güncellenir.

## Ücretsiz kota ve bağlantı

Her kullanıcı, sonuç başına `2 × 3 dönem × seçili topluluk sayısı` puan belgesi yazımı yapar. Oyun ekranındaki bağlantı yoklaması 20 saniyede bir yazımdır. Spark günlük kotaları geçerlidir; aşılırsa işlemler bekler/hata gösterir, ücretli plana geçilmez. Örnek/demo sıralama Firebase olmayan yerel test sürümünde korunur; mağaza sürümünde boş gerçek liste gösterilir, örnek oyuncular gerçekmiş gibi sunulmaz.

Rakibin durumu son oyun ekranı yoklamasına dayanır; sistem genel çevrim içi durumunu kesin olarak iddia etmez. Kısa inceleme taş alışları, rok, terfi ve şah/mat olaylarını açıklar; tam motor analizi değildir ve yalnız bitmiş oyunlarda açılır.

## Veri silme

Sıralamadan ayrılma kullanıcının açık skor kartlarını ve tekrar önleme belgelerini kaldırır; gelecekteki sonuçları puanlamaz. Çevrim içi verileri silme ayrıca profil yedeğini, okul bildirimlerini, sonuç belgelerini, maç ekranı bağlantı belgelerini ve önceki davet/maç verilerini temizler; ardından Authentication hesabı silinir. Yerel geçmiş cihazda kalır. Yeni hesaba girişte özel profil/okul geri yüklenir; yerel geçmiş başka telefona aktarılmaz.

## Yayın sınırları

0.8.0 için yeni veri açıklaması ve Hosting gizlilik politikası hazırlanır. Play Console veri güvenliği beyanının eski sürüm açıklaması yeni hesap/katılım özellikleriyle uyumlu hale getirilmeden bu sürüm mağazaya yayımlanmaz. İki fiziksel telefonla WhatsApp/App Links denemesi ayrı doğrulama gerektirir. Emülatör kullanılmaz.
