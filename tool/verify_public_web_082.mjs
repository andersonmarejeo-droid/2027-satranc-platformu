import {readFileSync, writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
const sha = bytes => createHash('sha256').update(bytes).digest('hex');
const checks = await Promise.all([
  ['privacy', 'store/site/privacy.html'],
  ['.well-known/assetlinks.json', 'store/site/.well-known/assetlinks.json'],
  ['', 'store/site/index.html'],
  ['challenge/' + '0'.repeat(40), 'store/site/challenge.html'],
].map(async ([path, local]) => {
  const response = await fetch('https://satranc-platformu.web.app/' + path, {signal: AbortSignal.timeout(15000)});
  const body = Buffer.from(await response.arrayBuffer());
  if (response.status !== 200 || sha(body) !== sha(readFileSync(local))) throw new Error('Hosting source mismatch: ' + path);
  return {path: path.startsWith('challenge/') ? 'challenge/<40-hex-id>' : path || '/', status: response.status, matchesLocal: true};
}));
writeFileSync('releases/firebase-082-public-web-verification.json', JSON.stringify({checkedAt: new Date().toISOString(), checks}, null, 2) + '\n');
console.log(JSON.stringify(checks));
