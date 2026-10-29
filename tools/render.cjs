/* Development only. Orthographic near-side projection of NASA's 2019 LROC map.
   Reproducible 120-frame phase set, spherical lighting, no runtime rendering code. */
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const jpeg = require('jpeg-js');
const { PNG } = require('pngjs');
const source = fs.readFileSync(path.join(__dirname, 'lroc_color_poles_1k.jpg'));
const texture = jpeg.decode(source, { useTArray: true, maxMemoryUsageInMB: 32 });
const size = 256;
const output = path.join(__dirname, '../skin/Lunar/@Resources/Images');
fs.mkdirSync(output, { recursive: true });
const surface = [];
for (let y = 0; y < size; y++) {
  for (let x = 0; x < size; x++) {
    const nx = (x + .5 - size / 2) / (size / 2 - 2);
    const ny = -(y + .5 - size / 2) / (size / 2 - 2);
    const r2 = nx * nx + ny * ny;
    if (r2 > 1) { surface.push(null); continue; }
    const nz = Math.sqrt(1 - r2);
    // East is screen-right; zero longitude is map center, lunar north at top.
    const u = .5 + Math.atan2(nx, nz) / (2 * Math.PI);
    const v = .5 - Math.asin(ny) / Math.PI;
    const tx = Math.min(texture.width - 1, Math.floor(u * texture.width));
    const ty = Math.min(texture.height - 1, Math.floor(v * texture.height));
    const i = 4 * (ty * texture.width + tx);
    const albedo = .2126 * texture.data[i] + .7152 * texture.data[i+1] + .0722 * texture.data[i+2];
    const alpha = Math.min(1, (1-Math.sqrt(r2))*(size/2-2));
    surface.push({ nx, nz, albedo, alpha });
  }
}
for (let frame = 0; frame < 120; frame++) {
  const angle = frame / 120 * 2 * Math.PI;
  const sx = Math.sin(angle), sz = -Math.cos(angle);
  const png = new PNG({ width: size, height: size });
  surface.forEach((point, index) => {
    if (!point) return;
    const lit = Math.max(0, point.nx * sx + point.nz * sz);
    // Mild artistic earthshine + softened Lambert shading; not a photometric model.
    const brightness = .018 + .982 * Math.pow(lit, .32);
    const value = Math.min(255, point.albedo * 1.4 * brightness);
    const i = index * 4;
    png.data[i] = value * .97; png.data[i+1] = value * .985; png.data[i+2] = value;
    png.data[i+3] = Math.round(point.alpha * 255);
  });
  fs.writeFileSync(path.join(output, `moon-${String(frame).padStart(3,'0')}.png`), PNG.sync.write(png));
}
const contact = new PNG({width: 1024, height: 512});
[0,15,30,45,60,75,90,105].forEach((frame,index) => {
  const png = PNG.sync.read(fs.readFileSync(path.join(output,`moon-${String(frame).padStart(3,'0')}.png`)));
  PNG.bitblt(png,contact,0,0,size,size,(index%4)*size,Math.floor(index/4)*size);
});
fs.writeFileSync(path.join(__dirname,'../docs/previews/phases.png'), PNG.sync.write(contact));
console.log(`Rendered 120 transparent ${size}px frames; source SHA256 ${crypto.createHash('sha256').update(source).digest('hex')}`);
