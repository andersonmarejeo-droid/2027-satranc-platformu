# Davet ve paylaşım — 0.7.0

Android mağaza derlemesi Firebase ile https://satranc-platformu.web.app/challenge/<id> oluşturur. Kimlik kriptografik rastgele 20 bayt / 40 hex karakter; davet 24 saat geçerli. İlk farklı oyuncu atomik işlemle katılır. Davet sahibi arkadaşını bekler; üçüncü kişi katılmış maçı okuyamaz.

WhatsApp butonu https://wa.me/?text=... üzerinden Türkçe metin ve HTTPS davetiyle mesaj taslağı açar. Kullanıcı alıcıyı seçip gönderir; uygulama otomatik mesaj göndermez ve rehberi okumaz. Açılamazsa bağlantı kopyalanabilir. Davet ekranına HTTPS bağlantısı veya kimlik yapıştırılabilir.

## Android App Links

Manifest autoVerify, HTTPS host satranc-platformu.web.app ve /challenge/ yolunu içerir. Hosting /.well-known/assetlinks.json kalıcı com.zpgames.satrancplatformu paketi için upload ve etkin Play sertifikalarını listeler. /challenge/** webde challenge.html sayfasını açar; uygulamada açma düğmesi chessplatform:/challenge/<id> alternatifi sunar. GoRouter /challenge/:id yolu korunur. Web sayfası maç verisi okumaz.

İki cihazda güncel 0.7.0+ Android mağaza paketi gerekir. Çevrim içi özellik 13+ ve veri açıklaması/onayıyla açılır. Uygulama Play'de herkese henüz açık olmadığı için sahte mağaza indirme bağlantısı sunulmaz.

18 canlı sıradan Firebase istemci kontrolü geçti. Paylaşım URI'si ve davet ekranları Flutter testlerinden geçti. Fiziksel telefonda soğuk/açık uygulama App Links ve WhatsApp alıcı akışı henüz doğrulanmadı; USB kontrolde telefon yoktu. Emülatör kullanılmaz.

## Yerel önizleme ve iOS

Firebase bayrağı olmayan yerel sürüm chessplatform:/challenge/<id> deneme bağlantısı üretir; yalnız oluşturulduğu kurulumda açılır ve ekranda deneme olarak belirtilir. iOS özel URL şeması kaynakları vardır; iOS build/Universal Links Windows'ta doğrulanmadı. Gerçek Apple Team ID, apple-app-site-association ve Associated Domains gerekir.

[Flutter App Links](https://docs.flutter.dev/cookbook/navigation/set-up-app-links) · [Android App Links](https://developer.android.com/training/app-links/about).
