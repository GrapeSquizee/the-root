// THE ROOT 모바일 서비스 워커: 한 번 열면 비행기 모드에서도 돌아가게 한다.
// 게임 파일(index.html)은 네트워크를 먼저 보고, 안 되면 저장해 둔 것을 쓴다(새 버전이 바로 들어오게).
// 아이콘과 manifest는 저장해 둔 것을 먼저 쓴다. 파일을 바꾸면 VERSION을 올린다.
const VERSION = 'the-root-v0.9';
const FILES = ['./', './index.html', './manifest.webmanifest',
  './icons/icon.svg', './icons/icon-192.png', './icons/icon-512.png', './icons/icon-maskable-512.png', './icons/apple-touch-icon.png'];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(VERSION).then((c) => c.addAll(FILES)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', (e) => {
  e.waitUntil(caches.keys()
    .then((keys) => Promise.all(keys.filter((k) => k !== VERSION).map((k) => caches.delete(k))))
    .then(() => self.clients.claim()));
});
self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET' || new URL(req.url).origin !== self.location.origin) return;
  if (req.mode === 'navigate') {
    e.respondWith(fetch(req)
      .then((res) => { const copy = res.clone(); caches.open(VERSION).then((c) => c.put('./index.html', copy)); return res; })
      .catch(() => caches.match('./index.html')));
    return;
  }
  e.respondWith(caches.match(req).then((hit) => hit || fetch(req)));
});
