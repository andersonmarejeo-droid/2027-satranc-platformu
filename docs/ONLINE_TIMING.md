# Oyun süreleri — 0.8.2+15

Yeni oyun ve davetlerde varsayılan süre **her oyuncu için 10 dakika**. Ana seçimler 10, 15, 30 ve 60 dakika; Diğer süreler altında 1/2/3/5, 90/120 dakika ve mevcut ek saniyeli seçenekler var. Yerel süresiz pratik korunur. Eski kısa oyun tercihi yeni varsayılana taşınır; bu sürümde bilerek yeniden seçilen kısa süre hatırlanır. Kaydedilmiş yerel maçın süresi değiştirilmez.

Yeni çevrim içi davetler ve maçlar `turnLimitSeconds: 180` taşır. Sırası gelen oyuncu üç dakika hamle yapmazsa rakibi kazanır. Süre ilk hamlede sunucunun maç oluşturma zamanından, sonraki hamlelerde sunucunun son kabul ettiği hamleden başlar. Her kabul edilmiş hamle karşı tarafın hamle sayacını yeniler. Toplam oyun saati daha önce biterse saat kaybı geçerlidir. Ekranı açmak, bağlantı yoklaması veya beraberlik teklifi süreyi yenilemez. Bu, uygulamanın çevrim içi maç kuralıdır; standart turnuva zaman kuralı olarak sunulmaz.

Davet ekranı, WhatsApp mesaj taslağı ve maç ekranı bu kuralı açıklar. Maç ekranında bu hamle için kalan süre gösterilir; hamlesizlik halinde kazanan ve neden görünür. Bitmiş maçın toplam saatleri ilk dolan sınırda donar. Beraberlik kabulü veya tahta üzerinde bitmiş maç sonradan hamlesizlik sonucuna dönüşmez.

Firestore, davet ve maçın aynı süre kuralını taşımasını, bu kuralın değiştirilememesini, geç hamle/beraberlik girişimlerinin reddini ve doğru hamlesizlik kazananını denetler. Yeni eşleştirme kuyruğu `dakika_ekSaniye_180` adını kullanır. Eski maç/davetlerde alan yoksa veya 0 ise yalnız mevcut toplam saat geçerlidir; sürmekte olan maçlara yeni kural eklenmez.

Ücretsiz Spark planı kullanılır; ücretli arka plan işlevi eklenmedi. Ekrandaki sonuç mevcut istemci yenilemesinde hesaplanır; sunucu geç hamleyi kendi zamanıyla reddeder. Sıralama puanları mevcut iki katılımcı onayı ve en az dört yarım hamle koşuluyla verilir. Rakip uygulamayı kapatmışsa maç sonucu görünür, puan için karşılıklı onay beklenebilir. Sunucu burada tam satranç motoru çalıştırmaz; istemciler hamleleri bağımsız doğrular.

Kanıt: `test/online_match_timing_test.dart`, `test/match_actions_test.dart`, `releases/flutter-082-tests.log`, `releases/online-timing-082-verification.json`, `releases/firebase-082-rules-deploy.log`. Canlı kontrol betiği `tool/verify_online_timing_firebase.mjs` sıradan misafir hesaplarıyla gerçek üç dakikayı bekler, yönetici erişimiyle zaman damgası üretmez; yalnız kendi geçici belgeleri ve hesapları silinir. Önceki sürümlerin kapasite/puan testleri tarihsel kanıttır.
