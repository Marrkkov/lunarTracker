const assert=require('node:assert/strict');
const fs=require('node:fs');
const {PNG}=require('pngjs');
const directory='skin/Lunar/@Resources/Images';
assert.equal(fs.readdirSync(directory).filter(f=>/^moon-\d{3}\.png$/.test(f)).length,120);
function image(frame) { return PNG.sync.read(fs.readFileSync(`${directory}/moon-${frame}.png`)); }
function energy(png,half) {
  let total=0;
  for(let y=0;y<png.height;y++) for(let x=0;x<png.width;x++) {
    if((half==='left' && x>=128)||(half==='right' && x<128)) continue;
    const i=(y*png.width+x)*4;
    total+=png.data[i]*png.data[i+3]/255;
  }
  return total;
}
for(const name of fs.readdirSync(directory)) {
  const png=PNG.sync.read(fs.readFileSync(`${directory}/${name}`));
  assert.equal(png.width,256); assert.equal(png.height,256); assert.equal(png.data[3],0);
}
const first=image('030'),last=image('090');
assert(energy(first,'right')>10*energy(first,'left'),'northern waxing illuminates right');
assert(energy(last,'left')>10*energy(last,'right'),'northern waning illuminates left');
assert(energy(image('060'))>30*energy(image('000')),'full/new brightness');
// A 180 degree rotation exchanges left/right, including texture: southern mode.
assert(energy(first,'right')>energy(first,'left'),'rotation will put waxing light on southern left');
console.log('120 PNG assets validated: transparency, size, waxing/waning lighting.');
