import {createRequire} from 'node:module';
import {readFileSync,writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {randomBytes} from 'node:crypto';
import assert from 'node:assert/strict';
const require=createRequire(resolve('.tools/firebase-client/package.json'));
const {initializeApp,deleteApp}=require('firebase/app');
const {getAuth,signInAnonymously,deleteUser,signInWithEmailAndPassword}=require('firebase/auth');
const {Client}=require(resolve('.tools/firebase-cli/node_modules/firebase-tools/lib/apiv2'));
const firebase=require(resolve('.tools/firebase-cli/node_modules/firebase-tools'));
const {getFirestore,doc,setDoc,getDoc,deleteDoc,serverTimestamp,setLogLevel}=require('firebase/firestore/lite');
const cfg=JSON.parse(readFileSync('android/app/google-services.json','utf8'));
const c=cfg.client.find(c=>c.client_info.android_client_info.package_name==='com.zpgames.satrancplatformu');
const settings={apiKey:c.api_key[0].current_key,projectId:cfg.project_info.project_id,appId:c.client_info.mobilesdk_app_id};
await firebase.apps.list('ANDROID',{project:'satranc-platformu',nonInteractive:true});
const adminClient=new Client({urlPrefix:'https://identitytoolkit.googleapis.com',apiVersion:'v2'});
const config=(await adminClient.get('/projects/satranc-platformu/config')).body;
const authSettings={emailEnabled:config.signIn?.email?.enabled===true,anonymousEnabled:config.signIn?.anonymous?.enabled===true,
  improvedEmailPrivacy:config.emailPrivacyConfig?.enableImprovedEmailPrivacy===true,
  passwordPolicyMode:config.passwordPolicyConfig?.passwordPolicyEnforcementState??'default',
  passwordStrength:config.passwordPolicyConfig?.passwordPolicyVersions?.[0]?.customStrengthOptions??null,
  emailRecaptchaEnforcement:config.recaptchaConfig?.emailPasswordEnforcementState??'default',
  verifyEmailTemplateConfigured:!!config.notification?.sendEmail?.verifyEmailTemplate};
const app=initializeApp(settings,'register-proof-'+randomBytes(5).toString('hex'));
const auth=getAuth(app), db=getFirestore(app);
setLogLevel('silent');
const email='registration-check-'+randomBytes(8).toString('hex')+'@example.invalid';
const password=randomBytes(16).toString('hex')+'Aa7!';
const checks=[]; let uid,createdProfile=false,failure,legacyStatus;
async function request(action,body) {
  const response=await fetch('https://identitytoolkit.googleapis.com/v1/accounts:'+action+'?key='+settings.apiKey,
    {method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body),signal:AbortSignal.timeout(15000)});
  const data=await response.json();
  return {status:response.status,data};
}
try {
  const user=(await signInAnonymously(auth)).user;uid=user.uid;
  const idToken=await user.getIdToken();
  const legacy=await request('update',{idToken,email,password,returnSecureToken:true});
  legacyStatus={status:legacy.status,code:legacy.data.error?.message?.split(/[ :]/u)[0]??'success'};
  // Even if the old API succeeded, the same ID-token signUp must never create
  // another user. The exact supported registration endpoint is exercised here.
  const linked=await request('signUp',{idToken,email,password,returnSecureToken:true});
  assert.equal(linked.status,200,linked.data.error?.message?.split(/[ :]/u)[0]??'signup-failed');checks.push('supported email registration endpoint accepts ID-token link');
  assert.equal(linked.data.localId,uid);checks.push('registration preserves guest UID');
  await user.reload();await auth.currentUser.getIdToken(true);
  assert.equal(auth.currentUser.isAnonymous,false);checks.push('reload exposes permanent account to Flutter-equivalent SDK');
  assert.equal(auth.currentUser.email,email);checks.push('registered address is reflected in account');
  const previousProvider=(await auth.currentUser.getIdTokenResult()).claims.firebase?.sign_in_provider;
  authSettings.originalRefreshedProvider=previousProvider;
  await signInWithEmailAndPassword(auth,email,password);
  assert.equal(auth.currentUser.uid,uid);checks.push('password session retains original UID');
  const permanentProvider=(await auth.currentUser.getIdTokenResult()).claims.firebase?.sign_in_provider;
  assert.equal(permanentProvider,'password');checks.push('password session authorizes permanent-account operations');
  await setDoc(doc(db,'playerAccounts',uid),{displayName:'Kayıt testi',membership:{version:1,countryId:'tr',cityId:null,schoolId:null,classId:null,groupIds:[]},rankingEnabled:false,rankingCleanupPending:false,updatedAt:serverTimestamp()});
  createdProfile=true;checks.push('fresh permanent ID token can back up private profile');
  assert.equal((await getDoc(doc(db,'playerAccounts',uid))).data().rankingEnabled,false);checks.push('ranking remains private and opt-in');
  await auth.signOut();await signInWithEmailAndPassword(auth,email,password);
  assert.equal(auth.currentUser.uid,uid);checks.push('email-password sign-in returns the original account');
  // No deliverable email is requested or sent to a person. Verify only that
  // ordinary linking supplies the account state needed by sendEmailVerification.
  assert.equal(auth.currentUser.emailVerified,false);checks.push('registration does not bypass email verification');
} catch(e) {failure={code:e.code??e.name,message:e.message?.replaceAll(email,'[fixture-email]')};}
const cleanupErrors=[];
try {if(createdProfile)await deleteDoc(doc(db,'playerAccounts',uid));if(auth.currentUser)await deleteUser(auth.currentUser);}catch(e){cleanupErrors.push(e.code??e.name);}
await deleteApp(app);
const receipt={recordedAt:new Date().toISOString(),version:'0.8.3+16',authSettings,legacyStatus,passed:checks.length,checks,
  deliveryToRealMailboxTested:false,emailsSentToPeople:0,fixtureDataAndAccountCleaned:cleanupErrors.length===0,cleanupErrors,failure:failure??null};
writeFileSync('releases/registration-083-live-verification.json',JSON.stringify(receipt,null,2)+'\n');console.log(JSON.stringify(receipt));
if(failure||cleanupErrors.length)process.exitCode=1;

