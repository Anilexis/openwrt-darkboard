const CACHE_NAME = 'darkboard-v0.1.2-rc1'; // Change the version when updating dashboard.html

const ASSETS = [
  './dashboard.html',
  './manifest.webmanifest',
  './web-app-manifest-192x192.png',
  './web-app-manifest-512x512.png'
];

// Installation: Cache the app shell
self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE_NAME).then(c => c.addAll(ASSETS)));
  self.skipWaiting(); // Activate the new SW immediately, without waiting for tab closure
});

// Activation: Delete caches of old versions
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(
        keys.map(key => {
          if (key !== CACHE_NAME) return caches.delete(key);
        })
      )
    )
  );
  self.clients.claim(); // Take control of open tabs immediately
});

// Network-First strategy
self.addEventListener('fetch', e => {
  // Skip directly for POST requests (ubus, Mihomo API) - SW does not touch them
  if (e.request.method !== 'GET') return;

  e.respondWith(
    // First try the network - always fresh data
    fetch(e.request).catch(() =>
      // Router is not available - serve from cache (offline mode)
      caches.match(e.request)
    )
  )
});
