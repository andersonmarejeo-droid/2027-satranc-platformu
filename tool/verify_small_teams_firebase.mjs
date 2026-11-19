// Real Spark rules: disposable accounts, no e-mails, no emulator or paid services.
import {createRequire} from 'node:module';
import {readFileSync,writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {randomBytes} from 'node:crypto';
import assert from 'node:assert/strict';
import {saveTeamAccount,leaveTeamAccount} from './firebase_team_fixture.mjs';
const require=createRequire(resolve('.tools/firebase-client/package.json'));
const {initializeApp,deleteApp}=require('firebase/app');
const {getAuth,signInAnonymously,linkWithCredential,EmailAuthProvider,deleteUser}=require('firebase/auth');
const {getFirestore,doc,getDoc,setDoc,deleteDoc,serverTimestamp,collection,query,where,getDocs,terminate,setLogLevel}=require('firebase/firestore/lite');
setLogLevel('silent');
const config=JSON.parse(readFileSync('android/app/google-services.json','utf8'));
const client=config.client.find(c=>c.client_info.android_client_info.package_name==='com.zpgames.satrancplatformu');
const settings={apiKey:client.api_key[0].current_key,projectId:config.project_info.project_id,appId:client.client_info.mobilesdk_app_id,authDomain:'satranc-platformu.firebaseapp.com'};
const seed='capacity-'+randomBytes(10).toString('hex'),classId=seed+'-class',groupId=seed+'-group';
const users=[];let passed=0,phase='start';
const check=c=>{assert.ok(c);passed++;};
async function denied(fn) {await assert.rejects(fn,e=>e.code==='permission-denied');passed++;}
const membership=(cls=null,groups=[])=>({version:1,countryId:'tr',cityId:'giresun',schoolId:'gfl',classId:cls,groupIds:groups});
const account=m=>({displayName:'Kapasite testi',membership:m,rankingEnabled:false,updatedAt:serverTimestamp()});
const save=(u,m,opts)=>saveTeamAccount(u.db,u.user.uid,account(m),opts);
const count=async(u,scope,id)=>(await getDoc(doc(u.db,'smallTeams',scope+'_'+id))).data().count;
try {
  phase='create disposable clients';
  for(let i=0;i<22;i++) {
    phase='anonymous fixture '+i;
    const app=initializeApp(settings,seed+'-'+i),auth=getAuth(app),user=(await signInAnonymously(auth)).user;
    const u={app,auth,user,db:getFirestore(app)};users.push(u);
    phase='link fixture '+i;
    if(i<21) await linkWithCredential(user,EmailAuthProvider.credential(seed+'-'+i+'@example.invalid',randomBytes(24).toString('base64url')));
  }
  const outsider=users[21];
  await denied(()=>save(outsider,membership(classId)));
  phase='class last-place race';
  for(const u of users.slice(0,19)) await save(u,membership(classId));
  check(await count(users[0],'classroom',classId)===19);
  const results=await Promise.allSettled(users.slice(19,21).map(u=>save(u,membership(classId))));
  console.log('Class race: '+results.map(r=>r.status==='fulfilled'?'accepted':r.reason.code).join(', '));
  check(results.filter(r=>r.status==='fulfilled').length===1);
  check(['team-full','permission-denied'].includes(results.find(r=>r.status==='rejected').reason.code));
  const winner=users[19+results.findIndex(r=>r.status==='fulfilled')],loser=users[19+results.findIndex(r=>r.status==='rejected')];
  check(await count(users[0],'classroom',classId)===20);
  phase='server hard cap';
  await denied(()=>save(loser,membership(classId),{ignoreCapacity:true}));
  await save(winner,membership(classId));check(await count(winner,'classroom',classId)===20);
  await denied(()=>deleteDoc(doc(winner.db,'playerAccounts',winner.user.uid)));
  await denied(()=>deleteDoc(doc(loser.db,'smallTeamMembers','classroom_'+classId+'_'+winner.user.uid)));
  await denied(()=>getDoc(doc(loser.db,'smallTeamMembers','classroom_'+classId+'_'+winner.user.uid)));
  await denied(()=>getDocs(collection(loser.db,'smallTeamMembers')));
  check((await getDocs(query(collection(winner.db,'smallTeamMembers'),where('uid','==',winner.user.uid)))).size===1);
  const metadata=(await getDoc(doc(loser.db,'smallTeams','classroom_'+classId))).data();
  check(Object.keys(metadata).sort().join(',')==='communityId,count,scope,updatedAt');
  await denied(()=>setDoc(doc(loser.db,'smallTeams','classroom_'+classId),{...metadata,count:19,updatedAt:serverTimestamp()}));
  phase='group last-place race';
  for(const u of users.slice(0,19)) await save(u,membership(classId,[groupId]));
  const groups=await Promise.allSettled(users.slice(19,21).map(u=>save(u,membership(u===winner?classId:null,[groupId]))));
  check(groups.filter(r=>r.status==='fulfilled').length===1);
  check(['team-full','permission-denied'].includes(groups.find(r=>r.status==='rejected').reason.code));
  check(await count(winner,'group',groupId)===20);
  const groupLoser=users[19+groups.findIndex(r=>r.status==='rejected')];
  await denied(()=>save(groupLoser,membership(groupLoser===winner?classId:null,[groupId]),{ignoreCapacity:true}));
  phase='failed switch is atomic';
  const spare=seed+'-spare';
  const loserGroups=(await getDoc(doc(loser.db,'playerAccounts',loser.user.uid))).data()?.membership.groupIds??[];
  await save(loser,membership(spare,loserGroups));
  await assert.rejects(()=>save(loser,membership(classId)),e=>e.code==='team-full');passed++;
  check((await getDoc(doc(loser.db,'playerAccounts',loser.user.uid))).data().membership.classId===spare);
  check(await count(loser,'classroom',spare)===1);
  // Attempted new class reservation and a full group join must roll back together.
  const previous=(await getDoc(doc(groupLoser.db,'playerAccounts',groupLoser.user.uid))).data().membership;
  await assert.rejects(()=>save(groupLoser,membership(seed+'-new',[groupId])),e=>e.code==='team-full');passed++;
  check((await getDoc(doc(groupLoser.db,'playerAccounts',groupLoser.user.uid))).data().membership.classId===previous.classId);
  check(!(await getDoc(doc(groupLoser.db,'smallTeams','classroom_'+seed+'-new'))).exists());
  phase='leave and refill';
  await leaveTeamAccount(winner.db,winner.user.uid);check(await count(winner,'classroom',classId)===19);
  await save(loser,membership(classId));check(await count(loser,'classroom',classId)===20);
  // Country, city and school deliberately allow all 21 permanent players.
  for(const u of users.slice(0,21)) await save(u,membership());
  check(await count(winner,'classroom',classId)===0);
  check(await count(winner,'group',groupId)===0);
  phase='maximum supported atomic changes';
  const six=Array.from({length:6},(_,i)=>seed+'-six-'+i);
  await save(winner,membership(null,six));
  check((await getDocs(query(collection(winner.db,'smallTeamMembers'),where('uid','==',winner.user.uid)))).size===6);
  await leaveTeamAccount(winner.db,winner.user.uid);
  check((await getDocs(query(collection(winner.db,'smallTeamMembers'),where('uid','==',winner.user.uid)))).empty);
  const report={passed,classLimit:20,groupLimit:20,concurrentLastPlace:true,backendCap:true,idempotent:true,atomicSwitch:true,privateMembership:true,unboundedParents:true,maximumTransactionChanges:6,checkedAt:new Date().toISOString()};
  writeFileSync('releases/small-team-081-verification.json',JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));
} catch(e) {console.error('Team verification failed during '+phase+' after '+passed+' checks ('+(e.code??e.name)+')');console.error(String(e.message).replace(/https?:\/\/\S+/g,'[endpoint]').slice(0,400));process.exitCode=1;}
finally {
  for(const u of users) {
    try {await leaveTeamAccount(u.db,u.user.uid);const ref=doc(u.db,'playerAccounts',u.user.uid);if((await getDoc(ref)).exists()) await deleteDoc(ref);}
    catch(e) {console.error('Fixture team cleanup failed ('+(e.code??e.name)+')');process.exitCode=1;}
    try {await deleteUser(u.auth.currentUser??u.user);}catch {process.exitCode=1;console.error('Fixture auth cleanup failed');}
    await terminate(u.db);await deleteApp(u.app);
  }
}
