// Ordinary client transaction used by disposable live-rule checks.
import {createRequire} from 'node:module';
import {resolve} from 'node:path';
const require=createRequire(resolve('.tools/firebase-client/package.json'));
const {doc,runTransaction,serverTimestamp}=require('firebase/firestore/lite');
export function teams(membership) {
  return new Map([...(membership.classId?[['classroom_'+membership.classId,['classroom',membership.classId]]]:[]),
    ...membership.groupIds.map(id=>['group_'+id,['group',id]])]);
}
export async function saveTeamAccount(db,uid,account,{ignoreCapacity=false}={}) {
  return runTransaction(db,async tx=>{
    const ref=doc(db,'playerAccounts',uid),old=(await tx.get(ref)).data();
    const target=teams(account.membership),previous=old?teams(old.membership):new Map(),changes=[];
    for(const [key,[scope,id]] of new Map([...previous,...target])) {
      const counterRef=doc(db,'smallTeams',key),memberRef=doc(db,'smallTeamMembers',key+'_'+uid);
      const counter=(await tx.get(counterRef)).data(),member=await tx.get(memberRef);
      const count=counter?.count??0,joining=target.has(key);
      if(joining===member.exists()) continue;
      if(joining && count>=20 && !ignoreCapacity) throw Object.assign(new Error('Team full'),{code:'team-full'});
      if(!joining && count<=0) throw new Error('Invalid counter');
      changes.push({counterRef,memberRef,scope,id,count,joining});
    }
    if(changes.length>6) throw new Error('Too many team changes');
    for(const c of changes) {
      tx.set(c.counterRef,{scope:c.scope,communityId:c.id,count:c.count+(c.joining?1:-1),updatedAt:serverTimestamp()});
      if(c.joining) tx.set(c.memberRef,{uid,scope:c.scope,communityId:c.id,joinedAt:serverTimestamp()});
      else tx.delete(c.memberRef);
    }
    tx.set(ref,account);
  });
}
export async function leaveTeamAccount(db,uid) {
  const {getDoc}=require('firebase/firestore/lite');
  const snapshot=await getDoc(doc(db,'playerAccounts',uid));
  if(!snapshot.exists()) return;
  let account=snapshot.data();
  while(account.membership.classId || account.membership.groupIds.length) {
    const budget=6-(account.membership.classId?1:0);
    account={...account,membership:{...account.membership,classId:null,groupIds:account.membership.groupIds.slice(budget)},rankingEnabled:false,updatedAt:serverTimestamp()};
    await saveTeamAccount(db,uid,account);
  }
}
