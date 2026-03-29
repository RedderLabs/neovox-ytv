const CACHE_NAME = 'neovox-v3';

// Recursos del shell de la app (lo mínimo para funcionar offline)
const SHELL_ASSETS = [
  '/',
  '/index.html',
  '/style.css',
  '/app.js',
  '/logo.png',
  '/favicon.ico',
  '/icon-192.png',
  '/icon-512.png',
  '/manifest.json'
];

// ── Install: cachear shell ────────────────────────────────────
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(SHELL_ASSETS))
      .then(() => self.skipWaiting())
  );
});

// ── Activate: limpiar caches viejas ───────────────────────────
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k))
      ))
      .then(() => self.clients.claim())
  );
});

// ── Keep-alive: responder a heartbeats del cliente ───────────
// Mantiene el SW activo mientras hay reproducción, lo que a su vez
// evita que el navegador descarte la pestaña asociada.
let lastHeartbeat = 0;

self.addEventListener('message', e => {
  if (e.data?.type === 'keepalive') {
    lastHeartbeat = e.data.ts || Date.now();
    // Responder para confirmar que el SW está vivo
    if (e.source) {
      e.source.postMessage({ type: 'keepalive-ack', ts: Date.now() });
    }
  }
});

// ── Fetch: network-first para API, cache-first para assets ───
self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);

  // No cachear peticiones a la API ni a YouTube
  if (url.pathname.startsWith('/api/') ||
      url.hostname.includes('youtube.com') ||
      url.hostname.includes('ytimg.com') ||
      url.hostname.includes('googlevideo.com')) {
    return; // dejar que el navegador maneje normalmente
  }

  // CDN externos (Tailwind, Google Fonts): network-first con fallback a cache
  if (url.origin !== location.origin) {
    e.respondWith(
      fetch(e.request)
        .then(res => {
          const clone = res.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(e.request, clone));
          return res;
        })
        .catch(() => caches.match(e.request))
    );
    return;
  }

  // Assets locales: cache-first con fallback a network
  e.respondWith(
    caches.match(e.request)
      .then(cached => {
        if (cached) return cached;
        return fetch(e.request).then(res => {
          const clone = res.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(e.request, clone));
          return res;
        });
      })
  );
});
