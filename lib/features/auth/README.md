# Kimlik ve oturum

`domain/auth_repository.dart` sağlayıcıdan bağımsız oyuncu kimliği/oturum sözleşmesini ve JWT sağlayıcı sınırını tanımlar. `data/api_auth_repository.dart`, sağlayıcı token değişiminde `/v1/auth/session` yanıtını oyuncu kimliğine dönüştürür; giriş sağlayıcıya, çıkış sağlayıcı oturumunun kapatılması ve sunucu oturumunun iptaline delege edilir. Gerçek giriş sağlayıcısı henüz bağlanmadı; `main()` misafir modunda başlar.

Bağlanacak sağlayıcı kısa ömürlü JWT erişim belirtecini üretmeli; sunucu `/v1/auth/session` çağrısında imza, issuer, audience ve süreyi doğrulayıp uygulama oyuncu kimliğini döndürmelidir. Sağlayıcı token'ları `SharedPreferences` içine kopyalanmamalıdır. Çıkış akışı sağlayıcı oturumunu kapatmalı ve mümkünse `DELETE /v1/auth/session` ile sunucu oturumunu iptal etmelidir.

Gemini API bir hesap/oturum sağlayıcısı değildir. İleride AI koçu için kullanılırsa bu kimlik sözleşmesinden ayrı, sunucu üzerinden çalışan isteğe bağlı bir özellik olmalıdır. Canlılık durumu ve dış bağımlılıklar ana README ile `docs/SPRINTS.md` içinde tutulur.
