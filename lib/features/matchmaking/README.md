# Rakip eşleştirme

domain: modeller ve bağımsız servis sözleşmeleri.
data: repository adaptörleri ve veri kaynakları.
presentation: ekranlar ve görünüm durumu.

`ApiMatchmakingRepository` OpenAPI'deki POST/GET/DELETE bilet uçlarını kullanır. Kuyruk durumu iki saniyede bir sorgulanır; WebSocket bağlantısı daha sonra aynı repository sözleşmesinin arkasına alınabilir.

İstemci adaptörü yalnız `API_BASE_URL` ve oturum belirteci sağlayıcısı birlikte verildiğinde seçilir. Diğer kurulumlarda çevrim içi düğmesi gösterilmez ve yerel iki kişilik pratik çalışır. Eşleşme bulununca maç kimliğiyle sunucu yetkili tahtası açılabilir; ekran FEN/saat/oyuncu snapshot'ını okur ve hamleleri beklenen sıra numarasıyla sunucuya yollar. WebSocket gelene kadar etkin maç REST ile dört saniyede bir yenilenir. Gerçek API ve kimlik sağlayıcısı henüz yapılandırılmamıştır.

Gerçek rakip araması 15 saniye sonuç vermezse ekranda açık bir bilgisayar rakibi seçeneği görünür. Kullanıcı beklemeyi sürdürebilir veya mevcut yerel bilgisayar motoruyla hemen başlayabilir. Fallback maçı "Gerçek rakip bulunamadı" ve "Bilgisayar antrenmanı · sıralamaya eklenmez" olarak etiketlenir; bot gerçek kişi gibi sunulmaz, çevrim içi sıralamaya ve oyuncu istatistiklerine yazılmaz. Bekleyen gerçek eşleşme bileti bilgisayar maçına geçerken iptal edilir.
