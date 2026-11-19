import {readFileSync,writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
const sha=b=>createHash('sha256').update(b).digest('hex');
const checks=await Promise.all([
  ['privacy','store/site/privacy.html'],
  ['.well-known/assetlinks.json','store/site/.well-known/assetlinks.json'],
].map(async ([path,local])=>{
  const response=await fetch('https://satranc-platformu.web.app/'+path,{signal:AbortSignal.timeout(15000)});
  const body=Buffer.from(await response.arrayBuffer());
  if(response.status!==200 || sha(body)!==sha(readFileSync(local))) throw new Error('Hosting source mismatch: '+path);
  return {path,status:response.status,matchesLocal:true};
}));
const response=await fetch('https://satranc-platformu.web.app/challenge/'+'0'.repeat(40),{signal:AbortSignal.timeout(15000)});
if(response.status!==200) throw new Error('Challenge page unavailable');
checks.push({path:'challenge/<40-hex-id>',status:response.status});
writeFileSync('releases/firebase-080-public-web-verification.json',JSON.stringify({checkedAt:new Date().toISOString(),checks},null,2)+'\n');
console.log(JSON.stringify(checks));
