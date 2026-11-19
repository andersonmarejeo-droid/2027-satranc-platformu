// Recover disposable capacity-test identities left by interrupted SDK transport.
// Exact synthetic address pattern only; never prints identifiers or credentials.
const {createRequire}=require('node:module');
const {resolve}=require('node:path');
const ownerRequire=createRequire(resolve('.tools/firebase-cli/package.json'));
(async()=>{
  const firebase=ownerRequire('firebase-tools');
  await firebase.apps.list('ANDROID',{project:'satranc-platformu',nonInteractive:true});
  const {Client}=ownerRequire('firebase-tools/lib/apiv2');
  const auth=new Client({urlPrefix:'https://identitytoolkit.googleapis.com',apiVersion:'v1'});
  const db=new Client({urlPrefix:'https://firestore.googleapis.com',apiVersion:'v1'});
  let token,removed=0,zeroCounters=0;
  const fixtures=[];
  do {
    const response=await auth.get('/projects/satranc-platformu/accounts:batchGet',{queryParams:{maxResults:1000,...(token?{nextPageToken:token}:{})}});
    fixtures.push(...(response.body.users??[]).filter(u=>/^capacity-[0-9a-f]{20}-\d{1,2}@example\.invalid$/.test(u.email??'')));
    token=response.body.nextPageToken;
  } while(token);
  for(const u of fixtures) {
    const path='/projects/satranc-platformu/databases/(default)/documents/playerAccounts/'+u.localId;
    let record;
    try {record=(await db.get(path)).body;}catch(e) {if(e.status!==404) throw e;}
    if(record) {
      const m=record.fields.membership.mapValue.fields;
      if(m.classId.stringValue || (m.groupIds.arrayValue.values??[]).length) throw new Error('Fixture still has reserved places; refusing deletion');
      await db.delete(path,{queryParams:{'currentDocument.updateTime':record.updateTime}});
    }
    await auth.post('/projects/satranc-platformu/accounts:delete',{localId:u.localId});removed++;
  }
  token=undefined;
  do {
    const response=await db.get('/projects/satranc-platformu/databases/(default)/documents/smallTeams',{queryParams:{pageSize:1000,...(token?{pageToken:token}:{})}});
    for(const record of response.body.documents??[]) {
      if(/^capacity-[0-9a-f]{20}-/.test(record.fields.communityId.stringValue) && Number(record.fields.count.integerValue)===0) {
        await db.delete('/'+record.name,{queryParams:{'currentDocument.updateTime':record.updateTime}});zeroCounters++;
      }
    }
    token=response.body.nextPageToken;
  } while(token);
  console.log(JSON.stringify({interruptedSyntheticAccountsRemoved:removed,emptyFixtureCountersRemoved:zeroCounters,realAccountsTouched:false}));
})().catch(e=>{console.error('Fixture recovery failed ('+(e.status??e.code??e.name)+'): '+String(e.message).replace(/https?:\/\/\S+/g,'[endpoint]').slice(0,200));process.exitCode=1;});
