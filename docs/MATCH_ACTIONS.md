# Beraberlik, rövanş ve hazır mesajlar — 0.7.1

Oyunun altındaki **Beraberlik teklif et** düğmesi çevrim içi rakibe bir teklif gönderir. Rakip kabul eder veya **Devam et** ile reddeder. Teklifi gönderen kişi kendi teklifini kabul edemez. Sonraki hamle teklifi düşürür; kabul edilen beraberlik saatleri durdurur ve yeni hamleleri engeller.

Maç bitince **Rövanş oyna** açılır. Rakip kabul edince iki oyuncu aynı sürelerle yeni bir maça geçer. Rövanş daveti yalnız önceki iki katılımcı içindir; bağlantıya sahip üçüncü bir kullanıcı bile bu daveti okuyamaz veya kabul edemez. Normal WhatsApp davetlerinin ilk kabul eden oyuncuya açılma davranışı korunur.

Maç sonunda **Tebrikler!**, **İyi oynadın!**, **Güzel oyundu.** ve **Teşekkürler!** gönderilebilir. Serbest metin, telefon/e-posta ve sohbet kutusu bulunmaz. Her maç toplam 12 hazır mesajla sınırlıdır; önceki mesajlar değiştirilemez. Hazır mesaj kodu, gönderenin rastgele kimliği ve zaman damgası aynı özel maç belgesinde tutulur. Maç silindiğinde mesajları da silinir. Verilerimi sil işlemi, alıcıya gönderilmiş bekleyen özel rövanş davetlerini de temizler.

Çevrim içi maçın canlı dinleyicisi maç sonunda açık kalır; mesajlar ve rövanş teklifleri hamle sayısı değişmeden eşitlenir. REST adaptörü bu özellikler için bir servis sunmadığında sahte gönderim düğmesi gösterilmez.

Aynı cihazdaki iki kişilik oyunda beraberliği rakip telefonda kabul eder. Bilgisayara karşı alıştırmada kullanıcı oyunu beraberlikle sonlandırmayı onaylar. Yerel rövanş önceki maçı geçmişe kaydeder. Yerel kısa mesajlar yalnız aynı cihazdaki oyuncuya gösterilir; bilgisayara veya sunucuya gönderildiği iddia edilmez.

**Maç seçenekleri** tam ekrandaki düğmeden de açılır. Hamle ipuçları varsayılan olarak kapalıdır; eski açık tercihler bir kez kapalı duruma taşınır. Yerel alıştırmada isteğe bağlı açılabilir; çevrim içi maçta her zaman gizlidir. Şahı tehdit altında bırakan hamle dahil standart satranç kuralları korunur.

Ferah Turkuaz varsayılan palettir; turkuaz yeşil, sıcak turuncu ve açık gri yüzeyler kullanır. Klasik Orman paleti seçilebilir. Açık/koyu/sistem tercihi ayrı saklanır. Siyah-beyaz tahta ve taşlar 2D, üstten ve 3D görünümlerde seçilebilir.

Doğrulama: 121 uygulama testi, son kaynaklardaki 4 odaklı kontrol ve 7 telefon görünümü. Spark projesindeki canlı testler ve paketlerin son doğrulaması docs/VERIFICATION.md içinde kaydedilir. Telefon görünümü başsız Flutter çıktısıdır; emülatör veya fiziksel cihaz testi değildir.

Maçlar puansızdır. Firestore katılımcı/sıra/geçmiş/saat kurallarını uygular; satranç yasallığı istemcilerde yeniden oynatılır. Serbest sohbet ve yetkili rekabetçi sunucu motoru bu sürümün kapsamı dışındadır.
