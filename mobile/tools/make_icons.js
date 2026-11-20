// icons/icon.svg에서 PNG 아이콘을 만든다. 저장소 루트에서: node mobile/tools/make_icons.js
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const dir = path.join(__dirname, '..', 'icons');
const svg = fs.readFileSync(path.join(dir, 'icon.svg'), 'utf8');
const jobs = [
  ['icon-192.png', 192, 1], ['icon-512.png', 512, 1], ['apple-touch-icon.png', 180, 1],
  // 마스크용: 안드로이드가 둥글게 잘라도 그림이 남도록 가운데 80% 안에 넣는다
  ['icon-maskable-512.png', 512, .8],
];
(async () => {
  const b = await chromium.launch(); const p = await b.newPage();
  for (const [name, size, scale] of jobs) {
    await p.setViewportSize({ width: size, height: size });
    const inner = Math.round(size * scale), off = Math.round((size - inner) / 2);
    await p.setContent(`<html><body style="margin:0;background:#0f1512;width:${size}px;height:${size}px">
      <div style="position:absolute;left:${off}px;top:${off}px;width:${inner}px;height:${inner}px">${svg.replace('<svg ', `<svg width="${inner}" height="${inner}" `)}</div></body></html>`);
    await p.screenshot({ path: path.join(dir, name), omitBackground: false });
    console.log(name, size);
  }
  await b.close();
})();
