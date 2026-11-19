import {readFileSync,writeFileSync,statSync,existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
const read=p=>readFileSync(p,'utf8').replace(/^\uFEFF/u,'');
const sha=p=>createHash('sha256').update(readFileSync(p)).digest('hex').toUpperCase();
const recordedAt=new Date().toISOString(),version='0.8.4+17';
const icon=JSON.parse(read('releases/icon-084-verification.json'));
const packageLog=read('releases/android-084-package-verification.log');
const resourceLog=read('releases/android-084-icon-resources.log');
if(!icon.allMeaningfulAlphaInsideSafeZone || icon.foregroundBoundsIn108Dp.length!==4 || !icon.fullMasterCopyMatches || icon.displayedPieceHeightFraction<0.85) throw new Error('Icon verification incomplete');
if(!packageLog.includes("versionCode='17' versionName='0.8.4'") || !packageLog.includes('jar verified') || !packageLog.includes('Verified') || !resourceLog.includes('Adaptive icon resources verified')) throw new Error('Android package verification incomplete');
const status=JSON.parse(read('store/release-status-083.json'));
const files={apk:'releases/satranc-platformu-0.8.4+17.apk',aab:'releases/satranc-platformu-play-0.8.4+17.aab'};
const desktop={apk:'C:/Users/GiresuN/Desktop/Satranc-Platformu-0.8.4.apk',aab:'C:/Users/GiresuN/Desktop/Satranc-Platformu-0.8.4.aab'};
const artifacts={};
for(const type of ['apk','aab']) {
  artifacts[type]={path:files[type],bytes:statSync(files[type]).size,sha256:sha(files[type])};
  if(sha(desktop[type])!==artifacts[type].sha256) throw new Error('Desktop export mismatch');
}
const phone=existsSync('releases/android-084-device-check.json')?JSON.parse(read('releases/android-084-device-check.json')):null;
const installed=phone?.thisVersionInstalled===true&&phone?.installedVersion===version;
status.recordedAt=recordedAt;
Object.assign(status.application,{versionName:'0.8.4',versionCode:17});
status.verification={
  androidPackageAndVersionVerified:true,apkSignatureVerified:true,aabSignatureVerified:true,
  embeddedSchoolCatalogMatchesSource:true,embeddedPrivateSchoolCatalogMatchesSource:true,embeddedSchoolLicensePresent:true,
  iconResourcesPackaged:true,iconAlphaAndSafeZoneVerified:true,launcherMasksVisuallyChecked:['circle','rounded-square'],icon,
  priorApplicationVerification:{version:'0.8.3+16',analysis:'passed',fullFlutterTestsPassed:164,liveRegistrationChecksPassed:10,rerunFor084:false},
  applicationLogicChangedIn084:false,emulatorStarted:false,
  thisVersionInstalledOnPhysicalPhone:installed,currentPhysicalPhoneVerification:phone,
  previousPhysicalPhoneVerification:{version:'0.8.1+14',installed:true,launchRequestSuccessful:true},
  physicalLauncherAppearanceVerified:false,detailedPhysicalUiAndPerformanceVerified:false,
  verificationEmailDeliveryToRealMailboxTested:false,twoPhysicalPhonesWhatsAppAppLinkTest:'pending'
};
status.artifacts=artifacts;
status.desktopExports={checksumsVerified:true,apkPath:desktop.apk,aabPath:desktop.aab};
status.playConsole.localVersionNotUploaded={versionCode:17,versionName:'0.8.4',aabPath:files.aab};
status.featuresAddedIn084=['large-ivory-chess-knight-icon','full-bleed-jade-background','android-adaptive-foreground-and-background','android-themed-monochrome-icon','circle-and-rounded-square-mask-coverage'];
status.newIconProposal={path:'design/icon-options/05-full-chess-512.png',prompt:'design/icon-options/05-PROMPTS.md',appliedToLauncher:true,appliedToPlayListing:false};
status.currentLimits=status.currentLimits.filter(s=>!s.startsWith('0.8.3+16 signed APK/AAB'));
status.currentLimits.push('0.8.4+17 icon-only signed APK/AAB prepared locally; not uploaded to Play. Previous internal 0.8.1+14/closed draft unchanged, dedicated review credential disclosure approval pending.');
status.currentLimits.push('New launcher masks are rendering simulations. Actual phone app-drawer appearance and themed-icon behavior have not been physically inspected.');
writeFileSync('store/release-status.json',JSON.stringify(status,null,2)+'\n');
writeFileSync('releases/release-084-receipt.json',JSON.stringify({recordedAt,version,artifacts,desktop,icon,phone,playVersionUploaded:false,applicationLogicChanged:false,previousApplicationVerification:status.verification.priorApplicationVerification},null,2)+'\n');
const phoneText=installed?'0.8.4+17 fiziksel telefona USB ile kuruldu; uygulama listesindeki simge görünümü fiziksel olarak henüz incelenmedi.':'Telefon son USB kontrolünde bağlı değildi; 0.8.4+17 fiziksel telefona kurulmadı.';
const delivery=`## Teslim ve doğrulama\n\n[Play AAB](${files.aab}) ve [telefon APK](${files.apk}) **0.8.4+17** olarak mevcut upload imzasıyla derlendi; masaüstündeki 0.8.4 kopyaları birebir aynı. Paket kimliği, imzalar, gömülü kataloglar/lisans ve yeni Android simge kaynakları doğrulandı.\n\nYeni büyük krem satranç atı ve tam alan turkuaz zemin Android launcher simgesidir. 26+ katmanlı simge, 33+ tek renk ve eski Android PNG boyutları hazır. [Yuvarlak/kare önizleme](design/icon-options/05-launcher-preview.png) arayüz simülasyonudur. Taş görünen alanın yaklaşık %87'si yüksekliğinde; alpha ve güvenli bölge doğrulandı. [Simge belgesi](docs/LAUNCHER_ICON.md), [ImageGen istemleri](design/icon-options/05-PROMPTS.md).\n\nİş mantığı değişmedi; önceki 0.8.3'ün temiz analizi, **164 uygulama testi ve 10 canlı kayıt/yedekleme kontrolü** tarihsel kanıttır, bu turda yeniden koşulmadı. Kayıt ol ve 12 karakter şifre düzeltmeleri korunur. Gerçek e-posta teslimi henüz test edilmedi.\n\n${phoneText} Emülatör açılmadı. **0.8.4 Play Console'a yüklenmedi**; mağaza için 512px yeni görsel hazır, mevcut çevrim içi mağaza simgesi değiştirilmedi. Son Play kaydı ve inceleme hesabı aktarımı onayının beklemesi değişmedi. Firebase Spark yapılandırması/kuralları bu turda değişmedi.\n\n`;
let readme=read('README.md').replace('Satranç Platformu — 0.8.3+16','Satranç Platformu — 0.8.4+17');
readme=readme.replace('Taş yağmuru ve ZP GAMES açılışı, fildişi at launcher simgesi, hareket azaltma.','Taş yağmuru ve ZP GAMES açılışı, tam alan turkuaz zeminde büyük fildişi at Android launcher simgesi, hareket azaltma.');
readme=readme.replace(/## Teslim ve doğrulama[\s\S]*?(?=\[Doğrulama\])/u,delivery);
writeFileSync('README.md',readme);
const verification=`## Güncel 0.8.4+17 — 5 Ekim 2026\n\n- Büyük tek at ve dolu turkuaz zemin, Android 26+ katmanlı simge/33+ tek renk katmanı ve 24/25 PNG boyutları. Eski dosyalar korunur. Alpha, güvenli bölge ve yuvarlak/kare önizleme doğrulandı; gerçek cihaz uygulama listesi henüz incelenmedi. Ayrıntı docs/LAUNCHER_ICON.md.\n- 17/0.8.4 APK/AAB mevcut imzayla, gömülü katalog/lisans ve yeni simge kaynaklarıyla derlendi. Masaüstü eşitliği doğrulandı. APK SHA256 ${artifacts.apk.sha256}; AAB SHA256 ${artifacts.aab.sha256}.\n- ${phoneText} Emülatör açılmadı. Play simgesi/sürümü bu turda yüklenmedi; Firebase değiştirilmedi.\n- İş mantığı aynı. 0.8.3'ün 164 testi/10 canlı kayıt kontrolü aşağıda tarihsel kanıt olarak kalır; yeni simge için tekrar koşulmadı.\n\n`;
for(const p of ['docs/VERIFICATION.md','docs/PLAY_FIREBASE_SETUP.md']) {
  const old=read(p).replace(/^## Güncel 0\.8\.4\+17[\s\S]*?(?=## Güncel 0\.8\.3\+16)/u,'');
  writeFileSync(p,verification+old);
}
const branding='\n## Tam alan simge — 0.8.4+17\n\nBüyük tek krem at ve tam alan turkuaz zemin, yeni Android launcher simgesine uygulandı. Yerleşik ImageGen ile görsel ve alpha katmanı hazırlandı. [Ana görsel](../design/icon-options/05-full-chess-512.png) · [Yuvarlak/kare 48px önizleme](../design/icon-options/05-launcher-preview.png) · [İstemler](../design/icon-options/05-PROMPTS.md) · [Teknik simge belgesi](LAUNCHER_ICON.md). Eski seçenekler korunur; önceki seçenek 04 bu tasarımla değiştirildi. Play mağaza görseli ayrıca yüklenmelidir ve henüz değiştirilmedi.\n';
const oldBranding=read('docs/BRANDING.md').replace(/\n## Tam alan simge — 0\.8\.4\+17[\s\S]*$/u,'');
writeFileSync('docs/BRANDING.md',oldBranding+branding);
console.log(JSON.stringify({version,artifacts,desktop,phoneInstalled:installed,iconHeightFraction:icon.displayedPieceHeightFraction}));
