// Development-only Lua VM. Fengari implements Lua 5.3; production stays Lua 5.1.
// Real Rainmeter/C-runtime integration is a separate Windows test.
const fs = require('node:fs');
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require('fengari');
process.env.TZ = 'America/Santiago';
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
function run(source, label) {
  if(lauxlib.luaL_loadbuffer(L,to_luastring(source),null,to_luastring(label)) !== lua.LUA_OK ||
    lua.lua_pcall(L,0,0,0) !== lua.LUA_OK) {
    throw new Error(to_jsstring(lua.lua_tostring(L,-1)));
  }
}
const quarters = {'New Moon':0,'First Quarter':1,'Full Moon':2,'Last Quarter':3};
let fixtureSource = 'fixtures = {\n';
let count = 0;
for (const year of [2000,2024,2026,2030,2049,2050]) {
  const json = JSON.parse(fs.readFileSync(`tests/fixtures/usno-${year}.json`,'utf8'));
  if(!json.phasedata || json.error) throw new Error('invalid USNO fixture');
  for(const event of json.phasedata) {
    const [hour,minute]=event.time.split(':').map(Number);
    const time=Date.UTC(event.year,event.month-1,event.day,hour,minute)/1000;
    fixtureSource += `{${time}.0,${quarters[event.phase]}},\n`;
    count++;
  }
}
run(fixtureSource+'}','fixtures');
let illumination='illuminationFixtures={\n';
for(const date of ['2026-10-29','2026-11-10','2026-11-20','2024-02-29']) {
  const data=JSON.parse(fs.readFileSync(`tests/fixtures/illumination-${date}.json`,'utf8')).properties.data;
  illumination+=`{${Date.UTC(data.year,data.month-1,data.day,12)/1000}.0,${parseFloat(data.fracillum)/100}},\n`;
}
run(illumination+'}','illumination');
run(fs.readFileSync('tests/spec.lua','utf8'),'spec.lua');
run(fs.readFileSync('tests/widget-spec.lua','utf8'),'widget-spec.lua');
require('./assets.cjs');
console.log(`Validated ${count} independent USNO event timestamps; timezone tests use Node/ICU America/Santiago.`);
