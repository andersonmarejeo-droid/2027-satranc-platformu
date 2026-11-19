# Canlı maç WebSocket olayları

Bu olay sözleşmesi OpenAPI REST uçlarını tamamlar. Flutter istemcisi `match.sync` isteği ve sunucu olaylarını okuyabilir; hamle gönderimi REST `POST /moves` üzerinden yapılır. Gerçek hizmet yapılandırılmadıysa WebSocket açılmaz.

## Bağlantı

`wss://<API_HOST>/v1/matches/<matchId>/stream?ticket=<single-use-ticket>` adresine bağlanılır. İstemci önce `POST /v1/matches/{matchId}/stream-ticket` ile kısa ömürlü, yalnız o maça bağlı tek kullanımlık bilet alır; bağlantı ilk kullanımdan sonra aynı biletle tekrar kurulamaz. Tarayıcı WebSocket API'si özel Authorization başlığı gönderemediğinden aynı bilet her platformda kullanılır. Erişim belirteci URL sorgusuna konmamalıdır. Sunucu oyuncunun maça katılımını her bağlantıda doğrular. Bilet URL'de taşınsa da istemci bunu kaydetmez veya günlüklemez.

Her JSON zarfı `type`, `matchId`, `sequence` ve `serverTime` alanlarını taşır. `sequence` sunucu tarafında artar; eski veya yinelenmiş olaylar yok sayılır. Bağlantı kurulunca istemci `{"type":"match.sync","lastSequence":N}` yollar. Bağlantı koparsa ekran REST maç görünümünü yeniler, istemci yeni bir tek kullanımlık bilet alıp son görülen sıra numarasından devam eder.

## Sunucudan istemciye

| type | Ek alanlar | Anlamı |
|---|---|---|
| `match.snapshot` | `match` | İlk durum veya yeniden bağlanma özeti |
| `move.accepted` | `ply`, `uci`, `san`, `fen`, `turn`, `clocks` | Sunucunun doğruladığı hamle |
| `clock.updated` | `clocks` | Sunucu saatleri |
| `draw.offered` | `playerId` | Beraberlik teklifi |
| `match.ended` | `result`, `reason`, `ratingChanges` | Sonuç: mat, terk, süre, beraberlik |
| `error` | `code`, `message`, `retryable` | İsteğin neden reddedildiği |

## İstemciden sunucuya

| type | Ek alanlar |
|---|---|
| `move.submit` | `clientMoveId`, `expectedPly`, `uci` |
| `draw.offer` | `clientActionId` |
| `draw.respond` | `clientActionId`, `accepted` |
| `match.resign` | `clientActionId` |
| `match.sync` | `lastSequence` |

Hamle, oyuncu kimliği, aktif sıra, yasal satranç konumu ve `expectedPly` sunucuda doğrulanır. İstemci bildirilen saatleri veya sonuçları otorite kabul etmez. Her eylemdeki kimlik aynı isteğin ağ tekrarını güvenli kılar.
