/* Dependency-free, deterministic ZIP builder. This creates a manual-install ZIP,
   NOT an rmskin. Rainmeter's official Skin Packager creates the latter. */
const fs=require('node:fs');
const path=require('node:path');
const zlib=require('node:zlib');
const crypto=require('node:crypto');
const root=path.resolve(__dirname,'..');
const version=JSON.parse(fs.readFileSync(path.join(root,'package.json'),'utf8')).version;
if(!/^\d+\.\d+\.\d+$/.test(version)) throw new Error('Invalid release version');
const target=path.join(root,'dist');
fs.mkdirSync(target,{recursive:true});
const files=new Map();
const source=path.join(root,'skin/Lunar');
const paths=['Lunar.ini','@Resources/Settings.inc',...['Astronomy','Alerts','Format','Widget'].map(n=>`@Resources/Scripts/${n}.lua`),
  ...Array.from({length:120},(_,i)=>`@Resources/Images/moon-${String(i).padStart(3,'0')}.png`)];
for(const relative of paths) {
  const file=path.join(source,relative);
  if(fs.lstatSync(file).isSymbolicLink()) throw new Error('Symlink refused');
  files.set(`Lunar/${relative}`,fs.readFileSync(file));
}
const settings=files.get('Lunar/@Resources/Settings.inc').toString('utf8');
if(!/^Notifications=0$/m.test(settings)) throw new Error('Release notifications must be disabled');
for(const doc of ['LICENSE','NOTICE.md','SECURITY.md','docs/configuration.md','docs/architecture.md','docs/validation.md'])
  files.set(`Lunar/@Resources/Docs/${path.basename(doc)}`,fs.readFileSync(path.join(root,doc)));
files.set('Lunar/@Resources/Docs/README.txt',Buffer.from(
  'Lunar '+version+' for Rainmeter 4.5.20+ on Windows 11\n\n'+
  'Copy the Lunar folder to your Rainmeter Skins directory, refresh all, then load Lunar.ini.\n'+
  'Edit @Resources/Settings.inc and refresh the skin. Set Latitude=-33 for Santiago orientation.\n'+
  'The OS local time zone is detected automatically. Notifications are disabled by default.\n'+
  'Uninstall: unload the skin and remove its Lunar folder. Back up Settings.inc and NotificationState.dat before upgrades.\n\n'+
  'See configuration.md, architecture.md, validation.md, SECURITY.md, NOTICE.md and LICENSE in this folder.\n'+
  'No external runtime, network access, telemetry, executable, registry edit, service or scheduled task.\n'));
const table=Array.from({length:256},(_,i)=>{
  let c=i; for(let n=0;n<8;n++) c=(c&1)?0xedb88320^(c>>>1):c>>>1;
  return c>>>0;
});
function crc32(data) {
  let crc=0xffffffff;
  for(const byte of data) crc=table[(crc^byte)&255]^(crc>>>8);
  return (crc^0xffffffff)>>>0;
}
const local=[],central=[],manifest=[];
let offset=0;
for(const [name,data] of [...files].sort(([a],[b])=>a<b?-1:a>b?1:0)) {
  const filename=Buffer.from(name,'utf8'), compressed=zlib.deflateRawSync(data,{level:9});
  const crc=crc32(data),dosDate=10273; // fixed 2000-01-01 for reproducible artifacts
  const header=Buffer.alloc(30);
  header.writeUInt32LE(0x04034b50); header.writeUInt16LE(20,4); header.writeUInt16LE(0x800,6);
  header.writeUInt16LE(8,8); header.writeUInt16LE(dosDate,12); header.writeUInt32LE(crc,14);
  header.writeUInt32LE(compressed.length,18); header.writeUInt32LE(data.length,22); header.writeUInt16LE(filename.length,26);
  local.push(header,filename,compressed);
  const entry=Buffer.alloc(46);
  entry.writeUInt32LE(0x02014b50); entry.writeUInt16LE(20,4); entry.writeUInt16LE(20,6);
  entry.writeUInt16LE(0x800,8); entry.writeUInt16LE(8,10); entry.writeUInt16LE(dosDate,14);
  entry.writeUInt32LE(crc,16); entry.writeUInt32LE(compressed.length,20); entry.writeUInt32LE(data.length,24);
  entry.writeUInt16LE(filename.length,28); entry.writeUInt32LE(offset,42);
  central.push(entry,filename);
  offset+=header.length+filename.length+compressed.length;
  manifest.push({path:name,bytes:data.length,sha256:crypto.createHash('sha256').update(data).digest('hex')});
}
const directory=Buffer.concat(central),end=Buffer.alloc(22);
end.writeUInt32LE(0x06054b50); end.writeUInt16LE(files.size,8); end.writeUInt16LE(files.size,10);
end.writeUInt32LE(directory.length,12); end.writeUInt32LE(offset,16);
const zip=Buffer.concat([...local,directory,end]);
const name=`Lunar-${version}.zip`;
fs.writeFileSync(path.join(target,name),zip);
fs.writeFileSync(path.join(target,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
fs.writeFileSync(path.join(target,'SHA256SUMS.txt'),`${crypto.createHash('sha256').update(zip).digest('hex')}  ${name}\n`);
console.log(`Built dist/${name}: ${files.size} allowlisted files, ${zip.length} bytes. No scripts outside Rainmeter Lua, plugins, state, or executables.`);
