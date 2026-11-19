// Bitsmith bridge: one interface, two transports — the native GLZ1
// handler (window.__glz1, injected at document start on the glaze://
// origin) or plain fetch against the loopback server. Same shape the
// family uses (termpilot bridge.ts).

(function () {
  'use strict';

  // Development aid: surface the first uncaught error in the window title
  // so headless verification can print it.
  window.addEventListener('error', function (event) {
    try { document.title = 'ERR: ' + event.message; } catch (e) { /* ignore */ }
  });
  window.addEventListener('unhandledrejection', function (event) {
    try { document.title = 'REJ: ' + event.reason; } catch (e) { /* ignore */ }
  });

  function nativeBridge() {
    return (typeof window !== 'undefined' && window.__glz1) || null;
  }

  let probe = null;

  /** True once a backend answers — native bridge present, or /api/health ok. */
  function hasBackend() {
    if (!probe) {
      const g = nativeBridge();
      probe = g
        ? Promise.resolve(true)
        : fetch('/api/health', { method: 'GET' })
            .then(function (r) { return r.ok; })
            .catch(function () { return false; });
    }
    return probe;
  }

  /** Base64 for arbitrary byte lengths: chunked String.fromCharCode. */
  function bytesToBase64(bytes) {
    let binary = '';
    const chunk = 0x8000;
    for (let i = 0; i < bytes.length; i += chunk) {
      binary += String.fromCharCode.apply(null, bytes.subarray(i, i + chunk));
    }
    return btoa(binary);
  }

  /** POST JSON to the backend; returns the parsed response body. */
  async function apiPost(path, body) {
    const g = nativeBridge();
    if (g) return g.invoke(path, body || {});
    const res = await fetch(path, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(body || {})
    });
    if (!res.ok) {
      const detail = await res.text();
      throw new Error(path + ' failed: ' + res.status + ' ' + detail.slice(0, 200));
    }
    return res.json();
  }

  window.BitsmithBridge = {
    hasBackend: hasBackend,
    apiPost: apiPost,
    bytesToBase64: bytesToBase64,
    native: nativeBridge
  };
})();
