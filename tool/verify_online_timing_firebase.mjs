// Ordinary Firebase clients exercise real server time. Never backdate fixtures
// or use administrative credentials; delete only documents made by this run.
import {createRequire} from 'node:module';
import {readFileSync, writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {randomBytes} from 'node:crypto';
import assert from 'node:assert/strict';
const require = createRequire(resolve('.tools/firebase-client/package.json'));
const {initializeApp, deleteApp} = require('firebase/app');
const {getAuth, signInAnonymously, deleteUser} = require('firebase/auth');
const {getFirestore, doc, setDoc, getDoc, deleteDoc, runTransaction,
  serverTimestamp, Timestamp, setLogLevel} = require('firebase/firestore/lite');
setLogLevel('silent');
const config = JSON.parse(readFileSync('android/app/google-services.json', 'utf8'));
const client = config.client.find(c => c.client_info.android_client_info.package_name === 'com.zpgames.satrancplatformu');
const settings = {apiKey: client.api_key[0].current_key, projectId: config.project_info.project_id,
  appId: client.client_info.mobilesdk_app_id, authDomain: 'satranc-platformu.firebaseapp.com'};
const users = [], created = [], checks = [], cleanupErrors = [];
const track = (db, collection, id) => created.push({db, collection, id});
const ref = (p, collection, id) => doc(p.db, collection, id);
const state = async (p, id) => (await getDoc(ref(p, 'onlineMatches', id))).data();
async function check(name, action) { await action(); checks.push(name); }
async function denied(name, action) {
  await check(name, () => assert.rejects(action, e => e.code === 'permission-denied'));
}
async function invite(a, minutes = 10, increment = 0, limit = 180) {
  const id = randomBytes(20).toString('hex');
  const data = {creator: a.user.uid, guest: '', matchId: '', minutes, increment,
    createdAt: serverTimestamp(), expiresAt: Timestamp.fromMillis(Date.now() + 3600000)};
  if (limit !== null) data.turnLimitSeconds = limit;
  await setDoc(ref(a, 'onlineInvites', id), data);
  track(a.db, 'onlineInvites', id);
  return id;
}
async function accept(a, b, id, override) {
  await runTransaction(b.db, async tx => {
    const i = ref(b, 'onlineInvites', id), v = (await tx.get(i)).data();
    const data = {participants: [v.creator, b.user.uid], minutes: v.minutes, increment: v.increment,
      moves: [], createdAt: serverTimestamp(), lastAt: serverTimestamp(),
      whiteMs: v.minutes * 60000, blackMs: v.minutes * 60000};
    if (v.turnLimitSeconds !== undefined) data.turnLimitSeconds = v.turnLimitSeconds;
    if (override !== undefined) data.turnLimitSeconds = override;
    tx.set(ref(b, 'onlineMatches', id), data);
    tx.update(i, {guest: b.user.uid, matchId: id});
  });
  track(a.db, 'onlineMatches', id);
}
async function move(p, id, uci) {
  await runTransaction(p.db, async tx => {
    const r = ref(p, 'onlineMatches', id), v = (await tx.get(r)).data();
    const field = v.moves.length % 2 === 0 ? 'whiteMs' : 'blackMs';
    tx.update(r, {moves: [...v.moves, uci], drawBy: '', lastAt: serverTimestamp(),
      [field]: Math.round(v[field] - Math.max(0, Date.now() - v.lastAt.toMillis()) + v.increment * 1000)});
  });
}
async function offer(p, id) {
  await runTransaction(p.db, async tx => {
    const r = ref(p, 'onlineMatches', id), v = (await tx.get(r)).data();
    tx.update(r, {drawBy: p.user.uid, drawPly: v.moves.length,
      actionRevision: (v.actionRevision ?? 0) + 1, actionAt: serverTimestamp()});
  });
}
const emptyProfile = () => ({alias: '', optIn: false, countryId: '', cityId: '', schoolId: '', classId: '', groupIds: []});
async function result(p, id, reason, outcome) {
  const v = await state(p, id);
  await setDoc(ref(p, 'onlineResults', id), {participants: v.participants, ply: v.moves.length,
    lastAt: v.lastAt, reason, outcome, confirmedBy: [p.user.uid],
    profiles: {[p.user.uid]: emptyProfile()}, endedAt: serverTimestamp()});
  track(p.db, 'onlineResults', id);
}
async function waitUntil(target) {
  while (Date.now() < target) {
    await new Promise(resolveWait => setTimeout(resolveWait, Math.min(15000, target - Date.now())));
    console.log(JSON.stringify({stage: 'waiting_for_real_server_deadline', secondsLeft: Math.max(0, Math.ceil((target - Date.now()) / 1000))}));
  }
}
let failure;
try {
  for (let n = 0; n < 3; n++) {
    const app = initializeApp(settings, `chess-timing-${randomBytes(6).toString('hex')}`);
    const p = {app, db: getFirestore(app)};
    users.push(p);
    p.user = (await signInAnonymously(getAuth(app))).user;
  }
  const [a, b, outsider] = users;
  await denied('unsupported turn policy is rejected', () => invite(a, 10, 0, 181));
  await denied('fractional turn policy is rejected', () => invite(a, 10, 0, 180.5));
  const white = await invite(a);
  await denied('acceptance cannot remove the advertised turn limit', () => accept(a, b, white, 0));
  await check('failed acceptance leaves invitation unused', async () => assert.equal((await getDoc(ref(a, 'onlineInvites', white))).data().guest, ''));
  await check('new match accepts the advertised policy', () => accept(a, b, white));
  const black = await invite(a); await accept(a, b, black); await move(a, black, 'e2e4');
  const short = await invite(a, 1); await accept(a, b, short);
  const legacy = await invite(a, 10, 0, null); await accept(a, b, legacy);
  const reset = await invite(a); await accept(a, b, reset);
  const start = (await state(a, white)).lastAt.toMillis();
  await denied('early inactivity result is rejected', () => result(b, white, 'inactivity', 'black'));
  await denied('outsider cannot read the match', () => state(outsider, white));
  await denied('black cannot move before white', () => move(b, white, 'e7e5'));
  await denied('existing turn policy is immutable', () => setDoc(ref(a, 'onlineMatches', white), {turnLimitSeconds: 0}, {merge: true}));
  await check('presence write is accepted', async () => {
    await setDoc(doc(a.db, 'onlineMatches', white, 'presence', a.user.uid), {seenAt: serverTimestamp()});
    track(a.db, `onlineMatches/${white}/presence`, a.user.uid);
  });
  await check('draw offer does not restart the turn clock', async () => {
    await offer(a, white);
    assert.equal((await state(a, white)).lastAt.toMillis(), start);
  });
  const bucket = '117_59_180', oldBucket = '117_59';
  assert.equal((await getDoc(ref(a, 'onlineQueues', bucket))).exists(), false, 'Refusing to replace an existing queue');
  assert.equal((await getDoc(ref(a, 'onlineQueues', oldBucket))).exists(), false, 'Refusing to touch a legacy queue');
  const queued = await invite(a, 117, 59);
  const slot = {creator: a.user.uid, invite: queued, expiresAt: Timestamp.fromMillis(Date.now() + 240000)};
  await check('matching queue carries the new rule', async () => {
    await setDoc(ref(a, 'onlineQueues', bucket), slot); track(a.db, 'onlineQueues', bucket);
  });
  await denied('different-rule matchmaking bucket is rejected', () => setDoc(ref(a, 'onlineQueues', oldBucket), slot));
  console.log(JSON.stringify({stage: 'initial_checks_passed', passed: checks.length}));
  await waitUntil(start + 75000);
  await check('move before three minutes is accepted and restarts the turn', async () => {
    await move(a, reset, 'e2e4');
    assert.ok((await state(b, reset)).lastAt.toMillis() > start + 60000);
  });
  await denied('one-minute game cannot be classified as inactivity', () => result(a, short, 'inactivity', 'black'));
  await check('total clock expires before the longer turn limit', () => result(b, short, 'timeout', 'black'));
  await denied('move after total clock expiry is rejected', () => move(a, short, 'e2e4'));
  const lastBlack = (await state(b, black)).lastAt.toMillis();
  await waitUntil(Math.max(start, lastBlack) + 182000);
  await denied('incorrect inactivity winner is rejected', () => result(a, white, 'inactivity', 'white'));
  await denied('unexpired total clock cannot override inactivity deadline', () => result(a, white, 'timeout', 'black'));
  await check('white inactivity awards black the win', () => result(b, white, 'inactivity', 'black'));
  await check('black inactivity awards white the win', () => result(a, black, 'inactivity', 'white'));
  await denied('late white move is rejected by server', () => move(a, white, 'e2e4'));
  await denied('late black move is rejected by server', () => move(b, black, 'e7e5'));
  await denied('expired match cannot accept a draw', () => offer(b, white));
  await check('presence and draw offer did not postpone deadline', async () => assert.equal((await state(a, white)).lastAt.toMillis(), start));
  await check('opponent can confirm the same final result', async () => {
    await runTransaction(a.db, async tx => {
      const r = ref(a, 'onlineResults', white), v = (await tx.get(r)).data();
      tx.update(r, {confirmedBy: [...v.confirmedBy, a.user.uid], profiles: {...v.profiles, [a.user.uid]: emptyProfile()}});
    });
    assert.equal((await getDoc(ref(a, 'onlineResults', white))).data().confirmedBy.length, 2);
  });
  await denied('legacy match cannot acquire a new inactivity result', () => result(b, legacy, 'inactivity', 'black'));
  await check('legacy match still accepts a move after three minutes', () => move(a, legacy, 'e2e4'));
  await denied('newly reset turn has not yet expired', () => result(a, reset, 'inactivity', 'white'));
  await check('black can move within its renewed three-minute turn', () => move(b, reset, 'e7e5'));
} catch (e) {
  failure = {code: e.code ?? e.name, message: e.message};
} finally {
  // Children/results must be removed while parent participant ownership exists.
  const priority = item => item.collection.includes('/presence') ? 0 : item.collection === 'onlineResults' ? 1 : item.collection === 'onlineQueues' ? 2 : item.collection === 'onlineMatches' ? 3 : 4;
  for (const item of created.sort((a, b) => priority(a) - priority(b))) {
    try { await deleteDoc(doc(item.db, item.collection, item.id)); }
    catch (e) { cleanupErrors.push({collection: item.collection, code: e.code ?? e.name}); }
  }
  for (const p of users) {
    try { if (p.user) await deleteUser(p.user); }
    catch (e) { cleanupErrors.push({collection: 'fixture-auth', code: e.code ?? e.name}); }
    await deleteApp(p.app);
  }
  const receipt = {recordedAt: new Date().toISOString(), version: '0.8.2+15',
    transport: 'official Firestore Lite HTTPS ordinary client credentials', realServerDeadlineSeconds: 180,
    passed: checks.length, checks, fixtureDataAndAccountsCleaned: cleanupErrors.length === 0, cleanupErrors, failure: failure ?? null};
  writeFileSync('releases/online-timing-082-verification.json', JSON.stringify(receipt, null, 2) + '\n');
  console.log(JSON.stringify(receipt));
  if (failure || cleanupErrors.length) process.exitCode = 1;
}
