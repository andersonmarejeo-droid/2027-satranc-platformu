// Real Spark project smoke test. Uses ordinary client credentials, never Admin
// SDK privileges. Only records created by this run are cleaned up.
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { randomBytes } from 'node:crypto';
import assert from 'node:assert/strict';
const require = createRequire(resolve('.tools/firebase-client/package.json'));
const { initializeApp, deleteApp } = require('firebase/app');
const { getAuth, signInAnonymously, deleteUser } = require('firebase/auth');
const { getFirestore, doc, setDoc, getDoc, deleteDoc, runTransaction,
  serverTimestamp, Timestamp, onSnapshot, terminate, setLogLevel, collection, query, where, getDocs } = require('firebase/firestore');
setLogLevel('silent');
const config = JSON.parse(readFileSync('android/app/google-services.json','utf8'));
const client = config.client.find(c => c.client_info.android_client_info.package_name === 'com.zpgames.satrancplatformu');
const settings = {apiKey:client.api_key[0].current_key,projectId:config.project_info.project_id,
  appId:client.client_info.mobilesdk_app_id,authDomain:'satranc-platformu.firebaseapp.com'};
const apps = [], created = [], users = [];
let passed = 0;
async function denied(action) {
  await assert.rejects(action, e => e.code === 'permission-denied'); passed++;
}
async function accept(db, uid, id) {
  return runTransaction(db, async tx => {
    const inviteRef = doc(db,'onlineInvites',id);
    const v = (await tx.get(inviteRef)).data();
    const parentRef = v.rematchOf ? doc(db,'onlineMatches',v.rematchOf) : null;
    const parent = parentRef ? (await tx.get(parentRef)).data() : null;
    assert.equal(v.guest,'');
    tx.set(doc(db,'onlineMatches',id),{participants:[v.creator,uid],minutes:v.minutes,
      increment:v.increment,moves:[],createdAt:serverTimestamp(),lastAt:serverTimestamp(),
      whiteMs:v.minutes*60000,blackMs:v.minutes*60000});
    tx.update(inviteRef,{guest:uid,matchId:id});
    if (parentRef) tx.update(parentRef,{rematchMatch:id,actionRevision:(parent.actionRevision??0)+1,actionAt:serverTimestamp()});
  });
}
async function move(db,id,uci) {
  await runTransaction(db,async tx => {
    const ref = doc(db,'onlineMatches',id), v = (await tx.get(ref)).data();
    const field = v.moves.length%2===0 ? 'whiteMs':'blackMs';
    tx.update(ref,{moves:[...v.moves,uci],drawBy:'',lastAt:serverTimestamp(),
      [field]:v[field]-Math.max(0,Date.now()-v.lastAt.toMillis())+v.increment*1000});
  });
}
async function action(db,id,change) {
  await runTransaction(db,async tx => {
    const ref = doc(db,'onlineMatches',id), v = (await tx.get(ref)).data();
    tx.update(ref,{...change(v),actionRevision:(v.actionRevision??0)+1,actionAt:serverTimestamp()});
  });
}
try {
  for (let i=0;i<3;i++) {
    const app = initializeApp(settings,`chess-verification-${randomBytes(6).toString('hex')}`);
    apps.push(app);
    const auth = getAuth(app), user = (await signInAnonymously(auth)).user;
    users.push({user,db:getFirestore(app)});
  }
  const [a,b,c] = users;
  const id = randomBytes(20).toString('hex');
  const inviteRef = doc(a.db,'onlineInvites',id);
  await setDoc(inviteRef,{creator:a.user.uid,guest:'',matchId:'',minutes:3,increment:0,
    createdAt:serverTimestamp(),expiresAt:Timestamp.fromMillis(Date.now()+3600000)});
  created.push({db:a.db,collection:'onlineInvites',id});
  await accept(b.db,b.user.uid,id);
  created.push({db:a.db,collection:'onlineMatches',id});
  assert.equal((await getDoc(doc(a.db,'onlineMatches',id))).data().participants[1],b.user.uid); passed++;
  await denied(() => getDoc(doc(c.db,'onlineMatches',id)));
  await denied(() => getDoc(doc(c.db,'onlineInvites',id)));
  await denied(() => move(b.db,id,'e7e5'));
  const observed = new Promise((resolveSeen,reject) => {
    const timer = setTimeout(() => { stop();reject(new Error('live-listener-timeout')); },15000);
    const stop = onSnapshot(doc(b.db,'onlineMatches',id),s => {
      if(s.data()?.moves?.[0] === 'e2e4') { clearTimeout(timer);stop();resolveSeen(); }
    }, e => {clearTimeout(timer);reject(e);});
  });
  await move(a.db,id,'e2e4'); await observed; passed++;
  await move(b.db,id,'e7e5'); passed++;
  const state = (await getDoc(doc(a.db,'onlineMatches',id))).data();
  assert.deepEqual(state.moves,['e2e4','e7e5']); passed++;
  await denied(() => setDoc(doc(a.db,'onlineMatches',id),{
    ...state,moves:['d2d4','e7e5','g1f3'],lastAt:serverTimestamp()}));
  await denied(() => setDoc(doc(c.db,'onlineMatches',id),{
    ...state,moves:[...state.moves,'g1f3'],lastAt:serverTimestamp()}));
  await denied(() => setDoc(doc(a.db,'leaderboards','untrusted'),{rating:9999}));
  const reread = (await getDoc(doc(b.db,'onlineMatches',id))).data();
  assert.deepEqual(reread.moves,['e2e4','e7e5']); passed++;
  await action(a.db,id,v => ({drawBy:a.user.uid,drawPly:v.moves.length})); passed++;
  const drawState = (await getDoc(doc(b.db,'onlineMatches',id))).data();
  assert.equal(drawState.drawBy,a.user.uid); passed++;
  const freeze = v => ({drawAccepted:true,
    whiteMs:v.whiteMs-Math.max(0,Date.now()-v.lastAt.toMillis()),blackMs:v.blackMs});
  await denied(() => action(a.db,id,freeze));
  await action(b.db,id,() => ({drawBy:''})); passed++;
  await action(b.db,id,v => ({drawBy:b.user.uid,drawPly:v.moves.length}));
  // A normal move declines an outstanding offer, without changing its history.
  await move(a.db,id,'g1f3');
  assert.equal((await getDoc(doc(b.db,'onlineMatches',id))).data().drawBy,''); passed++;
  await move(b.db,id,'b8c6');
  await action(a.db,id,v => ({drawBy:a.user.uid,drawPly:v.moves.length}));
  await action(b.db,id,freeze); passed++;
  await denied(() => move(a.db,id,'f1c4'));
  await action(a.db,id,v => ({quickMessages:[...(v.quickMessages??[]),
    {sender:a.user.uid,code:'congratulations',at:Timestamp.now()}]})); passed++;
  assert.equal((await getDoc(doc(b.db,'onlineMatches',id))).data().quickMessages[0].code,'congratulations'); passed++;
  await denied(() => action(b.db,id,v => ({quickMessages:[...v.quickMessages,
    {sender:b.user.uid,code:'free-text-not-allowed',at:Timestamp.now()}]})));
  await denied(() => action(b.db,id,() => ({quickMessages:[]})));
  await denied(() => action(c.db,id,() => ({drawBy:c.user.uid,drawPly:4})));
  for (let i=1;i<12;i++) await action(b.db,id,v => ({quickMessages:[...v.quickMessages,
    {sender:b.user.uid,code:'wellPlayed',at:Timestamp.now()}]}));
  await denied(() => action(b.db,id,v => ({quickMessages:[...v.quickMessages,
    {sender:b.user.uid,code:'thanks',at:Timestamp.now()}]})));
  const rematchId = randomBytes(20).toString('hex');
  await runTransaction(a.db,async tx => {
    const parentRef=doc(a.db,'onlineMatches',id), v=(await tx.get(parentRef)).data();
    tx.set(doc(a.db,'onlineInvites',rematchId),{creator:a.user.uid,guest:'',matchId:'',
      minutes:v.minutes,increment:v.increment,createdAt:serverTimestamp(),
      expiresAt:Timestamp.fromMillis(Date.now()+3600000),opponent:b.user.uid,rematchOf:id});
    tx.update(parentRef,{rematchBy:a.user.uid,rematchInvite:rematchId,
      actionRevision:v.actionRevision+1,actionAt:serverTimestamp()});
  });
  created.push({db:a.db,collection:'onlineInvites',id:rematchId}); passed++;
  const targeted = await getDocs(query(collection(b.db,'onlineInvites'),where('opponent','==',b.user.uid)));
  assert.equal(targeted.size,1); passed++;
  await denied(() => getDoc(doc(c.db,'onlineInvites',rematchId)));
  await denied(() => accept(c.db,c.user.uid,rematchId));
  await accept(b.db,b.user.uid,rematchId);
  created.push({db:a.db,collection:'onlineMatches',id:rematchId});
  const rematchState=(await getDoc(doc(a.db,'onlineMatches',rematchId))).data();
  assert.deepEqual(rematchState.participants,[a.user.uid,b.user.uid]);
  assert.equal((await getDoc(doc(a.db,'onlineMatches',id))).data().rematchMatch,rematchId); passed++;
  await action(a.db,rematchId,v => ({drawBy:a.user.uid,drawPly:v.moves.length}));
  await action(b.db,rematchId,freeze);
  // A recipient deleting their online data can also remove a pending rematch.
  const pendingId = randomBytes(20).toString('hex');
  await runTransaction(a.db,async tx => {
    const parentRef=doc(a.db,'onlineMatches',rematchId), v=(await tx.get(parentRef)).data();
    tx.set(doc(a.db,'onlineInvites',pendingId),{creator:a.user.uid,guest:'',matchId:'',
      minutes:v.minutes,increment:v.increment,createdAt:serverTimestamp(),
      expiresAt:Timestamp.fromMillis(Date.now()+3600000),opponent:b.user.uid,rematchOf:rematchId});
    tx.update(parentRef,{rematchBy:a.user.uid,rematchInvite:pendingId,
      actionRevision:(v.actionRevision??0)+1,actionAt:serverTimestamp()});
  });
  created.push({db:a.db,collection:'onlineInvites',id:pendingId});
  await denied(() => deleteDoc(doc(c.db,'onlineInvites',pendingId)));
  await deleteDoc(doc(b.db,'onlineInvites',pendingId)); passed++;
  created.splice(created.findIndex(v=>v.collection==='onlineInvites'&&v.id===pendingId),1);
  // Race two link holders: a transaction may create exactly one match.
  const raceId = randomBytes(20).toString('hex');
  await setDoc(doc(a.db,'onlineInvites',raceId),{creator:a.user.uid,guest:'',matchId:'',minutes:3,increment:0,
    createdAt:serverTimestamp(),expiresAt:Timestamp.fromMillis(Date.now()+3600000)});
  created.push({db:a.db,collection:'onlineInvites',id:raceId});
  const race = await Promise.allSettled([accept(b.db,b.user.uid,raceId),accept(c.db,c.user.uid,raceId)]);
  assert.equal(race.filter(r => r.status === 'fulfilled').length,1);
  created.push({db:a.db,collection:'onlineMatches',id:raceId}); passed++;
  // Use a private test bucket, never alter a pre-existing queue.
  const bucket = '117_59', queueRef = doc(a.db,'onlineQueues',bucket);
  assert.equal((await getDoc(queueRef)).exists(),false,'Test queue already exists; refusing to replace it');
  const queuedId = randomBytes(20).toString('hex');
  await runTransaction(a.db,async tx => {
    tx.set(doc(a.db,'onlineInvites',queuedId),{creator:a.user.uid,guest:'',matchId:'',minutes:117,increment:59,
      createdAt:serverTimestamp(),expiresAt:Timestamp.fromMillis(Date.now()+3600000)});
    tx.set(queueRef,{creator:a.user.uid,invite:queuedId,expiresAt:Timestamp.fromMillis(Date.now()+300000)});
  });
  created.push({db:a.db,collection:'onlineInvites',id:queuedId});
  created.push({db:a.db,collection:'onlineQueues',id:bucket}); passed++;
  await denied(() => deleteDoc(doc(c.db,'onlineQueues',bucket)));
  await runTransaction(b.db,async tx => {
    const slot = (await tx.get(doc(b.db,'onlineQueues',bucket))).data();
    const v = (await tx.get(doc(b.db,'onlineInvites',slot.invite))).data();
    tx.set(doc(b.db,'onlineMatches',slot.invite),{participants:[v.creator,b.user.uid],minutes:v.minutes,
      increment:v.increment,moves:[],createdAt:serverTimestamp(),lastAt:serverTimestamp(),
      whiteMs:v.minutes*60000,blackMs:v.minutes*60000});
    tx.update(doc(b.db,'onlineInvites',slot.invite),{guest:b.user.uid,matchId:slot.invite});
    tx.update(doc(b.db,'onlineQueues',bucket),{creator:'',invite:'',expiresAt:Timestamp.now()});
  });
  created.push({db:a.db,collection:'onlineMatches',id:queuedId});
  assert.equal((await getDoc(queueRef)).data().invite,''); passed++;
  // The cleared queue has no owner; replace with another owned test slot so
  // ordinary client cleanup remains authorized without Admin privileges.
  const cancelId = randomBytes(20).toString('hex');
  await runTransaction(a.db,async tx => {
    tx.set(doc(a.db,'onlineInvites',cancelId),{creator:a.user.uid,guest:'',matchId:'',minutes:117,increment:59,
      createdAt:serverTimestamp(),expiresAt:Timestamp.fromMillis(Date.now()+3600000)});
    tx.set(queueRef,{creator:a.user.uid,invite:cancelId,expiresAt:Timestamp.fromMillis(Date.now()+300000)});
  });
  await runTransaction(a.db,async tx => {
    tx.delete(doc(a.db,'onlineInvites',cancelId));
    tx.update(queueRef,{creator:'',invite:'',expiresAt:Timestamp.now()});
  }); passed++;
  // Re-own for cleanup; the invite is retained until queue deletion finishes.
  await runTransaction(a.db,async tx => {
    tx.set(doc(a.db,'onlineInvites',cancelId),{creator:a.user.uid,guest:'',matchId:'',minutes:117,increment:59,
      createdAt:serverTimestamp(),expiresAt:Timestamp.fromMillis(Date.now()+3600000)});
    tx.set(queueRef,{creator:a.user.uid,invite:cancelId,expiresAt:Timestamp.fromMillis(Date.now()+300000)});
  });
  created.push({db:a.db,collection:'onlineInvites',id:cancelId});
  const ownMatches = await getDocs(query(collection(a.db,'onlineMatches'),where('participants','array-contains',a.user.uid)));
  assert.equal(ownMatches.size,4); passed++;
  const guestInvites = await getDocs(query(collection(b.db,'onlineInvites'),where('guest','==',b.user.uid)));
  assert.ok(guestInvites.size >= 2); passed++;
  console.log(JSON.stringify({status:'passed',checks:passed,anonymousClients:3,
    verified:['one-time-invite','simultaneous-invite-acceptance','participant-only-access','turn-order','live-listener','two-client-moves','history-immutability','no-rating-write','reconnect-read','draw-opponent-only-acceptance','draw-decline-and-move-expiry','agreed-draw-blocks-moves','fixed-message-whitelist','message-immutability-and-limit','private-rematch-same-two-players','recipient-rematch-query-and-deletion','matchmaking-queue','queue-cancellation','owned-data-deletion-queries']},null,2));
} catch (error) {
  console.error(JSON.stringify({status:'failed',code:error.code??error.name,message:String(error.message).replace(/AIza[\w-]+/g,'[redacted]')}));
  process.exitCode = 1;
} finally {
  for(const record of created.reverse()) {
    try { await deleteDoc(doc(record.db,record.collection,record.id)); } catch { console.error('Test fixture cleanup incomplete');process.exitCode=1; }
  }
  for(const {user,db} of users) {
    try { await deleteUser(user);await terminate(db); } catch { console.error('Test session cleanup incomplete');process.exitCode=1; }
  }
  for(const app of apps) await deleteApp(app);
}
