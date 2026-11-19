# Sınıf ve grup kapasitesi — 0.8.1+14

Her sınıf ve grup en fazla **20 kalıcı hesap üyesi** kabul eder. Ülke, şehir ve okulda bu sınır yoktur. Misafirlerin yerel seçimleri sunucuda yer ayırmaz. Sıralamaya katılım ayrı ve isteğe bağlıdır; sıralamadan çıkmak takım üyeliğini silmez.

Katılım, ayrılma ve profil yedeği aynı Firestore işlemiyle yazılır. `smallTeams` yalnız takım türü/kimliği, 0–20 sayacı ve tarih içerir. `smallTeamMembers` oyuncuya özel üyelik belgeleridir; diğer üyelerin belgeleri okunamaz. Sunucu kuralları hem sayaç değişimini hem aynı oyuncunun üyelik/profil değişimini denetler. Arayüzü değiştiren bir istemci de 21. üyeyi kabul ettiremez.

Tekrarlanan kayıt sayacı artırmaz. Dolu takıma geçiş eski üyeliği korur; çoklu seçimlerden biri doluysa işlem bütünüyle reddedilir. Ayrılma ve hesap silme boş yer açar. Firestore erişim bütçesi için bir işlemde en fazla altı üyelik değişimi yapılır; hesap silme gerekirse küçük partilerle tamamlanır. Okul/sınıf üyeliği kullanıcı beyanıdır; kurum tarafından doğrulanmış değildir.

Canlı HTTPS istemci kontrolü 30 doğrulamadan geçti: sınıfta ve grupta 19→20 eşzamanlı yarış, 21. üyeye sunucu reddi, tekrar kayıt, özel üyelik erişimi, atomik takım değişimi, boş yerin yeniden doldurulması, 21 oyuncuya açık üst topluluklar, altı üyeliğin birlikte eklenip silinmesi. Geçici hesaplar ve veriler temizlendi. Bu hesaplar Play test katılımcısı değildir.

İlk Node HTTP/2 denemesi bağlantı hatası verdi; tamamlanan canlı test sıradan oyuncu yetkili Firestore Lite HTTPS işlemleriyle yapıldı. Firebase Spark planı ve sertifika doğrulaması korundu; emülatör açılmadı.
