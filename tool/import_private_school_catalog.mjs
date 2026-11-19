import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const staging=process.argv[3]||path.dirname(fileURLToPath(import.meta.url));
const project=process.argv[2];
const file=path.join(project,'assets/data/schools');
const publicCatalogue=JSON.parse(fs.readFileSync(path.join(file,'turkiye-schools.json'),'utf8'));
const privateCatalogue=JSON.parse(fs.readFileSync(path.join(staging,'private-schools.json'),'utf8'));
if(privateCatalogue.source.pages.length!==81)throw Error('All province pages required');
const norm=s=>s.toLocaleLowerCase('tr-TR').replace(/\s+/g,' ').trim();
const key=row=>`${row[1]}|${norm(row[2])}|${norm(row[3])}`;
const publicKeys=new Set(publicCatalogue.schools.map(key));
const schools=privateCatalogue.schools.filter(row=>!publicKeys.has(key(row)));
const source={...privateCatalogue.source,capturedAt:privateCatalogue.source.retrievedAt.slice(0,10),
  includedCount:schools.length,alreadyInPublicCatalogue:privateCatalogue.schools.length-schools.length};
if(new Set(schools.map(s=>s[0])).size!==schools.length)throw Error('Duplicate private app IDs');
fs.writeFileSync(path.join(file,'private-schools.json'),JSON.stringify({version:1,source,schools}));
fs.writeFileSync(path.join(file,'PRIVATE_SOURCE.json'),JSON.stringify(source,null,2)+'\n');
const counts={publicInstitutions:publicCatalogue.schools.length,privateSchools:schools.length,
  totalInstitutions:publicCatalogue.schools.length+schools.length,provinces:81,
  giresunPublic:publicCatalogue.schools.filter(s=>s[1]==='giresun').length,
  giresunPrivate:schools.filter(s=>s[1]==='giresun').length,
  privateSourceRows:privateCatalogue.source.sourceRecordCount,
  privateSourceDuplicates:privateCatalogue.source.duplicatesRemoved,
  alreadyInPublicCatalogue:source.alreadyInPublicCatalogue};
fs.writeFileSync(path.join(staging,'combined-counts.json'),JSON.stringify(counts,null,2)+'\n');
console.log(JSON.stringify(counts));
