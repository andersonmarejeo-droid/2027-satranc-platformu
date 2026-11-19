## Android mağaza sağlayıcısı — 0.7.0

FirebaseChessService mevcut OnlineChallengeRepository, MatchRepository, OwnedMatchRepository ve MatchmakingRepository sözleşmelerini uygular. AppServices, Android mağaza bayrağıyla başlatılmış Firebase varsa bu adaptörü seçer; REST ve yerel adaptörler korunur. Anonim Auth yalnız 13+ yaş/veri onayından sonraki ilk çevrim içi eylemde başlar. Firestore transaction ile tek kullanımlı davet, kuyruk ve hamle uygulanır; sıradan snapshot dinleyicisi canlı güncelleme sağlar. Hamleler UCI geçmişinden OnlinePosition ile bağımsız yeniden oynatılır. Kurallar sahiplik/sıra/geçmiş/saat sınırlarını uygular, tam satranç yasallığını sunucuda denetlemez; maçlar puansızdır. Yerel profil/okul tercihleri buluta gönderilmez. Arkadaşlık, okul/grup puanları ve gerçek hesap kurtarma sonraki işlerdir.

Aşağıdaki REST sözleşmesi alternatif sunucu mimarisi olarak korunur; tüm adaptörlerin aynı anda aktif olduğu anlamına gelmez.
# Mimari

Feature-first yapı; her modülde domain, data ve presentation. Domain modelleri UI, ağ veya depolama paketlerine bağlı değildir. `AppServices` bağımlılıkları tek noktada birleştirir.

- `GameRules` → `LocalChessRules`: chess paketini UI'dan ayırır. `GameController` seçimi, hedefleri, son hamleyi ve tahta yönünü yönetir.
- `SettingsRepository` → `PreferencesSettingsRepository`: tema tercihi.
- `ChallengeRepository` → `LocalChallengeRepository`: en fazla 20 yerel davet, 128 bit rastgele kimlik ve 24 saat süre.
- `LeaderboardRepository` → `DemoLeaderboardRepository`: kapsam bazında örnek sıralama.
- `AuthIdentityProvider` → `ApiAuthRepository`: sağlayıcı JWT değişimlerini `/v1/auth/session` ile oyuncu kimliğine eşler; çıkışta sunucu oturumunu iptal eder ve kimlik sağlayıcısına devreder. REST sağlayıcı sözleşmesi korunur; Android mağaza sürümü aşağıdaki Firebase misafir adaptörünü kullanır.
- Auth, matchmaking, friendships, safety ve API için bağımsız sözleşmeler; okul, sınıf, grup ve turnuva modelleri.
- `ApiClient` → `RestApiClient`: `API_BASE_URL` varsa platform taşımasıyla JSON HTTPS istekleri; isteğe bağlı Bearer başlığı, 15 saniye sınırı ve kullanıcıya uygun hata türleri. Firebase başlatılmamışsa ve URL yoksa REST servisi oluşturulmaz; yerel demo kullanılır.
- `GuestProfileRepository` → `PreferencesGuestProfileRepository`: rastgele kurulum kimliği ve doğrulanmış görünen ad bu cihazda kalır; bu kayıt bir çevrim içi hesap değildir.
- `SafetyPreferencesRepository` → `PreferencesSafetyPreferencesRepository`: profil görünürlüğü, sıralamada görünme ve davet tercihleri tek sürümlü JSON değeriyle yerelde saklanır. Varsayılanlar özeldir/kapalıdır; değerler çevrim içi davranış açmaz.
- `MatchmakingRepository` → `ApiMatchmakingRepository`: oturum hazırsa REST bileti açar, GET ile iki saniyede bir durum izler ve iptal eder.
- `MatchRepository` → `ApiMatchRepository`: sunucu snapshot'ını (FEN, sıra, oyuncular, saat ve SAN geçmişi) alır; yasal UCI hamlesini beklenen `ply` ve tekil `Idempotency-Key` ile gönderir. `OnlineGameController` yalnız sunucu yanıtıyla tahtayı değiştirir, WebSocket olayında snapshot'ı yeniler ve dört saniyelik REST yedek yenilemesini sürdürür. Platforma özgü WebSocket taşıyıcıları tek kullanımlık stream-ticket ile açılır; tekrar bağlantı yeni bilet ve son olay sıra numarası kullanır.

Küçük eylemler repository'ye doğrudan gider; iş kuralları büyüdükçe domain use-case sınıfları eklenebilir. [Flutter mimari önerileri](https://docs.flutter.dev/app-architecture/recommendations) ve [Router rehberi](https://docs.flutter.dev/ui/navigation) temel alınmıştır.

## Canlı sürüm adımları

1. Hesaplar, oturum ve yaşa uygun veri/iletişim izinleri.
2. Sunucu tarafında yetkili hamle, saat ve maç sonucu; WebSocket push, beraberlik/terk ve iki oyunculu yeniden bağlanma doğrulaması.
3. Puan ve süre bazında eşleştirme kuyruğu.
4. Davet süresi ve tek sefer kabul işlemini sunucuda eşzamanlı güvenceye alma.
5. Okul/sınıf/öğretmen rolleri ve görünürlük izinleri.
6. Gerçek puan listeleri, grup ve turnuvalar.
7. Bildirme, engelleme, moderasyon ve yayına uygun hukuki metinler.

```text
GET  /v1/auth/session
DEL  /v1/auth/session
POST /v1/challenges
GET  /v1/challenges/{id}
POST /v1/challenges/{id}/accept
POST /v1/matchmaking
GET  /v1/matchmaking/{ticketId}
DEL  /v1/matchmaking/{ticketId}
GET  /v1/matches/{matchId}
POST /v1/matches/{matchId}/moves
POST /v1/matches/{matchId}/stream-ticket
GET  /v1/leaderboards?scope=...&scopeId=...
```

Makinece okunur sözleşme `docs/api/openapi.yaml`, WebSocket olayları `docs/api/WEBSOCKET.md` içindedir. Sunucu daveti adaptörü sözleşmedeki oluşturma ve bulma uçlarını kullanır; kimliği, dakika tabanlı süreyi ve HTTPS paylaşım adresini doğrular. `AppServices.create`, adaptöre yalnız API adresi ve oturum belirteci sağlayıcısı birlikte verilirse geçer; aksi durumda yerel davetler sürer. Sunucu ve kimlik sağlayıcısı henüz yoktur. WebSocket web istemcisinde Authorization başlığı taşıyamaz; bağlantı için kısa ömürlü, maça bağlı tek kullanımlık bilet gerekir. Tercih deposu kritik maç veya kimlik verisinin saklama yeri değildir.

Kimlik sağlayıcısı henüz seçilmedi; sağlayıcı, oturum belirtecini üretir ve `/v1/auth/session` oyuncu profilini doğrular. Sıralama uç noktası oturum ister. Okul/sınıf kapsamları ve oyuncu görünürlüğü sunucu tarafı izin ve veli/onay kurallarıyla korunmalıdır.

Gemini bir kimlik sağlayıcısı veya yetkili maç/veri sunucusu değildir; bu nedenle JWT oturumu, davet, eşleşme, hamle doğrulama ve kalıcı kullanıcı kayıtlarının yerine geçmez. İleride Gemini destekli satranç koçu eklenirse, uygulama ayrı bir AI servis arayüzünden kendi sunucusuna istek yollar; Gemini anahtarı sunucuda tutulur ve AI çıktısı hiçbir zaman hamle/saat/sonuç için otorite kabul edilmez. Kimlik ve canlı oyun servislerinden bağımsız, isteğe bağlı bir özellik olarak planlanır.

Kalan işler ve bağımlılıklar `docs/SPRINTS.md` içinde sıralanmıştır.

