const CACHE_NAME = 'v0.1.0';
const ASSETS = [
  './',               
  'index.html',
  'manifest.json',
  '工具/carrot-192.png',
  '工具/carrot-512.png'
];

self.addEventListener('install', (event) => {
  self.skipWaiting(); 
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS);
    })
  );
});


self.addEventListener('activate', (event) => {
  self.clients.claim(); 
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cache) => {
          if (cache !== CACHE_NAME) {
            console.log('清理过时缓存:', cache);
            return caches.delete(cache);
          }
        })
      );
    })
  );
});

// 拦截请求：缓存优先策略
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      return response || fetch(event.request);
    })
  );
});