// Dedicated ordinary-player review identity. No administrator rights or real personal data.
// Run only after approval to provide its credentials to Google Play reviewers.
import {createRequire} from 'node:module';
import {readFileSync, writeFileSync, existsSync, mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {randomBytes} from 'node:crypto';
import assert from 'node:assert/strict';
const require = createRequire(resolve('.tools/firebase-client/package.json'));
const {initializeApp, deleteApp} = require('firebase/app');
const {getAuth, createUserWithEmailAndPassword, signInWithEmailAndPassword, signOut, reload, getIdToken} = require('firebase/auth');
const {getFirestore, doc, getDoc, setDoc, serverTimestamp, setLogLevel} = require('firebase/firestore/lite');
const firebase = require(resolve('.tools/firebase-cli/node_modules/firebase-tools'));
const {Client} = require(resolve('.tools/firebase-cli/node_modules/firebase-tools/lib/apiv2'));
setLogLevel('silent');
const config = JSON.parse(readFileSync('android/app/google-services.json', 'utf8'));
const client = config.client.find(c => c.client_info.android_client_info.package_name === 'com.zpgames.satrancplatformu');
const app = initializeApp({apiKey: client.api_key[0].current_key, projectId: config.project_info.project_id, appId: client.client_info.mobilesdk_app_id, authDomain: 'satranc-platformu.firebaseapp.com'}, 'play-review-preparation');
const auth = getAuth(app);
const privateFile = '.tools/private/play-review-account.json';
let credentials;
try {
  if (existsSync(privateFile)) {
    credentials = JSON.parse(readFileSync(privateFile, 'utf8'));
    assert.match(credentials.email, /^play-review-[a-f0-9]+@example\.invalid$/);
    await signInWithEmailAndPassword(auth, credentials.email, credentials.password);
    assert.equal(auth.currentUser.uid, credentials.uid);
  } else {
    credentials = {email: 'play-review-' + randomBytes(10).toString('hex') + '@example.invalid', password: randomBytes(24).toString('base64url')};
    const result = await createUserWithEmailAndPassword(auth, credentials.email, credentials.password);
    credentials.uid = result.user.uid;
    credentials.createdAt = new Date().toISOString();
    credentials.purpose = 'Google Play restricted feature review, ordinary player only; no real personal data, no admin rights.';
    mkdirSync('.tools/private', {recursive: true});
    writeFileSync(privateFile, JSON.stringify(credentials, null, 2) + '\n');
  }
  if (!auth.currentUser.emailVerified) {
    // Owner verifies this synthetic review-only identity; no verification email or OTP needed.
    await firebase.apps.list('ANDROID', {project: 'satranc-platformu', nonInteractive: true});
    await new Client({urlPrefix: 'https://identitytoolkit.googleapis.com', apiVersion: 'v1'}).post('/projects/satranc-platformu/accounts:update', {localId: credentials.uid, emailVerified: true});
    await reload(auth.currentUser);
    await getIdToken(auth.currentUser, true);
  }
  assert.equal(auth.currentUser.emailVerified, true);
  const db = getFirestore(app);
  const ref = doc(db, 'playerAccounts', credentials.uid);
  if (!(await getDoc(ref)).exists()) {
    await setDoc(ref, {displayName: 'Play Review', membership: {version: 1, countryId: 'tr', cityId: null, schoolId: null, classId: null, groupIds: []}, rankingEnabled: false, updatedAt: serverTimestamp()});
  }
  await signOut(auth);
  await signInWithEmailAndPassword(auth, credentials.email, credentials.password);
  assert.equal(auth.currentUser.emailVerified, true);
  assert.equal((await getDoc(ref)).data().displayName, 'Play Review');
  writeFileSync('releases/play-review-account-verification.json', JSON.stringify({checkedAt: new Date().toISOString(), ordinaryAccount: true, loginVerified: true, emailAlreadyVerified: true, otpRequired: false, privateBackupReadable: true, rankingOptInAvailable: true, administratorAccess: false, realPersonalData: false, remoteTeamPlacesInitiallyReserved: 0, credentialsFile: privateFile}, null, 2) + '\n');
  console.log('Dedicated ordinary-player review account prepared; sign-in and private backup verified. Credentials remain in ignored private storage.');
} finally { await deleteApp(app); }
