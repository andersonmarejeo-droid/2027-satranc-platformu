import {readFileSync, writeFileSync, statSync, existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
const read = path => readFileSync(path, 'utf8');
const sha = path => createHash('sha256').update(readFileSync(path)).digest('hex').toUpperCase();
const version = '0.8.2+15', recordedAt = new Date().toISOString();
const full = Number(read('releases/flutter-082-tests.log').match(/\+(\d+): All tests passed!/u)?.[1]);
const timing = JSON.parse(read('releases/online-timing-082-verification.json'));
const analysis = read('releases/flutter-082-analysis.log');
const packageLog = read('releases/android-082-package-verification.log');
if (full !== 151 || !analysis.includes('No issues found!') || timing.passed !== 30 || timing.failure || !timing.fixtureDataAndAccountsCleaned) throw new Error('Application/timing verification evidence incomplete');
if (!packageLog.includes("versionCode='15' versionName='0.8.2'") || !packageLog.includes('jar verified.') || !packageLog.includes('Verified')) throw new Error('Signed package evidence incomplete');
if (!read('releases/firebase-082-rules-deploy.log').includes('Deploy complete!') || !read('releases/firebase-082-hosting-deploy.log').includes('Deploy complete!')) throw new Error('Deployment evidence incomplete');
const web = JSON.parse(read('releases/firebase-082-public-web-verification.json'));
if (web.checks.length !== 4 || web.checks.some(c => c.status !== 200 || !c.matchesLocal)) throw new Error('Public web verification incomplete');
const desktop = {apk: 'C:/Users/GiresuN/Desktop/Satranc-Platformu-0.8.2.apk', aab: 'C:/Users/GiresuN/Desktop/Satranc-Platformu-0.8.2.aab'};
const files = {apk: 'releases/satranc-platformu-0.8.2+15.apk', aab: 'releases/satranc-platformu-play-0.8.2+15.aab'};
const artifacts = {};
for (const type of ['apk', 'aab']) {
  artifacts[type] = {path: files[type], bytes: statSync(files[type]).size, sha256: sha(files[type])};
  if (sha(desktop[type]) !== artifacts[type].sha256) throw new Error('Desktop export mismatch');
}
const phone = existsSync('releases/android-082-device-check.json') ? JSON.parse(read('releases/android-082-device-check.json')) : null;
const installed = phone?.installedVersion === version && phone?.thisVersionInstalled === true;
const status = JSON.parse(read('store/release-status-081.json'));
status.recordedAt = recordedAt;
Object.assign(status.application, {versionName: '0.8.2', versionCode: 15});
Object.assign(status.firebase, {rulesSha256: sha('firebase/firestore.rules'), rulesDeployment: 'successful', hostingDeployment: 'successful', privacyUpdatedForVersion: '0.8.2', lastVerifiedAt: recordedAt});
status.verification = {
  analysis: 'passed', fullFlutterTestsPassed: full, liveTimingChecksPassed: timing.passed,
  liveFirebaseChecksPassed: timing.passed, liveFirebaseChecksFromVersion: version,
  timing, firebaseLogs: ['releases/online-timing-082-live.log', 'releases/firebase-082-rules-deploy.log'],
  successfulFixtureDataAndAccountsCleaned: true,
  previousCapacityAndCompetitionChecks: {version: '0.8.1+14', capacity: 30, competition: 47, rerunFor082: false},
  previousLiveMatchChecks: {version: '0.8.0+13', passed: 38, rerunFor082: false},
  publicWebVerification: web,
  apkSignatureVerified: true, aabSignatureVerified: true, androidPackageAndVersionVerified: true,
  embeddedSchoolCatalogMatchesSource: true, embeddedPrivateSchoolCatalogMatchesSource: true, embeddedSchoolLicensePresent: true,
  emulatorStarted: false, thisVersionInstalledOnPhysicalPhone: installed, currentPhysicalPhoneVerification: phone,
  previousPhysicalPhoneVerification: {version: '0.8.1+14', installed: true, launchRequestSuccessful: true},
  twoPhysicalPhonesWhatsAppAppLinkTest: 'pending', detailedPhysicalUiAndPerformanceVerified: false,
};
status.artifacts = artifacts;
status.desktopExports = {checksumsVerified: true, apkPath: desktop.apk, aabPath: desktop.aab};
status.playConsole.localVersionNotUploaded = {versionCode: 15, versionName: '0.8.2', aabPath: files.aab};
status.onlineTimingPolicy = {defaultMinutesPerPlayer: 10, primaryMinutes: [10,15,30,60], turnLimitSeconds: 180, newOnlineMatchesOnly: true, legacyMatchesPreserved: true, backendEnforced: true, earlierTotalClockWins: true, rankingQuorumChanged: false};
status.featuresAddedIn082 = ['longer-primary-time-controls', 'ten-minute-default-and-preference-migration', 'server-enforced-three-minute-online-turn-limit', 'turn-countdown-and-inactivity-outcome', 'rule-aware-matchmaking-and-whatsapp-description', 'late-expired-move-refresh'];
status.currentLimits = status.currentLimits.filter(s => !s.startsWith('0.8.1 was installed') && !s.startsWith('0.8.1 has not been installed'));
status.currentLimits.push('0.8.2+15 signed APK/AAB prepared locally; Play Console still has the previously recorded 0.8.1+14 internal release and closed draft. Dedicated review account credential disclosure approval remains pending.');
status.currentLimits.push('Inactivity match outcome uses the existing client refresh; server rejects late moves. Community points retain both-player agreement and at least four plies; an absent opponent can delay point confirmation.');
writeFileSync('store/release-status.json', JSON.stringify(status, null, 2) + '\n');
writeFileSync('releases/release-082-receipt.json', JSON.stringify({recordedAt, version, fullTests: full, liveTimingChecks: timing.passed, artifacts, desktop, phone, playVersionUploaded: false}, null, 2) + '\n');
const phoneText = installed ? '0.8.2+15 USB ile fiziksel telefona kuruldu; sürüm, açılış isteği ve çalışan uygulama doğrulandı. Uygulama verileri silinmedi.' : '0.8.2+15 için fiziksel telefona kurulum doğrulanmadı; telefon kaydı varsa releases/android-082-device-check.json içinde.';
const delivery = `## Teslim ve doğrulama\n\n[Play AAB](${files.aab}) ve [telefon APK](${files.apk}) **0.8.2+15** olarak mevcut upload imzasıyla derlendi. Paket kimliği, imzalar, gömülü kataloglar/lisans ve masaüstü SHA256 eşitliği doğrulandı.\n\nKaynak analizi temiz; **${full} uygulama testi** ve gerçek üç dakikayı bekleyen **${timing.passed} canlı sunucu kontrolü** geçti. Geçici test verileri/hesapları temizlendi. Süre kuralı ve açıklaması Spark planına uygulandı. Önceki 0.8.1'in 30 kapasite + 47 hesap/puan kontrolü tarihsel kanıttır; bu turda yeniden çalıştırılmış sayılmaz. Emülatör açılmadı. ${phoneText} Ayrıntılı telefon arayüzü/performansı ve iki telefonla WhatsApp kontrolü bekler.\n\n**0.8.2 henüz Play Console'a yüklenmedi.** Son kayıt: dahili testte 0.8.1+14 kullanılabilir, Alpha 0.8.1+14 taslağı ayrı inceleme hesabı bilgilerini aktarma onayı bekler. Kapalı testin gerçek katılım/14 gün gereksinimi tamamlanmış değildir.\n\nHer sınıf/grup en fazla 20 kalıcı hesap üyesi kabul eder. [Kapasite](docs/SMALL_TEAMS.md) · [Süre kuralları](docs/ONLINE_TIMING.md).\n\n`;
let readme = read('README.md').replace('Satranç Platformu — 0.8.1+14', 'Satranç Platformu — 0.8.2+15');
readme = readme.replace('- Süresiz yerel oyun, 1/2/3/5 dakika ve uzun/ek saniyeli seçeneklerin sade anlatımı.', '- Süresiz yerel oyun; oyuncu başına varsayılan 10 dakika, ana 10/15/30/60 seçimleri, diğer kısa/uzun/ek saniyeli süreler. Yeni çevrim içi maçlarda 3 dakika hamlesizlik kaybı, hamle geri sayımı ve açık sonuç mesajı. Eski maçların süre kuralı korunur.');
readme = readme.replace(/## Teslim ve doğrulama[\s\S]*?(?=\[Doğrulama\])/u, delivery);
writeFileSync('README.md', readme);
const verification = `## Güncel 0.8.2+15 — 5 Ekim 2026\n\n- Oyuncu başına varsayılan 10 dakika, ana 10/15/30/60 seçimleri; diğer süreler ve süresiz yerel pratik korundu.\n- Yeni çevrim içi davet/maçlarda 180 saniye hamlesizlik rakibin galibiyetidir. Son kabul edilmiş hamle zamanı esas alınır; toplam saat erken biterse önce o geçerlidir. Davet/maç kuralı değiştirilemez, eşleştirme ayrı kuyruğu kullanır, eski maçlarda süre kuralı korunur. Ayrıntı docs/ONLINE_TIMING.md.\n- Temiz kaynak analizi, ${full} uygulama testi ve ${timing.passed} canlı sıradan istemci sunucu kontrolü geçti. Gerçek üç dakika beklendi; test belgeleri/hesapları temizlendi. Kanıt releases/online-timing-082-verification.json. Önceki 77 kapasite/puan kontrolü bu sürümde yeniden koşulmadı.\n- Firestore kuralları ve web açıklaması/gizlilik Spark planına uygulandı. İmzalı APK/AAB, paket 15/0.8.2, gömülü katalog/lisans ve masaüstü kopyaları doğrulandı. APK SHA256 ${artifacts.apk.sha256}; AAB SHA256 ${artifacts.aab.sha256}.\n- Emülatör açılmadı. ${phoneText} Ayrıntılı dokunma/performans ve iki telefon daveti henüz doğrulanmadı.\n- 0.8.2 Play'e yüklenmedi; önceki Play 0.8.1 kanıtı aşağıdadır. İnceleme hesabı bilgilerinin Google'a aktarımı için özel onay bekler.\n- Topluluk puanları en az dört yarım hamle ve iki katılımcı onayını korur; rakip kapalıysa sonuç görünse bile puan mutabakatı bekleyebilir.\n\n`;
for (const path of ['docs/VERIFICATION.md', 'docs/PLAY_FIREBASE_SETUP.md']) {
  const old = read(path).replace(/^## Güncel 0\.8\.2\+15[\s\S]*?(?=## Güncel 0\.8\.1\+14)/u, '');
  writeFileSync(path, verification + old);
}
console.log(JSON.stringify({version, fullTests: full, liveTimingChecks: timing.passed, phoneInstalled: installed, artifacts, desktop}));
