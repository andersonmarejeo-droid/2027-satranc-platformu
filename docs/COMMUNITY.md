# Üyelik ve liderlik akışı

Sürüm 0.7.2 yerel rehberden seçim ve örnek sıralama akışını uygular; onaylı okul üyeliği ve canlı puan oluşturmaz.

- Profil → Topluluğun → hazır Türkiye → aramalı şehir → isteğe bağlı aramalı okul → isteğe bağlı sınıf/şube beyanı. Sınıf kimliği seçilen okulun altında oluşturulur. Ülke/şehir/okul değişince geçersiz alt seçimler temizlenir.
- Gruplar okuldan bağımsızdır ve bir oyuncu birden fazla grup seçebilir. Bölge veya okul değişikliği grupları silmez.
- Liderlik → Ülke seçimi → Şehirler / Okullar / Gruplar listesi → seçilen topluluğun oyuncuları. Şehir seçildikten sonra Okullar yalnızca o şehri gösterir; ülkenin bütün okullarına dönüş düğmesi vardır.
- Okullar seçimi önce okulların sıralamasını açar. Okul seçilince Okuldaki oyuncular ve Sınıfların sıralaması seçenekleri vardır. Sınıflar seçimi o okulun sınıflarını ortalama oyuncu puanına göre sıralar; sınıf satırına dokununca yalnız o sınıftaki oyuncular açılır. Geri düğmesi sınıf listesine döner. `gfl-9a` ile `gl-9a`, ikisi de 9-A adını taşısa da ayrı sınıflardır.
- Okul seçiminde ilçe başlıkları alfabetik gelir ve aynı ilçedeki okullar başlığın altında okul adına göre sıralanır. Kullanıcı listesinden anaokulları ve ilkokullar çıkarılmıştır; kaynak katalog ve eski kayıtlar korunur.
- Konum simgesi kayıtlı ülke/şehir/okul/sınıfına gider. Kişisel sıra, repository'nin `currentPlayerId` kimliği ile `RankingEntry.playerId` eşleştirilerek bulunur; aynı adı taşıyan bir başkası kullanıcı yerine gösterilmez. Eşleşme varsa sıra/puan özeti ve Sıramı bul düğmesi oyuncunun satırını görünür yapar. Sunucu adaptörü oturum kimliğini sağlamalıdır. Demo kaynağında bu kimlik yoktur; açıkça Sıralaman henüz oluşmadı denir, hayali puan üretilmez.
- Topluluk listeleri ortalama örnek puana, oyuncu listeleri oyuncu puanına göre sıralanır. Bu puanlar demo verisidir; seçilen misafir profiline puan veya sıralama uydurulmaz.
- Seçimler `profile.community.v1` altında saklanır; yüklemede ülke/şehir/okul/sınıf ilişkileri yeniden doğrulanır. Yazma başarısızsa önceki seçim korunur ve kullanıcı yeniden deneyebilir.

0.7.2+12 sürümünde Türkiye için 81 ilde 55.117 kamu rehberi kurumu ve 12.619 özel okul, toplam 67.736 okul/kurum çevrimdışı katalog olarak eklenmiştir. Kaynak kapsamı, tarih, korunan eski kimlikler ve sonraya bırakılan izin değerlendirmesi [SCHOOL_CATALOG.md](SCHOOL_CATALOG.md) dosyasındadır. Sınıf/şube öğrenci beyanıdır; resmî sınıf listeleri aktarılmamıştır. Sıralamalar ve gruplar hâlâ örnek veridir. Sunucu, ülke/şehir/okul/sınıf ilişkilerini ve grup katılım yetkisini yeniden doğrulamalı; sınıf kimliği okuldan bağımsız isim olarak kabul edilmemelidir. Okul/öğretmen doğrulaması ve gerçek hesap akışı ayrı hizmet işleridir.
