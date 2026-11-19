# Maç ve tahta

Yerel pratik `GameRules` / `LocalChessRules` ile çalışır. Çevrim içi oyun, ayrı `MatchRepository` / `ApiMatchRepository` ve `OnlineGameController` yolunu kullanır; sunucunun FEN konumu görüntülenir, istemci yasal kare hedeflerini hesaplar ve UCI hamlesini mevcut `ply` ile gönderir. Sunucu kabul etmeden yerel tahta değiştirilmez. `409` durumunda güncel snapshot yüklenir.

Hamle istekleri OpenAPI sözleşmesinin zorunlu `Idempotency-Key` başlığını 128 bitten rastgele bir değerle taşır. Maç snapshot'ı oyuncu kimliklerini, FEN'i, son hamleyi, SAN geçmişini, sunucu saat görüntüsünü ve sonucu içerir. Tek kullanımlık stream-ticket Android ve tarayıcı WebSocket taşıyıcılarını açar. İstemci `match.sync` ile sıra numarasını bildirir, eski olayları atar, yenilerinde REST snapshot'ını yükler ve bağlantı kesilince yeni biletle yeniden bağlanır.

Eşleşme ve maç akışları ancak `API_BASE_URL` ile access-token sağlayıcısı birlikte `AppServices.create` çağrısına verildiğinde seçilir. `main()` henüz gerçek kimlik sağlayıcısına bağlı değildir. Canlı sunucu, akıcı saat sunumu ve iki oyunculu uçtan uca doğrulama beklemededir.
