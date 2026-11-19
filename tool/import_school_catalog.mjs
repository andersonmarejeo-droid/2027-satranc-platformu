import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';

const staging = process.argv[3] || path.dirname(fileURLToPath(import.meta.url));
const project = process.argv[2];
if (!project || !fs.existsSync(path.join(project, 'pubspec.yaml'))) throw Error('Flutter project required');
const bytes = fs.readFileSync(path.join(staging, 'meb-okullar.json'));
const records = JSON.parse(bytes.toString('utf8'));
const commit = JSON.parse(fs.readFileSync(path.join(staging, 'source-commit.json'), 'utf8')).sha;
const names = 'Adana|Adıyaman|Afyonkarahisar|Ağrı|Amasya|Ankara|Antalya|Artvin|Aydın|Balıkesir|Bilecik|Bingöl|Bitlis|Bolu|Burdur|Bursa|Çanakkale|Çankırı|Çorum|Denizli|Diyarbakır|Edirne|Elazığ|Erzincan|Erzurum|Eskişehir|Gaziantep|Giresun|Gümüşhane|Hakkari|Hatay|Isparta|Mersin|İstanbul|İzmir|Kars|Kastamonu|Kayseri|Kırklareli|Kırşehir|Kocaeli|Konya|Kütahya|Malatya|Manisa|Kahramanmaraş|Mardin|Muğla|Muş|Nevşehir|Niğde|Ordu|Rize|Sakarya|Samsun|Siirt|Sinop|Sivas|Tekirdağ|Tokat|Trabzon|Tunceli|Şanlıurfa|Uşak|Van|Yozgat|Zonguldak|Aksaray|Bayburt|Karaman|Kırıkkale|Batman|Şırnak|Bartın|Ardahan|Iğdır|Yalova|Karabük|Kilis|Osmaniye|Düzce'.split('|');
const cities = names.map((name, i) => ({id: ({Giresun:'giresun', İstanbul:'istanbul', Ankara:'ankara'})[name] || `tr-${String(i+1).padStart(2,'0')}`, name, code: String(i+1).padStart(2,'0')}));
const byName = new Map(cities.map(c => [c.name,c]));
const excluded = [];
const seen = new Set();
const schools = [];
for (const row of records) {
  const city = byName.get(row.il);
  if (!city) { excluded.push(row); continue; }
  if (!/^\d{6}$/.test(row.kurum_kodu) || !row.okul_adi?.trim() || !row.ilce?.trim()) throw Error('Invalid school row');
  if (seen.has(row.kurum_kodu)) throw Error(`Duplicate institution ${row.kurum_kodu}`);
  seen.add(row.kurum_kodu);
  const id = ({'962238':'gfl', '150926':'gl'})[row.kurum_kodu] || `meb-${row.kurum_kodu}`;
  schools.push([id, city.id, row.okul_adi.trim(), row.ilce.trim(), row.okul_turu, row.kurum_kodu]);
}
if (records.length !== 55216 || schools.length !== 55117 || excluded.length !== 99 || cities.length !== 81) throw Error('Unexpected source totals');
if (cities.some(c => !schools.some(s => s[1] === c.id))) throw Error('Missing province coverage');
const source = {
  repository: 'https://github.com/dalgali/MEB-okul-listesi', commit,
  upstream: 'https://www.meb.gov.tr/baglantilar/okullar/', capturedAt: '2026-08-31',
  downloadedAt: new Date().toISOString(), sourceSha256: crypto.createHash('sha256').update(bytes).digest('hex'),
  sourceRecordCount: records.length, includedCount: schools.length, excludedNonProvinceCount: excluded.length,
  coverage: 'Source snapshot of public MEB school/institution websites; not a verified exhaustive list of all public/private schools.',
  repositoryLicense: 'MIT', upstreamPermission: 'Not established; legal review pending. Repository license does not prove MEB permission.',
  schoolType: 'Inferred from institution name by source, not verified official classification.',
};
const dir = path.join(project, 'assets', 'data', 'schools');
fs.mkdirSync(dir, {recursive: true});
fs.writeFileSync(path.join(dir, 'turkiye-schools.json'), JSON.stringify({version: 1, source, cities, schools}));
fs.copyFileSync(path.join(staging, 'LICENSE'), path.join(dir, 'LICENSE.txt'));
fs.writeFileSync(path.join(dir, 'SOURCE.json'), JSON.stringify(source, null, 2) + '\n');
fs.writeFileSync(path.join(staging, 'excluded-non-province.json'), JSON.stringify(excluded, null, 2));
console.log(JSON.stringify({cities: cities.length, schools: schools.length, giresun: schools.filter(s=>s[1]==='giresun').length, excluded:excluded.length, bytes:fs.statSync(path.join(dir,'turkiye-schools.json')).size, commit}));
