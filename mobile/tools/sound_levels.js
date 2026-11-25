// 효과음과 배경 소리의 크기를 잰다. 저장소 루트에서 `node mobile/tools/sound_levels.js` (Playwright 필요).
// thud: 기록실(5장) 바닥의 빛이 지나갈 때의 둔탁한 소리. 배경 'vault'는 setTimeout으로 울려 오프라인 렌더로는 재지 않는다.
// thudFar: 사흘 밤(6장) 서쪽 거리에서 땅 밑으로 아주 작게 들리는 뿌리의 소리. 배경 'nights'도 setTimeout으로 울려 재지 않는다.
// full: 전 대역, phone: 300Hz 아래와 9kHz 위를 깎아 휴대전화 스피커를 흉내 낸 값. st=50ms 최대 RMS, peak, avg(dBFS).
const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 390, height: 780 } });
  const errs = []; p.on('pageerror', e => errs.push(e.message));
  await p.goto('file://' + require('path').resolve(__dirname, '../index.html'));
  const res = await p.evaluate(async () => {
    const SR = 44100;
    async function measure(fn, secs, phone) {
      const off = new OfflineAudioContext(1, SR * secs, SR);
      let dest = off.destination;
      if (phone) { // 휴대전화 스피커 흉내: 300Hz 아래 24dB/oct로 깎음, 9kHz 위 깎음
        const h1 = off.createBiquadFilter(), h2 = off.createBiquadFilter(), l = off.createBiquadFilter();
        h1.type = h2.type = 'highpass'; h1.frequency.value = h2.frequency.value = 300; l.type = 'lowpass'; l.frequency.value = 9000;
        h1.connect(h2).connect(l).connect(off.destination); dest = h1;
      }
      Object.defineProperty(off, 'destination', { value: dest });
      SFX._use(off); fn();
      const buf = await off.startRendering(); const d = buf.getChannelData(0);
      let peak = 0, maxRms = 0, sum = 0; const W = Math.floor(SR * .05);
      for (let i = 0; i < d.length; i++) { peak = Math.max(peak, Math.abs(d[i])); }
      for (let i = 0; i + W <= d.length; i += Math.floor(W / 2)) { let s = 0; for (let j = i; j < i + W; j++) s += d[j] * d[j]; maxRms = Math.max(maxRms, Math.sqrt(s / W)); }
      for (let i = 0; i < d.length; i++) sum += d[i] * d[i];
      const db = x => x > 0 ? +(20 * Math.log10(x)).toFixed(1) : -120;
      return { peak: db(peak), st: db(maxRms), avg: db(Math.sqrt(sum / d.length)) };
    }
    S.mute = false;
    const cases = {
      ok: () => SFX.ok(1), ok10: () => SFX.ok(10), bigOk: () => SFX.bigOk(5), bad: () => SFX.bad(), blur: () => SFX.blur(),
      lock: () => SFX.lock(), tick: () => SFX.tick(), page: () => SFX.page(), lore: () => SFX.lore(), coin: () => SFX.coin(),
      scratch8: () => SFX.scratch(8), scatter: () => SFX.scatter(), cut: () => SFX.cut(), hurt: () => SFX.hurt(),
      yarn: () => SFX.yarn(), fix: () => SFX.fix(), clock: () => SFX.clock(), thud: () => SFX.clock(BAL.thudVol), thudFar: () => SFX.clock(BAL.thudFar), bugs: () => SFX.bugs(), dawnKept: () => SFX.dawn(true), dawnTorn: () => SFX.dawn(false),
    };
    const out = {};
    for (const [k, fn] of Object.entries(cases)) out[k] = { full: await measure(fn, 2, false), phone: await measure(fn, 2, true) };
    S.onboarded = true;
    for (const k of ['wind', 'breeze', 'city', 'frost', 'night']) {
      const fn = () => { SFX.amb(null); SFX.amb(k); if (k === 'night') { /* 해체자 많을 때 */ } };
      out['amb_' + k] = { full: await measure(fn, 8, false), phone: await measure(fn, 8, true) };
    }
    return out;
  });
  console.log('name'.padEnd(10), 'full(st/peak)'.padEnd(16), 'phone(st/peak/avg)');
  for (const [k, v] of Object.entries(res)) console.log(k.padEnd(10), (v.full.st + '/' + v.full.peak).padEnd(16), v.phone.st + '/' + v.phone.peak + '/' + v.phone.avg);
  console.log('errors', errs);
  await b.close();
})();
