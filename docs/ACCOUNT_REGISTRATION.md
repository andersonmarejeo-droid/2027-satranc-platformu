# Kayıt ve doğrulama — 0.8.3+16

Hesabım sayfasında başlık, seçim ve gönderme düğmesi **Kayıt ol**. Giriş yap seçeneği ayrı kalır. Şifre açıklaması ve yerel kontrol, canlı Firebase projesinin zorunlu minimumu olan **12 karakter** ile uyumludur. Başarısız kayıtta parola yeniden denemek için formda kalır; başarılı kayıtta temizlenir.

## Kayıt sorununun nedeni ve düzeltmesi

E-posta gizlilik koruması açık projede eski e-posta/parola bağlama çağrısı `OPERATION_NOT_ALLOWED` döndürdü. [Google'ın resmî açıklaması](https://docs.cloud.google.com/identity-platform/docs/admin/email-enumeration-protection?hl=en), misafir ID token'ıyla `accounts:signUp` kullanılmasını istiyor. Koruma kapatılmadı; Firebase ayarları veya erişim kuralları gevşetilmedi.

Yeni yöntem misafir token'ını, e-postayı ve parolayı HTTPS ile bu uç noktaya gönderir. Dönen UID, mevcut misafir UID'siyle eşleşmelidir. Ardından aynı e-posta/parolayla **aynı hesaba** SDK girişi yapılır ve token yenilenir. Yalnız misafir token'ını yenilemek, kalıcı hesap görünmesine rağmen `sign_in_provider=anonymous` bırakıyordu; bu durum profil yedeğine erişimi reddediyordu. Canlı normal istemci testi bu davranışı ve yeni `password` oturumunu doğruladı. Yeni oyuncu kimliği oluşturulmaz; token/parola kaydedilmez veya günlüklenmez.

Sunucu kaydı kabul ettikten sonra oturum açılamazsa mesaj, kaydın oluştuğunu ve **Giriş yap** ile devam edileceğini belirtir. Kayıtlı e-posta, geçersiz adres, şifre şartı, hizmet yapılandırması ve bağlantı hataları ayrı anlaşılır mesajlardır; her hata internet sorunu diye gösterilmez.

## E-posta ve profil yedeği

Doğrulama e-postası isteği Türkçe olarak, profil yedeğinden önce gönderilir. İki işlem bağımsızdır: 20 üyeyle dolu sınıf/grup veya başarısız profil yedeği, doğrulama isteğini engellemez. E-posta isteğinin başarısız olması hesabı veya yedeği geri almaz; **Yeniden gönder** görünür. Başarılı bir gönderimden sonra bir dakika yeniden gönderme aralığı uygulanır. Profil yedeği bekliyorsa **Şimdi yedekle** ile tekrar denenebilir. Topluluk sıralaması hâlâ e-posta doğrulaması ve ayrı seçim gerektirir.

**Gönderim isteğinin kabulü, gelen kutusuna teslim kanıtı değildir.** Uygulama spam klasörünü kontrol etmeyi açıkça söyler. Bu turda hiçbir gerçek kişiye e-posta gönderilmedi; gerçek gelen kutusu teslimi ve fiziksel telefondaki yeni kayıt ekranı henüz doğrulanmadı.

## Kanıt

- `test/account_registration_test.dart`: aynı UID, doğru oturum, sunucu hata kodları, kayıt sonrası oturum açma hatası, dolu sınıf, başarısız yedek, e-posta hatası/yeniden gönderme, 12 karakter kontrolü, küçük ekran hesabına geçiş testleri.
- `tool/verify_email_registration_firebase.mjs`: sıradan istemciyle geçici `example.invalid` hesabı; gerçek Firebase'de kayıt/oturum/özel yedek için 10 kontrol. Test verisi ve hesabı silindi. Yönetim erişimi yalnız mevcut ayarları salt okunur incelemek için kullanıldı; hesap doğrulama atlatılmadı.
- `releases/registration-083-live-verification.json`: sanitizasyon yapılmış sonuçlar. Gerçek posta teslimi test edilmediği ayrı alandır. Önceki süre/kapasite kanıtları bu kayıt testleriyle karıştırılmaz.

Ücretsiz Spark planı korunur. Emülatör başlatılmaz. Yeni ikon seçeneği 04 tasarım önerisi olarak kaydedildi; mevcut uygulama simgesi değiştirilmedi.
