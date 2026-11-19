import {readFileSync, writeFileSync, existsSync, copyFileSync} from 'node:fs';
const read = path => readFileSync(path, 'utf8');
if (!existsSync('store/release-status-081.json')) copyFileSync('store/release-status.json', 'store/release-status-081.json');
let challenge = read('store/site/challenge.html');
challenge = challenge.replace('İkinizde de güncel 0.7.0 veya sonraki sürüm kurulu olmalıdır.', 'İkinizde de güncel 0.8.2 veya sonraki sürüm kurulu olmalıdır.');
if (!challenge.includes('0.8.2 ile oluşturulan')) challenge = challenge.replace('<p>Uygulama henüz test', '<p>0.8.2 ile oluşturulan yeni maçlarda sırası gelen oyuncu 3 dakika hamle yapmazsa rakibi kazanır. Her hamle bu sayacı yeniler; toplam oyun saati ayrıca işler. Eski maçların süre kuralı korunur.</p><p>Uygulama henüz test');
writeFileSync('store/site/challenge.html', challenge);
let site = read('store/site/index.html');
site = site.replace('0.7.0 Android sürümünde', 'Android sürümünde')
  .replace('0.7.1 sürümünde beraberlik', 'Beraberlik')
  .replace('Serbest sohbet bulunmaz; maçlar sıralama puanını değiştirmez.', 'Serbest sohbet bulunmaz. Doğrulanmış kalıcı hesaplar ayrı seçimle topluluk sıralamasına katılabilir. Sonuç iki uygulamada onaylanır; puanlar resmî Elo değildir.')
  .replace('Okul, sınıf ve grup sıralamaları uygulamada örnek içerik olarak gösterilir.', 'Okul, sınıf ve grup sıralamaları seçtiğiniz topluluğa göre gösterilir. Her sınıf ve grup en fazla 20 kalıcı hesap üyesi kabul eder.');
if (!site.includes('Oyuncu başına 10 dakika')) site = site.replace('<footer>', '<p>Oyuncu başına 10 dakika varsayılandır; 15, 30 ve 60 dakika da seçilebilir. 0.8.2 ile oluşturulan yeni çevrim içi maçlarda sırası gelen oyuncu 3 dakika hamle yapmazsa rakibi kazanır. Hamle sonrası sayaç yenilenir; toplam saat önce biterse saat sonucu geçerlidir.</p><footer>');
writeFileSync('store/site/index.html', site);
console.log('Public game description and historical 0.8.1 release record prepared.');
