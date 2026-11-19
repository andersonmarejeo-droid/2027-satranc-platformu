import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';

const staging = process.argv[2] || path.dirname(fileURLToPath(import.meta.url));
const project = process.argv[3] || 'C:/Users/GiresuN/StudioProjects/ChessPlatform';
fs.mkdirSync(staging,{recursive:true});
const cities = JSON.parse(fs.readFileSync(path.join(project,'assets/data/schools/turkiye-schools.json'),'utf8')).cities;
const cache = path.join(staging,'private-pages');
fs.mkdirSync(cache,{recursive:true});
if(fs.existsSync(path.join(staging,'private-giresun.html')))fs.copyFileSync(path.join(staging,'private-giresun.html'),path.join(cache,'01.html'));
if(fs.existsSync(path.join(staging,'private-giresun-correct.html')))fs.copyFileSync(path.join(staging,'private-giresun-correct.html'),path.join(cache,'28.html'));
const decode = text => text.replace(/<[^>]*>/g,' ').replace(/&#x([0-9a-f]+);/gi,(_,n)=>String.fromCodePoint(parseInt(n,16)))
  .replace(/&#(\d+);/g,(_,n)=>String.fromCodePoint(Number(n)))
  .replace(/&(amp|quot|apos|lt|gt|nbsp);/g,(_,n)=>({amp:'&',quot:'"',apos:"'",lt:'<',gt:'>',nbsp:' '})[n])
  .replace(/\s+/g,' ').trim();
const normalize = text => text.toLocaleLowerCase('tr-TR').replace(/ı/g,'i').replace(/[ğüşıöç]/g,c=>({ğ:'g',ü:'u',ş:'s',ı:'i',ö:'o',ç:'c'})[c]).replace(/\s+/g,' ').trim();
const titleCase = text => text.toLocaleLowerCase('tr-TR').replace(/(^|\s)(\p{L})/gu,(_,space,letter)=>space+letter.toLocaleUpperCase('tr-TR'));

function parse(html,city) {
  const select = html.match(/<select\s+name="il"[^>]*>([\s\S]*?)<\/select>/i)?.[1];
  const selected = select?.match(/<option\s+selected\s+value="([^"]+)"/i)?.[1];
  if (selected !== city.name.toLocaleUpperCase('tr-TR')) throw Error(`Incorrect province response: ${city.name}/${selected}`);
  const count = html.match(/(\d+)\s+adet kurum bulundu/);
  if (!count) throw Error(`Missing institution count: ${city.name}`);
  const body = html.match(/<tbody>([\s\S]*?)<\/tbody>/i)?.[1] || '';
  const rows = [...body.matchAll(/<tr[^>]*>([\s\S]*?)<\/tr>/gi)].map(match=>{
    const cells = [...match[1].matchAll(/<td[^>]*>([\s\S]*?)<\/td>/gi)].map(c=>decode(c[1]));
    if (cells.length!==6 || !/^\d+$/.test(cells[0]) || !cells[1] || !cells[2]) throw Error(`Invalid private school row in ${city.name}`);
    const [district,name,type] = cells.slice(1,4);
    // Address participates only in a fingerprint to distinguish same-name
    // campuses; addresses and phone numbers aren't exported to the app.
    const identity = `${city.id}|${normalize(district)}|${normalize(name)}|${normalize(type)}|${normalize(cells[4])}`;
    const id = 'private-'+crypto.createHash('sha256').update(identity).digest('hex').slice(0,20);
    return [id,city.id,name,titleCase(district),type,null];
  });
  const links = [...html.matchAll(/class="page-link" href="([^"]+)"/g)].map(m=>new URL(decode(m[1]),'https://ookgm.meb.gov.tr/').href);
  return {cityId:city.id,code:city.code,total:Number(count[1]),count:rows.length,links,
    updatedAt:html.match(/Güncelleme:\s*([^<)]+)/)?.[1]?.trim() ?? null,rows};
}
let next=0,done=0,failed=false;
const results=[];
async function worker() {
  while(next<cities.length && !failed) {
    const city=cities[next++], file=path.join(cache,`${city.code}.html`);
    const url = new URL('https://ookgm.meb.gov.tr/kurumlar.php');
    url.searchParams.set('il',city.name.toLocaleUpperCase('tr-TR'));
    url.searchParams.set('tur','okul');
    url.searchParams.set('tur2','0');
    try {
      let html;
      if(fs.existsSync(file)) html=fs.readFileSync(file,'utf8');
      else {
        const response=await fetch(url,{signal:AbortSignal.timeout(60000),headers:{'User-Agent':'SatrancPlatformu-SchoolCatalog/0.7.2 (public school names only)'}});
        if(!response.ok) throw Error(`HTTP ${response.status}`);
        html=await response.text();
        // Validate province and full row count before caching or importing.
        parse(html,city);
        fs.writeFileSync(file,html);
      }
      const result=parse(html,city);
      result.pages=[{url:url.href,sha256:crypto.createHash('sha256').update(html).digest('hex')}];
      for (const pageLink of result.links) {
        const pageUrl=new URL(pageLink);
        const page=Number(pageUrl.searchParams.get('sayfa'));
        if(page===1)continue;
        if(pageUrl.origin!=='https://ookgm.meb.gov.tr' || pageUrl.pathname!=='/kurumlar.php' ||
            pageUrl.searchParams.get('il')!==city.name.toLocaleUpperCase('tr-TR') || page<2) throw Error('Unexpected pagination link');
        const pageFile=path.join(cache,`${city.code}-${page}.html`);
        let pageHtml;
        if(fs.existsSync(pageFile))pageHtml=fs.readFileSync(pageFile,'utf8');
        else {
          await new Promise(resolve=>setTimeout(resolve,750));
          const response=await fetch(pageUrl,{signal:AbortSignal.timeout(60000)});
          if(!response.ok)throw Error(`HTTP ${response.status}`);
          pageHtml=await response.text();
          parse(pageHtml,city);
          fs.writeFileSync(pageFile,pageHtml);
        }
        const parsed=parse(pageHtml,city);
        if(parsed.total!==result.total)throw Error('Source total changed during pagination');
        result.rows.push(...parsed.rows);
        result.pages.push({url:pageUrl.href,sha256:crypto.createHash('sha256').update(pageHtml).digest('hex')});
      }
      if(result.rows.length!==result.total)throw Error(`Incomplete province ${city.name}: ${result.rows.length}/${result.total}`);
      result.count=result.rows.length;
      delete result.links;
      result.url=url.href;
      result.sha256=crypto.createHash('sha256').update(html).digest('hex');
      results.push(result);
      done++;
      console.log(JSON.stringify({province:city.name,privateSchools:result.count,progress:`${done}/81`}));
      await new Promise(resolve=>setTimeout(resolve,750));
    } catch(error) { failed=true; throw Error(`${city.name}: ${error.message}`); }
  }
}
await Promise.all([worker(),worker()]);
if(results.length!==81)throw Error('All province responses required');
const allRows=results.flatMap(r=>r.rows);
const schools=[...new Map(allRows.map(s=>[s[0],s])).values()];
const source={upstream:'https://ookgm.meb.gov.tr/kurumlar.php',retrievedAt:new Date().toISOString(),category:'okul',provinces:81,schoolCount:schools.length,sourceRecordCount:allRows.length,duplicatesRemoved:allRows.length-schools.length,
  identity:'Source does not expose a MEB institution code. App IDs hash province/district/name/type/address to distinguish campuses; addresses are not exported and institutionCode remains null.',
  permission:'MEB reuse permission not established; legal review deferred by user.',
  pages:results.sort((a,b)=>a.code.localeCompare(b.code)).map(({rows,...meta})=>meta)};
fs.writeFileSync(path.join(staging,'private-schools.json'),JSON.stringify({version:1,source,schools}));
console.log(JSON.stringify({complete:true,provinces:81,privateSchools:schools.length,giresun:schools.filter(s=>s[1]==='giresun').length}));
