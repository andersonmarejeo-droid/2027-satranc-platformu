// Read-only owner inventory. Only counts are printed; no account identifiers or names.
const {createRequire}=require('node:module');
const {resolve}=require('node:path');
const {writeFileSync}=require('node:fs');
const ownerRequire=createRequire(resolve('.tools/firebase-cli/package.json'));
(async()=>{
  const firebase=ownerRequire('firebase-tools');
  await firebase.apps.list('ANDROID',{project:'satranc-platformu',nonInteractive:true});
  const {Client}=ownerRequire('firebase-tools/lib/apiv2');
  const client=new Client({urlPrefix:'https://firestore.googleapis.com',apiVersion:'v1'});
  const teams=new Map();let accounts=0,token;
  do {
    const response=await client.get('/projects/satranc-platformu/databases/(default)/documents/playerAccounts',{queryParams:{pageSize:100,...(token?{pageToken:token}:{})}});
    for(const doc of response.body.documents??[]) {
      accounts++;
      const membership=doc.fields?.membership?.mapValue?.fields??{};
      const ids=[...(membership.classId?.stringValue?[['classroom',membership.classId.stringValue]]:[]),
        ...(membership.groupIds?.arrayValue?.values??[]).map(v=>['group',v.stringValue])];
      for(const [scope,id] of ids) {const key=scope+'_'+id;teams.set(key,(teams.get(key)??0)+1);}
    }
    token=response.body.nextPageToken;
  } while(token);
  const result={checkedAt:new Date().toISOString(),accounts,teams:teams.size,maximumMembers:Math.max(0,...teams.values()),overCapacity:[...teams].filter(([,count])=>count>20).map(([team,count])=>({team,count}))};
  writeFileSync('releases/small-team-inventory.json',JSON.stringify(result,null,2)+'\n');
  console.log(JSON.stringify(result));
})().catch(e=>{console.error('Inventory failed ('+(e.status??e.code??e.name)+')');console.error(String(e.message).replace(/https?:\/\/\S+/g,'[endpoint]').slice(0,600));console.error(JSON.stringify({underlying:e.original?.code,cause:e.original?.cause?.code,message:e.original?.message?.replace(/https?:\/\/\S+/g,'[endpoint]'),causeMessage:e.original?.cause?.message?.replace(/https?:\/\/\S+/g,'[endpoint]')}));process.exitCode=1;});
