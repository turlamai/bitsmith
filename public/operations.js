// Operations view — parameter forms render from api/ops/specs; previews and
// applies ride api/ops/preview and api/ops/apply. Every edit previews;
// Apply opens a confirmation; conflicts block the gate (engine-enforced).

(function () {
  'use strict';

  const api = window.BitsmithBridge.apiPost;
  const $ = function (id) { return document.getElementById(id); };

  const state = {
    specs: [],
    // A #<op-id> hash opens a card directly (also lets the acceptance
    // script reach a specific operation).
    selected: 'fill',
    values: {},
    summary: null,
    candidate: null,
    pending: null,
    previewTimer: null
  };

  function esc(value) {
    return String(value).replace(/[&<>"']/g, function (character) {
      return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[character];
    });
  }

  function hex(value, width) {
    return value.toString(16).toUpperCase().padStart(width || 2, '0');
  }

  function addr(n) { return '0x' + hex(n); }

  function t(key) { return window.BitsmithI18n ? window.BitsmithI18n.t(key) : key; }
  function engineString(key) {
    const strings = window.BitsmithEngineStrings;
    return strings && strings[key] ? strings[key] : key;
  }

  function toast(message, tone) {
    const stack = $('toastStack');
    const node = document.createElement('div');
    node.className = 'toast' + (tone === 'fail' ? ' is-fail' : tone === 'warn' ? ' is-warn' : '');
    node.innerHTML =
      '<svg class="od-icon" viewBox="0 0 24 24" aria-hidden="true">' +
        (tone === 'fail' || tone === 'warn'
          ? '<path d="M12 3.5 21 20H3z"></path><path d="M12 9v5M12 17.2v.1"></path>'
          : '<path d="m5 12.5 4.2 4.2L19 7"></path>') +
      '</svg><span>' + esc(message) + '</span>';
    stack.appendChild(node);
    window.setTimeout(function () {
      node.style.opacity = '0';
      node.style.transform = 'translateY(4px)';
      window.setTimeout(function () { node.remove(); }, 180);
    }, 3400);
  }

  // ---- spec + form rendering ---------------------------------------------------

  function currentSpec() {
    return state.specs.find(function (spec) { return spec.id === state.selected; });
  }

  function fieldHtml(field) {
    const value = state.values[state.selected][field.key];
    if (field.kind === 'select') {
      return '<div class="field"><label for="param-' + esc(field.key) + '">' + esc(field.label) + '</label>' +
        '<select class="select" id="param-' + esc(field.key) + '" data-param="' + esc(field.key) + '">' +
        field.options.map(function (option) {
          return '<option' + (option === value ? ' selected' : '') + '>' + esc(option) + '</option>';
        }).join('') + '</select></div>';
    }
    if (field.kind === 'note') {
      return '<p class="help">' + esc(field.label) + '</p>';
    }
    if (field.kind === 'bytes') {
      // Free-form hex payload: the engine validates; the placeholder is an
      // example, never a value.
      return '<div class="field"><label for="param-' + esc(field.key) + '">' + esc(field.label) + '</label>' +
        '<input class="input" id="param-' + esc(field.key) + '" data-param="' + esc(field.key) + '" value="' + esc(value) + '"' +
        (field.placeholder ? ' placeholder="' + esc(field.placeholder) + '"' : '') +
        ' spellcheck="false" autocomplete="off"></div>';
    }
    return '<div class="field"><label for="param-' + esc(field.key) + '">' + esc(field.label) + '</label>' +
      '<input class="input" id="param-' + esc(field.key) + '" data-param="' + esc(field.key) + '" value="' + esc(value) + '" spellcheck="false" autocomplete="off"></div>';
  }

  function render() {
    const spec = currentSpec();
    $('opList').innerHTML = state.specs.map(function (entry) {
      return '<button type="button" class="op-item" data-op="' + esc(entry.id) + '" aria-current="' + (entry.id === state.selected) + '">' +
        '<span class="op-main"><span class="op-name" style="display:block">' + esc(entry.name) + '</span>' +
        '<span class="op-desc" style="display:block">' + esc(entry.desc) + '</span></span>' +
        '<span class="op-badge">' + esc(entry.badge) + '</span></button>';
    }).join('');

    $('compactOperation').innerHTML = state.specs.map(function (entry) {
      return '<option value="' + esc(entry.id) + '"' + (entry.id === state.selected ? ' selected' : '') + '>' +
        esc(entry.name) + '</option>';
    }).join('');

    $('operationDetail').innerHTML =
      '<div class="op-detail-head"><div class="op-detail-title"><h2>' + esc(spec.name) + '</h2>' +
      '<p>' + esc(spec.desc) + '. ' + esc(t('ops.detail-hint')) + '</p></div></div>' +
      '<div class="op-body">' +
      '<section class="form-section"><div class="form-section-head"><h3>' + esc(t('ops.parameters')) + '</h3>' +
      '<span class="mini-note">' + esc(t('ops.absolute-addresses')) + '</span></div>' +
      '<div class="form-section-body"><div class="form-grid">' +
      spec.fields.map(fieldHtml).join('') +
      '</div><p class="help">' + esc(spec.help || engineString('field-help')) + '</p></div></section>' +
      '<section class="preview-section"><div class="preview-section-head"><h3>' + esc(t('ops.preview-title')) + '</h3>' +
      '<span class="mini-note">' + esc(t('ops.preview-note')) + '</span></div>' +
      '<div class="preview-body" id="previewContent" aria-live="polite"></div></section></div>' +
      '<div class="op-apply-bar"><button class="btn" id="resetBtn" type="button">' + esc(t('ops.reset-sample')) + '</button>' +
      '<span class="toolbar-spacer"></span>' +
      '<button class="btn btn-primary" id="applyBtn" type="button">' + esc(t('ops.review-apply')) + '</button></div>';

    bindDetailEvents();
    preview();
  }

  function bindDetailEvents() {
    $('operationDetail').addEventListener('input', function (event) {
      if (event.target.dataset.param) {
        state.values[state.selected][event.target.dataset.param] = event.target.value;
        schedulePreview();
      }
    });
    $('operationDetail').addEventListener('change', function (event) {
      if (event.target.dataset.param) {
        state.values[state.selected][event.target.dataset.param] = event.target.value;
        if (state.selected === 'convert' && event.target.dataset.param === 'target') {
          render();
          const target = $('param-target');
          if (target) target.focus();
        } else {
          schedulePreview();
        }
      }
    });
    $('operationDetail').addEventListener('click', function (event) {
      if (event.target.id === 'resetBtn') {
        resetSample();
      }
      if (event.target.id === 'applyBtn' && state.candidate && state.candidate.ok) {
        state.pending = state.candidate;
        $('confirmCopy').textContent = confirmationCopy(state.pending);
        $('confirmApply').showModal();
        $('cancelApply').focus();
      }
    });
  }

  function confirmationCopy(candidate) {
    return candidate.note + ' +' + candidate.added + ' / −' + candidate.removed + ' / ~' + candidate.changed +
      ' · ' + t('ops.confirm-tail');
  }

  function schedulePreview() {
    window.clearTimeout(state.previewTimer);
    state.previewTimer = window.setTimeout(preview, 120);
  }

  // ---- preview ------------------------------------------------------------------

  function miniMapHtml(segments, gaps, lo, hi) {
    const span = Math.max(hi - lo + 1, 1);
    const parts = [];
    const merged = (segments || []).map(function (s) { return { kind: 'data', start: s.start, end: s.end, size: s.size }; })
      .concat((gaps || []).map(function (g) { return { kind: 'gap', start: g.start, end: g.end, size: g.size }; }))
      .sort(function (a, b) { return a.start - b.start; });
    merged.forEach(function (segment) {
      if (segment.start > lo) {
        parts.push([segment.start - lo, 'gap', addr(lo) + '–' + addr(segment.start - 1) + ' ' + t('ops.unmapped')]);
      }
      parts.push([segment.end - segment.start + 1, segment.kind === 'gap' ? 'gap' : 'data',
        addr(segment.start) + '–' + addr(segment.end) + ' ' +
        (segment.kind === 'gap' ? t('ops.unmapped') : t('ops.populated'))]);
      lo = segment.end + 1;
    });
    return parts.map(function (part) {
      return '<span class="map-part ' + part[1] + '" style="flex:' + part[0] + '" title="' + esc(part[2]) + '" aria-label="' + esc(part[2]) + '"></span>';
    }).join('');
  }

  function changesHtml(preview) {
    return (preview.changes || []).map(function (change) {
      const mark = change[0];
      const address = change[1];
      const from = change[2];
      const to = change[3];
      const text = addr(address) + '  ' +
        (from === 'null' || from === null ? '··' : hex(from, 2)) + ' → ' +
        (to === 'null' || to === null ? '··' : hex(to, 2));
      const cls = mark === '+ ' ? 'is-add' : mark === '- ' ? 'is-remove' : 'is-warn';
      return '<div class="diff-row ' + cls + '"><span class="diff-mark">' + esc(mark.trim()) + '</span>' +
        '<span class="diff-copy">' + esc(text) + '</span></div>';
    }).join('');
  }

  function crcHtml(crc) {
    return '<div class="crc-readout"><span class="crc-label">' + esc(t('crc.computed')) + ' ' + esc(crc.label) + '</span>' +
      '<output class="crc-value">0x' + hex(crc.value, crc.bits / 4) + '</output>' +
      '<span class="badge">' + esc(t('crc.live')) + '</span></div>' +
      '<div class="crc-params"><span>poly <b>' + addr(crc.poly) + '</b></span>' +
      '<span>init <b>' + addr(crc.init) + '</b></span>' +
      '<span>xorout <b>' + addr(crc.xor) + '</b></span>' +
      '<span>refin / refout <b>' + (crc.reflect ? 'yes / yes' : 'no / no') + '</b></span></div>' +
      '<p class="callout">' + esc(crc.note) + '</p>' +
      '<p class="mini-note">' + esc(crc['read-only']) + '</p>';
  }

  function renderPreview(preview, error) {
    const summary = state.summary;
    const blocked = !!error;
    const content = $('previewContent');
    const lo = summary && summary.stats.min !== null && summary.stats.min !== 'null' ? summary.stats.min : 0;
    const hi = summary && summary.stats.max !== null && summary.stats.max !== 'null' ? summary.stats.max : 0;

    if (blocked) {
      content.innerHTML = '<div class="conflict-callout" role="alert"><div><strong>' +
        esc(t('ops.preview-blocked')) + '</strong><p>' + esc(error) + '</p></div></div>';
    } else if (state.selected === 'crc') {
      content.innerHTML = '<p class="callout">' + esc(preview.note) + '</p>' + crcHtml(preview.crc);
    } else {
      const diffRows = changesHtml(preview);
      const rd = preview['record-diff'];
      const affected = rd && !rd.skipped
        ? '<details class="callout"><summary>' + esc(t('ops.affected-records')) + ' · −' + rd.removed + ' / +' + rd.added + '</summary>' +
          '<pre class="op-output">' + esc(rd.lines.length ? rd.lines.join('\n') : t('ops.no-record-change')) + '</pre>' +
          '<p class="mini-note">' + esc(t('ops.canonical-note')) + '</p></details>'
        : '';
      content.innerHTML =
        '<div class="mini-map">' +
          [['Before', summary.segments, summary.gaps], ['After', preview['after-segments'], preview['after-gaps']]].map(function (pair) {
            return '<div class="mini-map-row"><span class="mini-map-label">' + esc(pair[0]) + '</span>' +
              '<span class="mini-map-track" role="img" aria-label="' + esc(pair[0]) + '">' +
              miniMapHtml(pair[1], pair[2], lo, hi) + '</span></div>';
          }).join('') +
        '</div>' +
        '<p class="mini-note mono">' + esc(addr(lo)) + '–' + esc(addr(hi)) + ' · ' + esc(t('ops.shared-scale')) + '</p>' +
        '<p class="callout">' + esc(preview.note) + '</p>' +
        '<div class="diff-list"><div class="diff-row"><span class="diff-mark">Δ</span>' +
        '<span class="diff-copy">' + esc(t('ops.affected-bytes')) + ' +' + preview.added + ' / −' + preview.removed + ' / ~' + preview.changed + '</span></div>' +
        diffRows + '</div>' +
        (preview.added + preview.removed + preview.changed > 12
          ? '<p class="mini-note">' + esc(t('ops.first-12')) + '</p>' : '') +
        '<p class="mini-note">' + esc(t('ops.canonical-counts')) + ' ' + preview['before-count'] + ' → ' + preview['after-count'] + '</p>' +
        affected +
        (preview.output ? '<pre class="op-output" aria-label="Conversion output preview">' + esc(preview.output) + '</pre>' : '');
    }

    const gateBlocked = blocked || state.selected === 'crc';
    $('applyBtn').disabled = blocked || state.selected === 'crc';
    $('gateBadge').textContent = blocked
      ? t('ops.gate-blocked')
      : state.selected === 'crc' ? t('ops.gate-readonly') : t('ops.gate-ready');
    $('gateBadge').className = 'badge ' + (blocked ? 'badge-fail' : 'badge-ok');
    $('gatePill').textContent = blocked ? t('ops.blocked') : t('ops.ready');
    $('gatePill').className = 'badge ' + (blocked ? 'badge-fail' : 'badge-ok');
    $('gateChecks').innerHTML = '<p class="callout ' + (blocked ? 'is-fail' : '') + '">' +
      (blocked ? esc(error) : esc(t('ops.gate-retained'))) + '</p>';
    renderScope();
    const dot = $('statusDot');
    dot.className = 'status-dot ' + (blocked ? 'fail' : 'ok');
    $('statusGate').textContent = blocked
      ? t('ops.apply-blocked')
      : state.selected === 'crc' ? t('ops.digest-computed') : t('ops.preview-ready');
    $('statusApplyNote').textContent = ' · ' + t('status.revision') + ' ' + (summary ? summary.revision : 0);
    $('statusConflicts').textContent = blocked ? '1' : '0';
    $('statusHint').textContent = blocked ? t('ops.resolve-conflict') : t('ops.working-copy-only');
  }

  function renderScope() {
    const summary = state.summary;
    if (!summary) return;
    $('scopeRecords').textContent = summary.stats['data-bytes'] + ' B';
    $('scopeList').innerHTML =
      '<dt>' + esc(t('scope.source')) + '</dt><dd>' + esc(summary.name) + '</dd>' +
      '<dt>' + esc(t('scope.format')) + '</dt><dd>' + esc(summary['format-label']) + '</dd>' +
      '<dt>' + esc(t('scope.revision')) + '</dt><dd>' + summary.revision + '</dd>' +
      '<dt>' + esc(t('scope.populated')) + '</dt><dd>' + summary.stats['data-bytes'] + '</dd>' +
      '<dt>' + esc(t('scope.span')) + '</dt><dd>' + addr(summary.stats.min) + '–' + addr(summary.stats.max) + '</dd>';
    $('sessionNote').textContent = t('ops.session-note') + ' ' + summary.revision + '. ' + t('ops.session-note-2');
    $('sideFoot').textContent = summary.stats['data-bytes'] + ' · ' + summary['format-label'];
  }

  async function preview() {
    state.candidate = null;
    let error = '';
    let result = null;
    try {
      result = await api('api/ops/preview', {
        op: state.selected,
        params: state.values[state.selected] || {},
        lang: window.BitsmithI18n.lang()
      });
      if (!result.ok) error = result.error || t('ops.preview-blocked');
    } catch (err) {
      error = String(err.message || err);
    }
    state.candidate = result && result.ok ? result : null;
    renderPreview(state.candidate, error);
  }

  // ---- apply ----------------------------------------------------------------------

  async function applyPending() {
    const pending = state.pending;
    state.pending = null;
    if (!pending) return;
    const result = await api('api/ops/apply', {
      op: state.selected,
      params: state.values[state.selected] || {},
      expectRevision: pending.revision,
      lang: window.BitsmithI18n.lang()
    });
    if (result && result.ok) {
      $('confirmApply').close();
      await refreshSummary();
      state.candidate = null;
      preview();
      toast(result.phrase + ' ' + result.revision, 'ok');
    } else {
      $('confirmApply').close();
      toast(result && result.error ? result.error : t('ops.apply-failed'), 'fail');
      preview();
    }
  }

  async function resetSample() {
    const result = await api('api/workspace/reset', { lang: window.BitsmithI18n.lang() });
    if (result && result.phrase) toast(result.phrase, 'ok');
    await refreshSummary();
    state.candidate = null;
    render();
    const resetBtn = $('resetBtn');
    if (resetBtn) resetBtn.focus();
  }

  async function refreshSummary() {
    const summary = await api('api/workspace/state', { lang: window.BitsmithI18n.lang() });
    if (summary && summary.strings) window.BitsmithEngineStrings = summary.strings;
    state.summary = summary;
    const loaded = summary.loaded;
    $('toolbarSub').textContent = loaded
      ? t('ops.working-copy') + ' · ' + addr(summary.stats.min) + '–' + addr(summary.stats.max)
      : t('status.no-file-loaded');
    renderScope();
  }

  // ---- boot -------------------------------------------------------------------------

  async function boot() {
    const specsResponse = await api('api/ops/specs', { lang: window.BitsmithI18n.lang() });
    state.specs = specsResponse.ops || [];
    state.values = {};
    state.specs.forEach(function (spec) {
      const entry = {};
      spec.fields.forEach(function (field) {
        if (field.kind !== 'note') entry[field.key] = field['default'];
      });
      state.values[spec.id] = entry;
    });
    const wanted = window.location.hash.replace('#', '');
    if (state.specs.some(function (spec) { return spec.id === wanted; })) {
      state.selected = wanted;
    }
    // The top-bar count follows the engine's card list, never a typed number.
    $('stagedCount').textContent = state.specs.length + ' ' + t('ops.operations-count');

    function select(id) {
      state.selected = id;
      if (window.history && window.history.replaceState) {
        window.history.replaceState(null, '', '#' + id);
      }
      render();
    }

    $('opList').addEventListener('click', function (event) {
      const button = event.target.closest('[data-op]');
      if (button) {
        select(button.dataset.op);
      }
    });
    $('compactOperation').addEventListener('change', function (event) {
      select(event.target.value);
    });
    $('cancelApply').addEventListener('click', function () { $('confirmApply').close(); });
    $('commitApply').addEventListener('click', applyPending);
    $('confirmApply').addEventListener('close', function () {
      const button = $('applyBtn');
      if (button) button.focus();
    });

    document.addEventListener('keydown', function (event) {
      if (event.metaKey || event.ctrlKey || event.altKey || event.target.matches('input,select,textarea') || $('confirmApply').open) return;
      const route = { '1': 'records.html', '2': 'image.html', '3': 'operations.html', '4': 'learn.html' }[event.key];
      if (route) window.location.href = route;
    });

    await refreshSummary();
    render();
  }

  window.BitsmithI18n.ready(function () {
    boot();
  });
})();
