import {readFileSync,writeFileSync,statSync,existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
const read = p => readFileSync(p,'utf8');
const sha = p => createHash('sha256').update(readFileSync(p)).digest('hex').toUpperCase();
const version='0.8.3+16', recordedAt=new Date().toISOString();
const full=Number(read('releases/flutter-083-tests.log').match(/\+(\d+): All tests passed!/u)?.[1]);
const registration=JSON.parse(read('releases/registration-083-live-verification.json'));
const analysis=read('releases/flutter-083-analysis.log');
const packages=read('releases/android-083-package-verification.log');
if(full!==164 || !analysis.includes('No issues found!') || registration.passed!==10 || registration.failure || !registration.fixtureDataAndAccountCleaned) throw new Error('Registration verification evidence incomplete');
if(registration.authSettings.passwordStrength.minPasswordLength!==12 || !registration.authSettings.improvedEmailPrivacy) throw new Error('Observed policy mismatch');
if(!packages.includes("versionCode='16' versionName='0.8.3'") || !packages.includes('jar verified') || !packages.includes('Verified')) throw new Error('Signed package verification incomplete');
const status=JSON.parse(read('store/release-status-082.json'));
if(sha('firebase/firestore.rules')!==status.firebase.rulesSha256) throw new Error('Rules changed without deployment evidence');
const files={apk:'releases/satranc-platformu-0.8.3+16.apk',aab:'releases/satranc-platformu-play-0.8.3+16.aab'};
const desktop={apk:'C:/Users/GiresuN/Desktop/Satranc-Platformu-0.8.3.apk',aab:'C:/Users/GiresuN/Desktop/Satranc-Platformu-0.8.3.aab'};
const artifacts={};
for(const type of ['apk','aab']) {
  artifacts[type]={path:files[type],bytes:statSync(files[type]).size,sha256:sha(files[type])};
  if(sha(desktop[type])!==artifacts[type].sha256) throw new Error('Desktop export mismatch');
}
const phone=existsSync('releases/android-083-device-check.json')?JSON.parse(read('releases/android-083-device-check.json')):null;
const installed=phone?.thisVersionInstalled===true&&phone?.installedVersion===version;
status.recordedAt=recordedAt;
Object.assign(status.application,{versionName:'0.8.3',versionCode:16});
status.firebase.authenticationSettingsLastReadAt=registration.recordedAt;
status.firebase.emailEnumerationProtectionEnabled=true;
status.firebase.enforcedMinimumPasswordLength=12;
status.firebase.authConfigurationChangedIn083=false;
status.firebase.rulesRedeployedIn083=false;
status.verification={
  analysis:'passed',fullFlutterTestsPassed:full,registrationTargetedTestsPassed:13,
  liveFirebaseChecksPassed:registration.passed,liveFirebaseChecksFromVersion:version,registration,
  verificationEmailDeliveryToRealMailboxTested:false,
  successfulFixtureDataAndAccountsCleaned:true,
  previousLiveTimingChecks:{version:'0.8.2+15',passed:30,rerunFor083:false},
  previousCapacityAndCompetitionChecks:{version:'0.8.1+14',capacity:30,competition:47,rerunFor083:false},
  apkSignatureVerified:true,aabSignatureVerified:true,androidPackageAndVersionVerified:true,
  embeddedSchoolCatalogMatchesSource:true,embeddedPrivateSchoolCatalogMatchesSource:true,embeddedSchoolLicensePresent:true,
  emulatorStarted:false,thisVersionInstalledOnPhysicalPhone:installed,currentPhysicalPhoneVerification:phone,
  previousPhysicalPhoneVerification:{version:'0.8.1+14',installed:true,launchRequestSuccessful:true},
  twoPhysicalPhonesWhatsAppAppLinkTest:'pending',detailedPhysicalUiAndPerformanceVerified:false
};
status.artifacts=artifacts;
status.desktopExports={checksumsVerified:true,apkPath:desktop.apk,aabPath:desktop.aab};
status.playConsole.localVersionNotUploaded={versionCode:16,versionName:'0.8.3',aabPath:files.aab};
status.featuresAddedIn083=['clear-register-label','id-token-signup-preserving-guest-uid','password-session-for-private-backup','twelve-character-policy-alignment','verification-independent-of-backup','localized-verification-request-and-retry','specific-auth-errors'];
status.newIconProposal={path:'design/icon-options/04-studio-chess-512.png',prompt:'design/icon-options/04-STUDIO-PROMPT.md',appliedToLauncher:false,appliedToPlayListing:false};
status.currentLimits=status.currentLimits.filter(s=>!s.startsWith('0.8.2+15 signed APK/AAB'));
status.currentLimits.push('0.8.3+16 signed APK/AAB prepared locally; not uploaded to Play. The previously recorded internal 0.8.1+14 and closed draft remain unchanged. Dedicated review credential disclosure approval remains pending.');
status.currentLimits.push('Registration and private backup passed ordinary live-client checks. No email was sent to a real person; actual verification-mail delivery to a mailbox is unverified.');
writeFileSync('store/release-status.json',JSON.stringify(status,null,2)+'\n');
writeFileSync('releases/release-083-receipt.json',JSON.stringify({recordedAt,version,fullTests:full,liveRegistrationChecks:registration.passed,artifacts,desktop,phone,playVersionUploaded:false,realVerificationMailDeliveryTested:false},null,2)+'\n');
const phoneText=installed?'Yeni sürüm USB ile fiziksel telefona kuruldu; sürüm/açılış kaydı releases/android-083-device-check.json.':'Yeni sürüm henüz telefona kurulmadı; son USB kontrolünde telefon bağlı değildi. Son doğrulanmış telefon sürümü tarihsel 0.8.1+14 kaydıdır.';
const delivery=`## Teslim ve doğrulama\n\n[Play AAB](${files.aab}) ve [telefon APK](${files.apk}) **0.8.3+16** olarak mevcut upload imzasıyla derlendi; masaüstündeki 0.8.3 kopyaları birebir aynı. Paket kimliği, imzalar, gömülü kataloglar/lisans doğrulandı.\n\nKaynak analizi temiz; **${full} uygulama testi**, bunların içinde 13 yeni kayıt testi, ve **${registration.passed} canlı kayıt/oturum/özel yedek kontrolü** geçti. Test verisi ve hesabı silindi. Kayıt ol ifadesi, desteklenen UID koruyan kayıt yöntemi ve sunucudaki 12 karakter şifre şartı uyumludur. Doğrulama isteği başarısız yedek veya dolu sınıftan bağımsız çalışır. Gerçek gelen kutusuna e-posta teslimi bu turda test edilmedi. [Kayıt düzeltmesi](docs/ACCOUNT_REGISTRATION.md).\n\nEmülatör açılmadı. ${phoneText} **0.8.3 henüz Play Console'a yüklenmedi.** Son Play kaydı: dahili 0.8.1+14; Alpha taslağının inceleme hesabı aktarımı için özel onay bekler. Önceki süre/kapasite/puan testleri tarihsel kanıttır; canlı kayıt kontrollerine eklenmez. Firebase Spark ve mevcut kurallar korunur.\n\nYeni Zeka Parkuru tarzındaki [ikon önerisi](design/icon-options/04-studio-chess-512.png) ve [üretim istemi](design/icon-options/04-STUDIO-PROMPT.md) kaydedildi; seçim bekler.\n\n`;
let readme=read('README.md').replace('Satranç Platformu — 0.8.2+15','Satranç Platformu — 0.8.3+16');
readme=readme.replace(/## Teslim ve doğrulama[\s\S]*?(?=\[Doğrulama\])/u,delivery);
writeFileSync('README.md',readme);
const verification=`## Güncel 0.8.3+16 — 5 Ekim 2026\n\n- Hesabım formu Kayıt ol; minimum şifre 12. Misafir UID'siyle signUp ve aynı hesaba password oturumu: gizlilik korumasını kapatmadan kayıt/özel yedek çalışır. Açıklama docs/ACCOUNT_REGISTRATION.md.\n- E-posta isteği Türkçe ve yedekten önce bağımsız; hata/yeniden gönderme ve bekleyen yedek görünür. Kayıt sonrası oturum hatası, yeniden kayıt yerine Giriş yap ile toparlanır.\n- Temiz analiz, ${full} tam uygulama testi (13 yeni kayıt testi dahil) ve ${registration.passed} canlı sıradan istemci kontrolü geçti; geçici hesap/verisi silindi. Gerçek mail teslimi test edilmedi, doğrulama atlatılmadı. Önceki 0.8.2'nin 30 zaman kuralı kontrolü tarihsel kanıttır.\n- 16/0.8.3 APK/AAB mevcut upload imzasıyla, katalog/lisans ve masaüstü eşitliğiyle doğrulandı. APK SHA256 ${artifacts.apk.sha256}; AAB SHA256 ${artifacts.aab.sha256}.\n- ${phoneText} Emülatör açılmadı; yeni sürüm Play'e yüklenmedi. Spark ve sunucu kuralları değişmedi.\n- Zeka Parkuru stilindeki ikon seçeneği 04 kaydedildi, mevcut simgeye uygulanmadı.\n\n`;
for(const p of ['docs/VERIFICATION.md','docs/PLAY_FIREBASE_SETUP.md']) {
  const old=read(p).replace(/^## Güncel 0\.8\.3\+16[\s\S]*?(?=## Güncel 0\.8\.2\+15)/u,'');
  writeFileSync(p,verification+old);
}
console.log(JSON.stringify({version,fullTests:full,liveRegistrationChecks:registration.passed,phoneInstalled:installed,artifacts,desktop}));
