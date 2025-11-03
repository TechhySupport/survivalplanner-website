'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "762853ef611a7c13b523b55cd59b8cdb",
"assets/AssetManifest.bin.json": "806bf86064ce6d4b66cd3cd506c29910",
"assets/AssetManifest.json": "ec5adafec27a12f8f9b0d68d9803372e",
"assets/assets/button.png": "9ae1a22550e81411fe0fa80b8259b454",
"assets/assets/design_plans.png": "1e5dd2a1c9bfa06c8cfacab10e48b9f5",
"assets/assets/gear.png": "de67518408e97e95d48dd0ac46eac03c",
"assets/assets/hardened_alloy.png": "5b78d3c2f47cb6429abb6d097fc845e6",
"assets/assets/icon_logo.png": "82b627f849cf5fcc8f0edacfedf5ea26",
"assets/assets/logo.old.png": "dc084bb61a3562b0a37be26c41f91327",
"assets/assets/logo.png": "4d8d794d7944b5309181dc0a9540a8ad",
"assets/assets/lunar_amber.png": "2974d6b23549de7295c934303408ade5",
"assets/assets/navbackground.png": "2a7213b681db12d7c1caee35c590d1da",
"assets/assets/polishing_solution.png": "e3fa501ac564068f3ecbb84f4481c507",
"assets/assets/stones.jpg": "68ef8c6f55acfc16e2197c5ce38cb7c2",
"assets/assets/survivalplannerapp.mp4": "864622cbbd94255eb300a3d2b8ec1646",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "876e9ae6b790851c5add9848d8d1e8cf",
"assets/icon_logo.png": "82b627f849cf5fcc8f0edacfedf5ea26",
"assets/lib/assets/button.png": "9ae1a22550e81411fe0fa80b8259b454",
"assets/lib/assets/design_plans.png": "1e5dd2a1c9bfa06c8cfacab10e48b9f5",
"assets/lib/assets/firecrystals/fc1.png": "cadff3aad5dd64563fff89ceeb0d4290",
"assets/lib/assets/firecrystals/fc10.png": "d3736384803ca29d2ca2b6cbcc89d24b",
"assets/lib/assets/firecrystals/fc2.png": "743b7ea4d0c81aec0db515fb863522df",
"assets/lib/assets/firecrystals/fc3.png": "84f209fdc6734844b3cc415b1a3c52ac",
"assets/lib/assets/firecrystals/fc4.png": "aafaddc7c95237f1dca01b1706cc8dce",
"assets/lib/assets/firecrystals/fc5.png": "cc8d88ad6c9a2bfb1b94943b7b747263",
"assets/lib/assets/firecrystals/fc6.png": "f8aa82b6e322b0b31d4f795debdc540b",
"assets/lib/assets/firecrystals/fc7.png": "588adebc0b7f99943d51a3e529ec8cba",
"assets/lib/assets/firecrystals/fc8.png": "b2932d21fd7d9d43ca029e79bd9f0ffb",
"assets/lib/assets/firecrystals/fc9.png": "55244cb40d4b3936c69addd9e2336c69",
"assets/lib/assets/firecrystals/firecystal.png": "29fb13ce230c3a9f2c59ddeb65ebacb5",
"assets/lib/assets/gear.png": "de67518408e97e95d48dd0ac46eac03c",
"assets/lib/assets/hardened_alloy.png": "5b78d3c2f47cb6429abb6d097fc845e6",
"assets/lib/assets/icon_logo.png": "82b627f849cf5fcc8f0edacfedf5ea26",
"assets/lib/assets/logo.old.png": "dc084bb61a3562b0a37be26c41f91327",
"assets/lib/assets/logo.png": "4d8d794d7944b5309181dc0a9540a8ad",
"assets/lib/assets/lunar_amber.png": "2974d6b23549de7295c934303408ade5",
"assets/lib/assets/navbackground.png": "2a7213b681db12d7c1caee35c590d1da",
"assets/lib/assets/polishing_solution.png": "e3fa501ac564068f3ecbb84f4481c507",
"assets/lib/assets/stones.jpg": "68ef8c6f55acfc16e2197c5ce38cb7c2",
"assets/logo.old.png": "dc084bb61a3562b0a37be26c41f91327",
"assets/NOTICES": "e6545b7980eeb515ba532832d69e22c1",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"flutter_bootstrap.js": "d74d4711cb5e7a7c8e8b7a3c9ea914c1",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "4599813b4291a3da57573a97d4a8ac2a",
"/": "4599813b4291a3da57573a97d4a8ac2a",
"main.dart.js": "22219680517012ed9378284aa4de37f5",
"manifest.json": "34f97befd4783e50080e15757da9fd44",
"version.json": "89abf1ea6e0ff75edc3932735cc439e9"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
