// Learn view — the checksum playground calls the engine for its arithmetic;
// the anatomy and prose are content (i18n'd), the S-record steps load once.

(function () {
  'use strict';

  const api = window.BitsmithBridge.apiPost;
  const byId = function (id) { return document.getElementById(id); };
  let debounce = null;

  function esc(value) {
    return String(value).replace(/[&<>"']/g, function (character) {
      return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[character];
    });
  }

  function hx(n) { return n.toString(16).toUpperCase().padStart(2, '0'); }

  function renderSteps(host, steps) {
    host.replaceChildren.apply(host, steps.map(function (step) {
      const box = document.createElement('div');
      box.className = 'checksum-step';
      const label = document.createElement('span');
      label.className = 'step-num';
      label.textContent = step.label;
      const strong = document.createElement('strong');
      strong.textContent = step.value;
      const note = document.createElement('p');
      note.textContent = step.note;
      box.append(label, strong, note);
      return box;
    }));
  }

  function feedback(text, pass) {
    const node = byId('checksumFeedback');
    node.textContent = text;
    node.classList.toggle('is-pass', pass === true);
    node.classList.toggle('is-fail', pass === false);
  }

  async function updateChecksum() {
    const raw = byId('checksumInput').value.trim();
    const steps = byId('intelSteps');
    if (!/^:(?:[0-9a-fA-F]{2}){5,}$/.test(raw)) {
      steps.replaceChildren();
      feedback(window.BitsmithI18n.t('learn.input-error'), null);
      return;
    }
    const result = await api('api/learn/checksum', {
      line: raw,
      lang: window.BitsmithI18n.lang()
    });
    if (!result.valid) {
      steps.replaceChildren();
      feedback(result.reason || window.BitsmithI18n.t('learn.input-error'), null);
      return;
    }
    renderSteps(steps, result.steps);
    feedback(result.verdict, result.pass);
  }

  async function loadSrecSteps() {
    const result = await api('api/learn/srec-steps', { lang: window.BitsmithI18n.lang() });
    if (result && result.ok) {
      renderSteps(byId('srecSteps'), result.steps);
    }
  }

  byId('checksumInput').addEventListener('input', function () {
    window.clearTimeout(debounce);
    debounce = window.setTimeout(updateChecksum, 150);
  });

  document.addEventListener('keydown', function (event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return;
    if (event.target.matches('input, textarea, select')) return;
    const routes = { '1': 'records.html', '2': 'image.html', '3': 'operations.html', '4': 'learn.html' };
    if (routes[event.key]) window.location.href = routes[event.key];
  });

  // Byte anatomy strips: field roles as hoverable tokens (static teaching
  // content; labels come from the i18n tables).
  function byteToken(text, kind, label) {
    const el = document.createElement('span');
    el.className = 'field-token is-' + kind;
    el.textContent = text;
    el.tabIndex = 0;
    el.title = label;
    el.setAttribute('aria-label', label + ' · ' + text);
    return el;
  }

  function buildAnatomy() {
    const intelFields = [
      [':', 'colon', window.BitsmithI18n.t('anatomy.intel.colon')],
      ['04', 'count', window.BitsmithI18n.t('anatomy.intel.count')],
      ['80', 'address', window.BitsmithI18n.t('anatomy.intel.addr-high')],
      ['20', 'address', window.BitsmithI18n.t('anatomy.intel.addr-low')],
      ['00', 'type', window.BitsmithI18n.t('anatomy.intel.type')],
      ['48', 'data', window.BitsmithI18n.t('anatomy.intel.data-1')],
      ['B1', 'data', window.BitsmithI18n.t('anatomy.intel.data-2')],
      ['08', 'data', window.BitsmithI18n.t('anatomy.intel.data-3')],
      ['47', 'data', window.BitsmithI18n.t('anatomy.intel.data-4')],
      ['00', 'checksum', window.BitsmithI18n.t('anatomy.intel.checksum')]
    ];
    const srecFields = [
      ['S7', 'type', window.BitsmithI18n.t('anatomy.srec.type')],
      ['05', 'count', window.BitsmithI18n.t('anatomy.srec.count')],
      ['00', 'address', window.BitsmithI18n.t('anatomy.srec.addr-1')],
      ['00', 'address', window.BitsmithI18n.t('anatomy.srec.addr-2')],
      ['00', 'address', window.BitsmithI18n.t('anatomy.srec.addr-3')],
      ['00', 'address', window.BitsmithI18n.t('anatomy.srec.addr-4')],
      ['FA', 'checksum', window.BitsmithI18n.t('anatomy.srec.checksum')]
    ];
    intelFields.forEach(function (f) { byId('intelAnatomy').append(byteToken(f[0], f[1], f[2])); });
    srecFields.forEach(function (f) { byId('srecAnatomy').append(byteToken(f[0], f[1], f[2])); });
  }

  window.BitsmithI18n.ready(function () {
    buildAnatomy();
    updateChecksum();
    loadSrecSteps();
  });
})();
