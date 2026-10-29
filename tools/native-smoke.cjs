/* Development only: prepares an isolated Rainmeter profile IN this workspace.
   Never installs a skin into the user's existing Rainmeter profile. */
const fs=require('node:fs');
const path=require('node:path');
const root=path.resolve(__dirname,'..');
const target=path.join(root,'tests/.native');
fs.mkdirSync(path.join(target,'Skins/Probe'),{recursive:true});
// Stage only production files; later changes must re-run this script.
fs.cpSync(path.join(root,'skin/Lunar'),path.join(target,'Skins/Lunar'),{recursive:true});
if(process.argv.includes('--alert')) {
  // Test-only frozen astronomical instant; never change the OS clock or source.
  const script=path.join(target,'Skins/Lunar/@Resources/Scripts/Widget.lua');
  const shim="\nlocal productionInitialize=Initialize\nfunction Initialize()\n"+
    "local testAstronomy=dofile(SKIN:GetVariable('@')..'Scripts\\\\Astronomy.lua')\n"+
    'local testInstant=math.ceil(testAstronomy.event(332,2))\n'+
    'os.time=function() return testInstant end\nproductionInitialize()\nend\n';
  fs.appendFileSync(script,shim);
  const setting=path.join(target,'Skins/Lunar/@Resources/Settings.inc');
  fs.writeFileSync(setting,fs.readFileSync(setting,'utf8').replace('Notifications=0','Notifications=1'));
  console.log('Staged TEST-ONLY occurrence alert at a frozen event; OS clock unchanged.');
}
const quarters={'New Moon':0,'First Quarter':1,'Full Moon':2,'Last Quarter':3};
let fixture='fixtures={\n';
for(const year of [2000,2024,2026,2030,2049,2050]) {
  const json=JSON.parse(fs.readFileSync(path.join(root,`tests/fixtures/usno-${year}.json`),'utf8'));
  for(const e of json.phasedata) {
    const [h,m]=e.time.split(':').map(Number);
    fixture+=`{${Date.UTC(e.year,e.month-1,e.day,h,m)/1000}.0,${quarters[e.phase]}},\n`;
  }
}
fs.writeFileSync(path.join(target,'Fixtures.lua'),fixture+'}\n');
let illumination='illuminationFixtures={\n';
for(const date of ['2026-10-29','2026-11-10','2026-11-20','2024-02-29']) {
  const data=JSON.parse(fs.readFileSync(path.join(root,`tests/fixtures/illumination-${date}.json`),'utf8')).properties.data;
  illumination+=`{${Date.UTC(data.year,data.month-1,data.day,12)/1000}.0,${parseFloat(data.fracillum)/100}},\n`;
}
fs.appendFileSync(path.join(target,'Fixtures.lua'),illumination+'}\n');
const config=`[Rainmeter]\nLogging=1\nDisableVersionCheck=1\nSkinPath=${target}\\Skins\\\n\n[Lunar]\nActive=1\nWindowX=200\nWindowY=150\nDraggable=1\n\n[Probe]\nActive=1\nWindowX=0\nWindowY=0\n`;
const ini=`[Rainmeter]\nUpdate=1000\n[MeasureProbe]\nMeasure=Script\nScriptFile=${root}\\tests\\native-probe.lua\nProjectRoot=${root}\\\nTestRoot=${target}\\\n[MeterDummy]\nMeter=String\nText=\n`;
// Windows profile INIs use UTF-16LE BOM to preserve non-ASCII directory names.
for(const [file,text] of [['Rainmeter.ini',config],['Skins/Probe/Probe.ini',ini]])
  fs.writeFileSync(path.join(target,file),Buffer.concat([Buffer.from([255,254]),Buffer.from(text,'utf16le')]));
console.log(`Prepared isolated profile: ${path.join(target,'Rainmeter.ini')}`);
