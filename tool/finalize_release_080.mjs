import {readFileSync,writeFileSync,statSync} from 'node:fs';
import {createHash} from 'node:crypto';
const read=p=>readFileSync(p,'utf8');
const sha=p=>createHash('sha256').update(readFileSync(p)).digest('hex').toUpperCase();
const analysis=read('releases/flutter-080-analysis.log');
const tests=read('releases/flutter-080-tests.log');
const previews=read('releases/flutter-080-previews.log');
const passed=Number(tests.match(/\+(\d+): All tests passed!/u)?.[1]);
if(!analysis.includes('No issues found!') || passed!==141 || !previews.includes('All tests passed!')) throw new Error('Final verification is incomplete');
const live=read('releases/firebase-080-competition-verification.log');
const online=read('releases/firebase-080-online-verification.log');
if(!/"passed"\s*:\s*47/u.test(live) || JSON.parse(online).checks!==38 || JSON.parse(online).status!=='passed') throw new Error('Live checks incomplete');
const recordedAt=new Date().toISOString();
const phone=JSON.parse(read('releases/android-080-device-check.json'));
const files={apk:'releases/satranc-platformu-0.8.0+13.apk',aab:'releases/satranc-platformu-play-0.8.0+13.aab'};
const desktop={apk:'C:/Users/GiresuN/Desktop/Satranc-Platformu-0.8.0.apk',aab:'C:/Users/GiresuN/Desktop/Satranc-Platformu-0.8.0.aab'};
const artifacts={};
for(const type of ['apk','aab']) {
  artifacts[type]={path:files[type],bytes:statSync(files[type]).size,sha256:sha(files[type])};
  if(artifacts[type].sha256!==sha(desktop[type])) throw new Error('Desktop package differs: '+type);
}
const previewFiles=['080-home','080-profile','080-weekly-cup-fixture','080-account','080-review'].map(n=>'previews/'+n+'.png');
for(const file of previewFiles) if(statSync(file).size<10000) throw new Error('Missing visual preview');
const status=JSON.parse(read('store/release-status.json'));
status.recordedAt=recordedAt;
Object.assign(status.application,{versionName:'0.8.0',versionCode:13});
Object.assign(status.firebase,{
  emailPasswordAuthenticationEnabled:true,rulesSha256:sha('firebase/firestore.rules'),
  indexesFile:'firebase/firestore.indexes.json',indexesSha256:sha('firebase/firestore.indexes.json'),
  rulesDeployment:'successful',indexesDeployment:'successful',hostingDeployment:'successful',
  privacyUpdatedForVersion:'0.8.0',lastVerifiedAt:recordedAt,
});
status.verification={
  analysis:'passed',fullFlutterTestsPassed:passed,liveFirebaseChecksPassed:85,
  liveMatchChecksPassed:38,liveCompetitionChecksPassed:47,
  ordinaryClientSessionsPerLiveSuite:3,linkedSyntheticVerifiedFixtureAccounts:2,
  liveFirebaseChecksFromVersion:'0.8.0+13',liveFirebaseChecksRerunFor080:true,
  firebaseLogs:['releases/firebase-080-online-verification.log','releases/firebase-080-competition-verification.log'],
  fixtureDataAndAccountsCleaned:true,
  androidAssociationHttpStatus:200,challengePageHttpStatus:200,privacyHttpStatus:200,
  hostedPrivacyAndAssetLinksMatchSource:true,
  apkSignatureVerified:true,aabSignatureVerified:true,androidPackageAndVersionVerified:true,
  embeddedSchoolCatalogMatchesSource:true,embeddedPrivateSchoolCatalogMatchesSource:true,embeddedSchoolLicensePresent:true,
  emulatorStarted:false,physicalPhoneConnectedAtLastCheck:phone.physicalPhoneConnected,
  thisVersionInstalledOnPhysicalPhone:phone.thisVersionInstalled??false,
  physicalLaunchRequestSuccessful:phone.launchRequestSuccessful??false,
  physicalAppLinkDomainVerified:phone.physicalAppLinkDomainVerified??false,
  twoPhysicalPhonesWhatsAppAppLinkTest:'pending',
  mobileVisualPreviewsVerified:5,mobileVisualPreviewFiles:previewFiles,
  visualPreviewMethod:'Headless production Flutter widgets; ranking/auth fixtures are preview-only, not physical phone screenshots.',
};
status.artifacts=artifacts;
status.desktopExports={checksumsVerified:true,apkPath:desktop.apk,aabPath:desktop.aab};
status.playConsole.localVersionNotUploaded={versionName:'0.8.0',versionCode:13,currentClosedReviewVersionCode:10,currentInternalVersionCode:10,
  newAccountDataSafetyAndDeletionDeclarations:'pending before upload',preparedListingFile:'store/listing-tr.md'};
status.playConsole.recheckedDuring080Work=false;
status.featuresAddedIn080=[
  'compact-my-school-and-single-picker-edit','private-missing-school-feedback','remembered-one-tap-play-and-safe-resume',
  'auto-open-fast-match-and-queue-timeout','connection-presence-and-retry',
  'optional-linked-email-account-verification-and-recovery','private-profile-and-membership-backup-restore',
  'separate-public-ranking-opt-in-and-retriable-opt-out-cleanup',
  'two-client-result-agreement','immutable-idempotent-3-1-0-community-points',
  'weekly-monthly-all-time-community-standings-and-exact-own-rank','post-game-basic-review','reduce-motion-and-light-board',
];
status.currentLimits=[
  'Online access and accounts require neutral 13+ age selection and consent; offline play remains available from age 6.',
  'Community points require verified e-mail, explicit opt-in, at least four plies and matching confirmations from both clients. Guests remain unranked.',
  'Full chess legality is replayed by clients. Community points are not authoritative Elo; colluding modified clients are not prevented by a server engine.',
  'School/class/group membership is self-declared. Weekly cup is a score-period ranking, not automatic bracket tournament pairing.',
  'Profile/school selection is privately backed up; local game history is not synchronized across devices.',
  'Physical Android App Link opening, two-phone invitation flow and real-device performance still need verification.',
  'No iOS Firebase/Universal Links configuration or iOS build has been verified.',
  'New account data safety and deletion declarations must be updated in Play Console before uploading 0.8.0; Console was not rechecked this turn.',
  'Spark daily read/write quotas apply; no paid plan was enabled. Presence writes occur every 20 seconds while the match screen is active.',
  'Catalogue sources and dates are retained; MEB reuse permission and absolute current completeness remain unverified; user deferred permission review.',
];
writeFileSync('store/release-status.json',JSON.stringify(status,null,2)+'\n');
let readme=read('README.md');
const delivery=`## Teslim ve doğrulama\n\n[Play AAB](${files.aab}) ve [telefon APK](${files.apk}) mevcut upload imzasıyla derlendi. Paket/code13, minSdk24, targetSdk36; APK/AAB imzaları, iki çevrimdışı okul kataloğu ve lisans, masaüstü kopyalarının SHA256 eşitliği doğrulandı. Son kayıt store/release-status.json içindedir.\n\nKaynak analizi temiz; **141 uygulama testi**, **85 canlı Firebase kontrolü** (38 maç/davet + 47 hesap/puan/yetki) ve beş başsız ekran önizlemesi geçti. Önizlemeler gerçek Flutter arayüzü ve açıkça belirtilen test verisidir; telefon ekran görüntüsü değildir. Emülatör açılmadı. ${phone.thisVersionInstalled?'Güncel sürüm bağlı fiziksel telefona yüklendi; ayrıntılı fiziksel dokunma/performans ve iki telefon davet denemesi bekler.':'Son kontrolde fiziksel telefon bağlı değildi; yeni sürüm telefona yüklenmedi.'}\n\n0.8.0/13 Play Console'a yüklenmedi; yeni hesap/veri güvenliği ve silme beyanları yayın öncesinde güncellenmelidir. Son mağaza/test durumu 4 Ekim 18:28 tarihli kayıttır. Topluluk puanı Elo değildir, haftalık kupa dönem sıralamasıdır. Her iki oyuncunun da puan için 0.8.0 veya üstü kullanması gerekir.\n\n`;
readme=readme.replace(/## Teslim ve doğrulama[\s\S]*?(?=\[Doğrulama\])/u,delivery);
writeFileSync('README.md',readme);
const verification=`## Güncel 0.8.0+13 — 5 Ekim 2026\n\n- Kompakt okul düzenleme/bildirim, hatırlanan hızlı oyun, gerçek topluluk puanı/kişisel sıra, isteğe bağlı hesap ve yedek, bağlantı toparlama, haftalık kupa sıralaması ve maç sonrası temel inceleme eklendi. Hamle ipuçları çevrim içi kapalı; standart satranç kuralları korunur.\n- Temiz kaynak analizi, 141 uygulama testi ve beş başsız Flutter önizlemesi geçti. Testler başarısız hesap geri yüklemesinin uzaktaki yedeği değiştirmemesini, temizlik durumunun korunmasını, sıralama sorgu yarışı/gerçek kişisel sıra ve çevrim dışı hamle engellemeyi kapsar. Loglar releases/flutter-080-analysis.log, flutter-080-tests.log ve flutter-080-previews.log.\n- Canlı Spark projesine son kurallar/üç indeks uygulandı; e-posta sağlayıcısı etkin. Üç normal istemciyle 38 maç/davet, ayrı üç normal istemciyle 47 hesap/sonuç/puan/yetki kontrolü geçti. Yalnız iki geçici example.invalid test kimliği owner API ile test için doğrulandı; e-posta gönderilmedi. Uygulama veri işlemleri normal istemcilerle yapıldı. Tüm fixture belgeleri/hesapları temizlendi.\n- Hosting gizlilik ve assetlinks HTTP200, kaynak hash eşitliği ve davet sayfası HTTP200 doğrulandı. Güncel Hosting kayıt releases/firebase-080-public-web-verification.json.\n- APK ${artifacts.apk.bytes} bayt, SHA256 ${artifacts.apk.sha256}; AAB ${artifacts.aab.bytes} bayt, SHA256 ${artifacts.aab.sha256}. Paket com.zpgames.satrancplatformu, versionName0.8.0/code13, min24/target36; mevcut upload imzası, APK signature ve AAB jar verification geçti. İki pakette okul katalogları kaynakla aynı ve lisans mevcut; Desktop kopyaları birebir aynı. Paket kaydı releases/android-080-package-verification.log.\n- Beş önizleme ${previewFiles.join(', ')}. Haftalık sıralamadaki oyuncular ve hesap oturumu yalnız görsel fixture'dır; gerçek oyuncu iddiası yoktur.\n- Emülatör açılmadı. ${phone.thisVersionInstalled?'Bağlı fiziksel telefona yükleme doğrulandı; fiziksel arayüz kontrolü yapılmadı.':'Fiziksel telefon son kontrolde bağlı değildi; 0.8.0 yüklenmedi.'} İki telefon WhatsApp/App Links ve gerçek cihaz performansı bekler. Play Console bu turda değiştirilmedi; sürüm13 yüklenmedi. Yeni hesap/veri güvenliği/silme beyanları ve gerçek kapalı test koşulları tamamlanmadan herkese yayın yapılamaz.\n- Puan iki uygulamanın mutabakatıdır; yetkili motor, resmi üyelik veya Elo iddiası yoktur. Haftalık kupa puan tablosudur, eleme turnuvası değildir. Spark kotaları ve ertelenen kaynak izin değerlendirmesi geçerlidir.\n\n`;
const current=read('docs/VERIFICATION.md');
writeFileSync('docs/VERIFICATION.md',verification+current);
writeFileSync('releases/release-080-receipt.json',JSON.stringify({recordedAt,version:'0.8.0+13',passed,liveChecks:85,artifacts,desktop},null,2)+'\n');
console.log(JSON.stringify({version:'0.8.0+13',tests:passed,liveChecks:85,desktop,phoneInstalled:phone.thisVersionInstalled??false}));
