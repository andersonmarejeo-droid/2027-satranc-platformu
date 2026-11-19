// Normal client SDK checks against Spark. Only disposable fixtures are removed.
// Test-only e-mail identities use example.invalid; no e-mails are sent.
import {createRequire} from 'node:module';
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {randomBytes} from 'node:crypto';
import assert from 'node:assert/strict';
import {saveTeamAccount,leaveTeamAccount} from './firebase_team_fixture.mjs';
const require=createRequire(resolve('.tools/firebase-client/package.json'));
const {initializeApp,deleteApp}=require('firebase/app');
const {getAuth,signInAnonymously,linkWithCredential,EmailAuthProvider,reload,getIdToken,signOut,signInWithEmailAndPassword,deleteUser}=require('firebase/auth');
const {getFirestore,doc,setDoc,getDoc,deleteDoc,runTransaction,serverTimestamp,Timestamp,collection,query,where,getDocs,orderBy,getCount:getCountFromServer,terminate,setLogLevel}=require('firebase/firestore/lite');
const firebase=require(resolve('.tools/firebase-cli/node_modules/firebase-tools'));
const {Client}=require(resolve('.tools/firebase-cli/node_modules/firebase-tools/lib/apiv2'));
setLogLevel('silent');
const config=JSON.parse(readFileSync('android/app/google-services.json','utf8'));
const client=config.client.find(c=>c.client_info.android_client_info.package_name==='com.zpgames.satrancplatformu');
const settings={apiKey:client.api_key[0].current_key,projectId:config.project_info.project_id,
  appId:client.client_info.mobilesdk_app_id,authDomain:'satranc-platformu.firebaseapp.com'};
const apps=[],users=[],created=[];let passed=0;
const checked=(condition)=>{assert.ok(condition);passed++;};
async function denied(action) {await assert.rejects(action,e=>e.code==='permission-denied');passed++;}
const id=randomBytes(20).toString('hex');
const membership={version:1,countryId:'tr',cityId:'giresun',schoolId:'gfl',classId:'gfl-9a',groupIds:[]};
const profile=(alias)=>({alias,optIn:true,countryId:'tr',cityId:'giresun',schoolId:'gfl',classId:'gfl-9a',groupIds:[]});
function track(db,c,id) {created.push({db,c,id});return doc(db,c,id);}
async function move(db,uci) {
  await runTransaction(db,async tx=>{
    const ref=doc(db,'onlineMatches',id),v=(await tx.get(ref)).data(),field=v.moves.length%2===0?'whiteMs':'blackMs';
    tx.update(ref,{moves:[...v.moves,uci],drawBy:'',lastAt:serverTimestamp(),
      [field]:v[field]-Math.max(0,Date.now()-v.lastAt.toMillis())+v.increment*1000});
  });
}
const week=(time)=>'w'+Math.floor((time.toMillis()+3*86400000+10800000)/604800000);
const month=(time)=>{const d=new Date(time.toMillis()+10800000);return 'm'+(d.getUTCFullYear()*100+d.getUTCMonth()+1);};
function cardAndClaim(user,period,scope,communityId,points=3,matchId=id) {
  const uid=user.user.uid,cardId=`${period}_${scope}_${communityId}_${uid}`,claimId=`${cardId}_${matchId}`;
  return {cardId,claimId,
    card:{uid,period,scope,communityId,alias:user.alias,published:true,points,games:1,wins:points===3?1:0,draws:points===1?1:0,losses:points===0?1:0,lastClaim:claimId,updatedAt:serverTimestamp()},
    claim:{uid,period,scope,communityId,alias:user.alias,cardId,matchId,points,win:points===3?1:0,draw:points===1?1:0,loss:points===0?1:0,awardedAt:serverTimestamp()}};
}
async function award(user,value,{inflation=0}={}) {
  return runTransaction(user.db,async tx=>{
    const cardRef=doc(user.db,'communityScores',value.cardId),claimRef=doc(user.db,'scoreClaims',value.claimId);
    const existing=(await tx.get(cardRef)).data();
    tx.set(claimRef,value.claim);
    const card={...value.card};
    if(existing) for(const k of ['points','games','wins','draws','losses']) card[k]+=existing[k];
    card.points+=inflation;tx.set(cardRef,card);
  });
}
try {
  for(let i=0;i<3;i++) {
    const app=initializeApp(settings,'competition-check-'+randomBytes(6).toString('hex'));apps.push(app);
    const auth=getAuth(app),user=(await signInAnonymously(auth)).user;
    users.push({auth,user,db:getFirestore(app),alias:'Test oyuncusu '+(i+1)});
  }
  const [a,b,c]=users;
  for(const p of [a,b]) {
    p.email='chess-'+randomBytes(12).toString('hex')+'@example.invalid';p.password=randomBytes(24).toString('base64url');
    const uid=p.user.uid;
    await linkWithCredential(p.user,EmailAuthProvider.credential(p.email,p.password));
    checked(p.auth.currentUser.uid===uid);
    const ref=track(p.db,'playerAccounts',uid);
    await denied(()=>setDoc(ref,{displayName:p.alias,membership,rankingEnabled:true,updatedAt:serverTimestamp()}));
    await saveTeamAccount(p.db,uid,{displayName:p.alias,membership,rankingEnabled:false,updatedAt:serverTimestamp()});passed++;
  }
  console.log('Account linking and unverified-account restrictions passed');
  // The owner marks only these disposable synthetic fixture identities verified.
  await firebase.apps.list('ANDROID',{project:'satranc-platformu',nonInteractive:true});
  const owner=new Client({urlPrefix:'https://identitytoolkit.googleapis.com',apiVersion:'v1'});
  for(const p of [a,b]) {
    await owner.post('/projects/satranc-platformu/accounts:update',{localId:p.user.uid,emailVerified:true});
    await reload(p.user);await getIdToken(p.user,true);checked(p.user.emailVerified);
    await saveTeamAccount(p.db,p.user.uid,{displayName:p.alias,membership,rankingEnabled:true,updatedAt:serverTimestamp()});passed++;
  }
  await denied(()=>getDoc(doc(c.db,'playerAccounts',a.user.uid)));
  await denied(()=>setDoc(doc(c.db,'playerAccounts',a.user.uid),{displayName:'Other',membership,rankingEnabled:false,updatedAt:serverTimestamp()}));
  await signOut(a.auth);await signInWithEmailAndPassword(a.auth,a.email,a.password);a.user=a.auth.currentUser;
  checked((await getDoc(doc(a.db,'playerAccounts',a.user.uid))).data().membership.classId==='gfl-9a');
  const inviteRef=track(a.db,'onlineInvites',id);
  await setDoc(inviteRef,{creator:a.user.uid,guest:'',matchId:'',minutes:5,increment:2,
    createdAt:serverTimestamp(),expiresAt:Timestamp.fromMillis(Date.now()+3600000)});
  track(a.db,'onlineMatches',id);
  await runTransaction(b.db,async tx=>{
    await tx.get(doc(b.db,'onlineInvites',id));
    tx.set(doc(b.db,'onlineMatches',id),{participants:[a.user.uid,b.user.uid],minutes:5,increment:2,moves:[],createdAt:serverTimestamp(),lastAt:serverTimestamp(),whiteMs:300000,blackMs:300000});
    tx.update(doc(b.db,'onlineInvites',id),{guest:b.user.uid,matchId:id});
  });passed++;
  await setDoc(doc(a.db,'onlineMatches',id,'presence',a.user.uid),{seenAt:serverTimestamp()});passed++;
  checked((await getDoc(doc(b.db,'onlineMatches',id,'presence',a.user.uid))).exists());
  await denied(()=>setDoc(doc(b.db,'onlineMatches',id,'presence',a.user.uid),{seenAt:serverTimestamp()}));
  await denied(()=>getDoc(doc(c.db,'onlineMatches',id,'presence',a.user.uid)));
  await move(a.db,'f2f3');await move(b.db,'e7e5');await move(a.db,'g2g4');await move(b.db,'d8h4');passed++;
  const match=(await getDoc(doc(a.db,'onlineMatches',id))).data(),resultRef=track(a.db,'onlineResults',id);
  const result={participants:match.participants,ply:4,lastAt:match.lastAt,outcome:'black',reason:'mate',confirmedBy:[a.user.uid],profiles:{[a.user.uid]:profile(a.alias)},endedAt:serverTimestamp()};
  await setDoc(resultRef,result);passed++;
  await denied(()=>getDoc(doc(c.db,'onlineResults',id)));
  await denied(()=>setDoc(doc(c.db,'onlineResults',id),{...result,confirmedBy:[c.user.uid]}));
  await denied(()=>award(a,cardAndClaim(a,'all','school','gfl',0)));
  await denied(()=>setDoc(doc(a.db,'onlineResults',id),{...result,confirmedBy:[a.user.uid,b.user.uid],profiles:{[a.user.uid]:profile(a.alias),[b.user.uid]:profile(b.alias)}}));
  await runTransaction(b.db,async tx=>{
    const ref=doc(b.db,'onlineResults',id),r=(await tx.get(ref)).data();
    tx.update(ref,{confirmedBy:[...r.confirmedBy,b.user.uid],profiles:{...r.profiles,[b.user.uid]:profile(b.alias)}});
  });passed++;
  await denied(()=>move(a.db,'a2a3'));
  const sealed=(await getDoc(resultRef)).data(),period=week(sealed.endedAt);
  const accountRef=doc(b.db,'playerAccounts',b.user.uid);
  await setDoc(accountRef,{displayName:b.alias,membership,rankingEnabled:false,rankingCleanupPending:true,updatedAt:serverTimestamp()});passed++;
  checked((await getDoc(accountRef)).data().rankingCleanupPending===true);
  await denied(()=>award(b,cardAndClaim(b,period,'school','gfl')));
  await denied(()=>setDoc(accountRef,{displayName:b.alias,membership,rankingEnabled:true,rankingCleanupPending:true,updatedAt:serverTimestamp()}));
  await setDoc(accountRef,{displayName:b.alias,membership,rankingEnabled:true,rankingCleanupPending:false,updatedAt:serverTimestamp()});passed++;
  await denied(()=>award(b,cardAndClaim(b,period,'school','other-school')));
  await denied(()=>award(b,cardAndClaim(b,'w0','school','gfl')));
  await denied(()=>award(b,cardAndClaim(b,period,'school','gfl',999)));
  const bAward=cardAndClaim(b,period,'school','gfl');
  await denied(()=>award(b,bAward,{inflation:100}));
  for(const p of ['all',period,month(sealed.endedAt)]) {
    const value=cardAndClaim(b,p,'school','gfl');
    await award(b,value);track(b.db,'communityScores',value.cardId);track(b.db,'scoreClaims',value.claimId);passed++;
  }
  const aAward=cardAndClaim(a,period,'school','gfl',0);
  await award(a,aAward);track(a.db,'communityScores',aAward.cardId);track(a.db,'scoreClaims',aAward.claimId);passed++;
  await denied(()=>award(b,bAward));
  await denied(()=>deleteDoc(doc(b.db,'scoreClaims',bAward.claimId)));
  await denied(()=>setDoc(doc(b.db,'communityScores',bAward.cardId),{...bAward.card,points:1000}));
  const publicQuery=query(collection(c.db,'communityScores'),where('published','==',true),where('scope','==','school'),where('communityId','==','gfl'),where('period','==',period),orderBy('points','desc'),orderBy('uid'));
  let standings;
  for(let attempt=0;attempt<12;attempt++) {
    try {standings=await getDocs(publicQuery);break;}
    catch(e) {if(e.code!=='failed-precondition'||attempt===11) throw e;await new Promise(r=>setTimeout(r,10000));}
  }
  const mine=standings.docs.filter(d=>[a.user.uid,b.user.uid].includes(d.data().uid));
  checked(mine.length===2 && mine[0].data().points===3 && mine[1].data().points===0);
  const higher=await getCountFromServer(query(collection(c.db,'communityScores'),where('published','==',true),where('scope','==','school'),where('communityId','==','gfl'),where('period','==',period),where('points','>',0)));
  checked(higher.data().count>=1);
  await denied(()=>deleteDoc(doc(c.db,'communityScores',bAward.cardId)));
  const suggestionId=a.user.uid+'_'+randomBytes(16).toString('hex'),suggestion=track(a.db,'schoolSuggestions',suggestionId);
  await setDoc(suggestion,{uid:a.user.uid,cityId:'giresun',district:'Test ilçe',schoolName:'Test okul kaydı',createdAt:serverTimestamp()});passed++;
  await denied(()=>getDoc(doc(c.db,'schoolSuggestions',suggestionId)));
  console.log(JSON.stringify({passed,accountLinking:true,privateBackup:true,resultQuorum:true,idempotentScores:true,
    publicStandings:true,periodValidation:true,presencePrivacy:true,schoolSuggestionsPrivate:true}));
} catch(e) {
  console.error('Competition verification failed after '+passed+' checks ('+(e.code??e.status??e.name)+')');
  if(['failed-precondition','permission-denied'].includes(e.code)) {
    console.error(String(e.message).replace(/https?:\/\/\S+/g,'[console link]').slice(0,800));
  }
  process.exitCode=1;
}
finally {
  for(const type of ['communityScores','scoreClaims','schoolSuggestions','onlineResults','onlineMatches','onlineInvites','playerAccounts']) {
    for(const row of created.filter(x=>x.c===type)) {
      try {
        if(type==='onlineMatches') {
          const presence=await getDocs(collection(row.db,type,row.id,'presence'));
          for(const p of presence.docs) await deleteDoc(p.ref);
        }
        if(type==='playerAccounts') await leaveTeamAccount(row.db,row.id);
        await deleteDoc(doc(row.db,row.c,row.id));
      } catch (_) {console.error('Fixture cleanup failed: '+type);process.exitCode=1;}
    }
  }
  for(const u of users) {try {await deleteUser(u.auth.currentUser??u.user);}catch(_) {console.error('Fixture auth cleanup failed');process.exitCode=1;}try {await terminate(u.db);}catch(_) {}}
  for(const app of apps) await deleteApp(app);
}
