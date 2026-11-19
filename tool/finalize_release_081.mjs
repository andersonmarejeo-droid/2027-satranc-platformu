import {readFileSync, writeFileSync, statSync, existsSync, copyFileSync} from 'node:fs';
import {createHash} from 'node:crypto';

const read = p => readFileSync(p, 'utf8');
const sha = p => createHash('sha256').update(readFileSync(p)).digest('hex').toUpperCase();
const full = Number(read('releases/flutter-081-tests.log').match(/\+(\d+): All tests passed!/u)?.[1]);
const targeted = Number(read('releases/flutter-081-membership-tests.log').match(/\+(\d+): All tests passed!/u)?.[1]);
const capacity = JSON.parse(read('releases/small-team-081-verification.json'));
const competition = read('releases/firebase-081-competition-verification.log');
const packageLog = read('releases/android-081-package-verification.log');
if (full !== 143 || targeted !== 2 || !read('releases/flutter-081-analysis.log').includes('No issues found!') || capacity.passed !== 30 || !/"passed"\s*:\s*47/u.test(competition) || !packageLog.includes('jar verified.')) {
  throw new Error('Final verification evidence is incomplete');
}
const play = JSON.parse(read('releases/play-081-result.json'));
if (play.internalTest.versionCode !== 14 || play.internalTest.state !== 'available_to_internal_testers') throw new Error('Internal test publication is not verified');
const inventory = JSON.parse(read('releases/small-team-inventory.json'));
const publicWeb = JSON.parse(read('releases/firebase-081-public-web-verification.json'));
if (publicWeb.checks.length !== 3 || publicWeb.checks.some(c => c.status !== 200)) throw new Error('Public deployment verification incomplete');
const phone = existsSync('releases/android-081-device-check.json') ? JSON.parse(read('releases/android-081-device-check.json')) : null;
const phoneInstalled = phone?.installedVersion === '0.8.1+14' && phone?.thisVersionInstalled === true;
const recordedAt = new Date().toISOString();
const desktop = {apk: 'C:/Users/GiresuN/Desktop/Satranc-Platformu-0.8.1.apk', aab: 'C:/Users/GiresuN/Desktop/Satranc-Platformu-0.8.1.aab'};
const files = {apk: 'releases/satranc-platformu-0.8.1+14.apk', aab: 'releases/satranc-platformu-play-0.8.1+14.aab'};
const expected = {apk: 'A2D088409DBA4F61BA50A4E3141E7EB3EEF83681B471917612D41ADAF55005DD', aab: 'A78A286D8DA5146128154F45572E2E38D5265928A797EF4D430B8B6F48B739A5'};
const artifacts = {};
for (const type of ['apk', 'aab']) {
  artifacts[type] = {path: files[type], bytes: statSync(files[type]).size, sha256: sha(files[type])};
  if (artifacts[type].sha256 !== expected[type] || sha(desktop[type]) !== expected[type]) throw new Error('Signed package or desktop export changed');
}
if (!existsSync('store/release-status-080.json')) copyFileSync('store/release-status.json', 'store/release-status-080.json');
const status = JSON.parse(read('store/release-status-080.json'));
status.recordedAt = recordedAt;
Object.assign(status.application, {versionName: '0.8.1', versionCode: 14});
Object.assign(status.firebase, {rulesSha256: sha('firebase/firestore.rules'), rulesDeployment: 'successful', hostingDeployment: 'successful', privacyUpdatedForVersion: '0.8.1', lastVerifiedAt: recordedAt});
status.verification = {
  analysis: 'passed', fullFlutterTestsPassed: full, finalTargetedMembershipTestsPassed: targeted,
  liveFirebaseChecksPassed: 77, liveCapacityChecksPassed: 30, liveCompetitionChecksPassed: 47,
  liveFirebaseChecksFromVersion: '0.8.1+14', liveMatchChecksRerunFor081: false,
  previousLiveMatchChecks: {version: '0.8.0+13', passed: 38},
  firebaseLogs: ['releases/small-team-081-live.log', 'releases/firebase-081-competition-verification.log'],
  capacity: {...capacity, inventoryFile: 'releases/small-team-inventory.json', inventory},
  successfulFixtureDataAndAccountsCleaned: true,
  publicWebVerification: publicWeb,
  transport: 'Firebase Firestore Lite HTTPS ordinary client transactions; Node HTTP/2 attempt did not complete.',
  apkSignatureVerified: true, aabSignatureVerified: true, androidPackageAndVersionVerified: true,
  embeddedSchoolCatalogMatchesSource: true, embeddedPrivateSchoolCatalogMatchesSource: true, embeddedSchoolLicensePresent: true,
  emulatorStarted: false, thisVersionInstalledOnPhysicalPhone: phoneInstalled,
  currentPhysicalPhoneVerification: phone,
  previousPhysicalPhoneVerification: {version: '0.8.0+13', installed: true, androidAppLinksVerified: true},
  twoPhysicalPhonesWhatsAppAppLinkTest: 'pending', mobileVisualPreviewsRerunFor081: false,
  previousMobileVisualPreviews: {version: '0.8.0+13', passed: 5},
};
status.artifacts = artifacts;
status.desktopExports = {checksumsVerified: true, apkPath: desktop.apk, aabPath: desktop.aab};
status.playConsole = {...status.playConsole, ...play};
delete status.playConsole.localVersionNotUploaded;
status.playConsole.recheckedDuring081Work = true;
status.smallTeamPolicy = {maximumMembers: 20, scopes: ['classroom', 'group'], appliesTo: 'permanent linked accounts', guestsReserveRemotePlaces: false, parentsCapped: false, backendEnforced: true, maximumTransactionChanges: 6, membershipPrivate: true};
status.featuresAddedIn081 = ['atomic-class-and-group-20-member-cap', 'concurrent-final-place-reservation', 'friendly-full-team-error', 'departure-frees-capacity', 'private-membership-documents', 'uncapped-country-city-school', 'account-deletion-releases-places'];
status.currentLimits = status.currentLimits.filter(s => !s.startsWith('New account data safety') && !s.startsWith('Physical Android App Link'));
status.currentLimits.push('0.8.1 was published to internal test; closed-test and pre-launch status are recorded from Play UI below. Real participants and the 14-day requirement cannot be simulated by Firebase fixtures.');
status.currentLimits.push(phoneInstalled ? '0.8.1 was installed by USB on a physical phone; two-phone WhatsApp invitations and detailed performance checks remain pending.' : '0.8.1 has not been installed on a physical phone this turn; two-phone WhatsApp invitations and performance checks remain pending.');
writeFileSync('store/release-status.json', JSON.stringify(status, null, 2) + '\n');
writeFileSync('releases/release-081-receipt.json', JSON.stringify({recordedAt, version: '0.8.1+14', fullTests: full, targetedTests: targeted, liveChecks: 77, artifacts, desktop, play}, null, 2) + '\n');

const closed = play.closedTest.state === 'under_google_review' ? 'Kapalı Alpha testi ve güncel mağaza beyanları Google incelemesine gönderildi; onay bekliyor.' : play.closedTest.description;
const delivery = `## Teslim ve doğrulama\n\n[Play AAB](${files.aab}) ve [telefon APK](${files.apk}) 0.8.1+14 olarak mevcut upload imzasıyla derlendi. Paket com.zpgames.satrancplatformu, minSdk24/targetSdk36; imzalar, gömülü kataloglar ve lisans, masaüstü kopyalarının SHA256 eşitliği doğrulandı.\n\nKaynak analizi temiz; **143 uygulama testi**, son hata dönüşümü için **2 hedefli üyelik testi** ve **77 canlı Firebase kontrolü** (30 kapasite + 47 hesap/puan/yetki) geçti. Önceki 0.8.0'ın 38 maç/davet kontrolü tarihsel kanıttır; bu turda yeniden geçildiği iddia edilmez. Emülatör açılmadı. 0.8.1 bu turda telefona yüklenmedi; önceki 0.8.0 fiziksel telefon/App Links kontrolü korunur.\n\n**Dahili testte 0.8.1+14 kullanılabilir.** ${closed} Yeni hesap, veri toplama/silme beyanı ve mağaza açıklaması güncellendi. Gerçek kapalı test katılımcısı sayısı son kontrolde ${play.closedTest.observedOptedInTesters}; 12 kişi/14 gün koşulu henüz tamamlanmadı. Play otomatik test durumu: ${play.preLaunchReport.description}. Güncel kayıt store/release-status.json ve releases/play-081-result.json.\n\nHer sınıf/grup en fazla 20 kalıcı hesap üyesi kabul eder. Misafir seçimi yerel, sıralamaya katılım ayrı seçimdir. [Kapasite kuralı ve test kanıtı](docs/SMALL_TEAMS.md).\n\n`;
let readme = read('README.md').replace('Satranç Platformu — 0.8.0+13', 'Satranç Platformu — 0.8.1+14');
readme = readme.replace(/## Teslim ve doğrulama[\s\S]*?(?=\[Doğrulama\])/u, delivery);
if (phoneInstalled) readme = readme.replace('0.8.1 bu turda telefona yüklenmedi; önceki 0.8.0 fiziksel telefon/App Links kontrolü korunur.', '0.8.1+14 USB ile fiziksel telefona kuruldu ve açılış isteği başarılı oldu. Ayrıntılı dokunma/performans ve iki telefon davet kontrolü bekler; önceki 0.8.0 App Links kanıtı tarihsel olarak korunur.');
writeFileSync('README.md', readme);
const verification = `## Güncel 0.8.1+14 — 5 Ekim 2026\n\n- Sınıf ve grup kapasitesi kalıcı hesaplarda 20. Sayaç, özel üyelik ve profil tek atomik işlemdir; sunucu 21. üyeyi engeller. Dolu takıma geçişte eski seçim korunur; ayrılma yer açar. Üst ülke/şehir/okul kapasitesi sınırlandırılmaz. Ayrıntı docs/SMALL_TEAMS.md.\n- 143 tam uygulama testi, son kapasite hata dönüşümü sonrası 2 hedefli test ve temiz kaynak analizi geçti. Canlı sıradan HTTPS istemcileriyle 30 kapasite ve 47 mevcut hesap/puan/yetki kontrolü geçti. Başarılı süitin fixture hesapları/verileri temizlendi; final envanter kaydı releases/small-team-inventory.json. HTTP/2 taşıma denemesi tamamlanmadı, sertifika doğrulaması korunarak resmî Firestore Lite HTTPS kullanıldı.\n- Spark projesine kurallar ve 0.8.1 gizlilik sayfası ücretsiz planla uygulandı; releases/firebase-081-deploy.log. APK/AAB paket ve mevcut upload imzası, katalog/lisans ve masaüstü eşitliği releases/android-081-package-verification.log ile doğrulandı.\n- APK SHA256 ${artifacts.apk.sha256}; AAB SHA256 ${artifacts.aab.sha256}.\n- Dahili test 0.8.1+14 yayında. ${closed} Play sonuçları releases/play-081-result.json; otomatik ön lansman: ${play.preLaunchReport.description}. ${play.closedTest.observedOptedInTesters} gerçek katılım gözlendi; test fixture'ları Play katılımcısı değildir.\n- Veri Güvenliği'nde isteğe bağlı hesap, okul/grup seçimi ve okul bildirimi açıklaması güncellendi. Sabit sporculuk mesajları Google'ın oyun eylemleri/diyalog seçenekleri kapsamındaki Diğer işlemler kategorisinde; serbest sohbet olmadığı için mesaj kategorisi eklenmedi. Otomatik onay denetimi bu ayrı mesaj kategorisini mevcut kanıtla reddetti; güvenli sınıflandırma kullanıldı.\n- Emülatör açılmadı; yeni sürüm fiziksel telefona yüklenmedi. Önceki 0.8.0'ın 38 maç/davet, beş başsız önizleme ve telefon/App Links kanıtı tarihsel aşağıdaki bölümde kalır; 0.8.1 yeniden test sonucu değildir.\n\n`;
for (const path of ['docs/VERIFICATION.md', 'docs/PLAY_FIREBASE_SETUP.md']) {
  const old = read(path);
  const history = old.startsWith('## Güncel 0.8.1+14') ? old.replace(/^## Güncel 0\.8\.1\+14[\s\S]*?(?=## Güncel 0\.8\.0\+13)/u, '') : old;
  const currentVerification = phoneInstalled ? verification.replace('Emülatör açılmadı; yeni sürüm fiziksel telefona yüklenmedi.', 'Emülatör açılmadı; 0.8.1+14 USB ile fiziksel telefona kuruldu, sürüm ve başarılı açılış doğrulandı. Kurulum -r ile yapıldı; veri silme komutu çalıştırılmadı. Telefon kaydı releases/android-081-device-check.json.') : verification;
  writeFileSync(path, currentVerification + history);
}
console.log(JSON.stringify({version: '0.8.1+14', fullTests: full, targetedTests: targeted, liveChecks: 77, artifacts, desktop, internalTest: play.internalTest.state, closedTest: play.closedTest.state}));
