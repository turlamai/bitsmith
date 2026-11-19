// Records view — data from the engine, rendered here.
//
// Every verdict comes from the backend (live arithmetic per load); nothing
// in this file recomputes checksums. Sample mode keeps the designed FBL/APP
// sidebar labels; opened files show the engine's computed segments.

(function () {
  'use strict';

  const api = window.BitsmithBridge.apiPost;
  const $ = function (id) { return document.getElementById(id); };

  const state = {
    summary: null,
    records: [],
    selected: -1,
    openExplain: false,
    popAnchor: null
  };

  const elements = {
    recordBody: $('recordBody'),
    inspectorBody: $('inspectorBody'),
    inspectorCount: $('inspectorCount'),
    fileName: $('fileName'),
    fileSubline: $('fileSubline'),
    fileRange: $('fileRange'),
    fileBytes: $('fileBytes'),
    fileRecords: $('fileRecords'),
    verifyStrip: $('verifyStrip'),
    verifyCount: $('verifyCount'),
    segmentList: $('segmentList'),
    summaryValid: $('summaryValid'),
    toolbarSub: $('toolbarSub'),
    recordLoaded: $('recordLoaded'),
    emptyWorkspace: $('emptyWorkspace'),
    emptySide: $('emptySide'),
    fileSummary: $('fileSummary'),
    emptyTitle: $('emptyTitle'),
    emptyCopy: $('emptyCopy'),
    recordActions: $('recordActions'),
    topFileName: $('topFileName'),
    topFormat: $('topFormat'),
    statusFormat: $('statusFormat'),
    statusRecords: $('statusRecords'),
    statusChecksum: $('statusChecksum'),
    statusDot: $('statusDot'),
    typePop: $('type04Pop'),
    toastStack: $('toastStack'),
    topFileTab: $('topFileTab')
  };

  function esc(value) {
    return String(value).replace(/[&<>"']/g, function (character) {
      return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[character];
    });
  }

  function hex(value, width) {
    return value.toString(16).toUpperCase().padStart(width || 2, '0');
  }

  function formatAddress(value) {
    if (value === null || value === undefined) return '—';
    return '0x' + value.toString(16).toUpperCase().padStart(8, '0');
  }

  function t(key) { return window.BitsmithI18n ? window.BitsmithI18n.t(key) : key; }
  function engineString(key) {
    const strings = window.BitsmithEngineStrings;
    return strings && strings[key] ? strings[key] : key;
  }

  function toast(message, tone) {
    const node = document.createElement('div');
    node.className = 'toast' + (tone === 'fail' ? ' is-fail' : tone === 'warn' ? ' is-warn' : '');
    node.innerHTML =
      '<svg class="od-icon" viewBox="0 0 24 24" aria-hidden="true">' +
        (tone === 'fail' || tone === 'warn'
          ? '<path d="M12 3.5 21 20H3z"></path><path d="M12 9v5M12 17.2v.1"></path>'
          : '<path d="m5 12.5 4.2 4.2L19 7"></path>') +
      '</svg><span>' + esc(message) + '</span>';
    elements.toastStack.appendChild(node);
    window.setTimeout(function () {
      node.style.opacity = '0';
      node.style.transform = 'translateY(4px)';
      window.setTimeout(function () { node.remove(); }, 180);
    }, 3400);
  }

  // ---- segments -------------------------------------------------------------

  function humanSize(bytes) {
    if (bytes >= 1024 && bytes % 1024 === 0) return (bytes / 1024) + ' KiB';
    return bytes.toLocaleString() + ' B';
  }

  function renderSegments(summary) {
    let rows;
    if (summary.sample && summary.kind === 'intel') {
      // Designed sample display: FBL / GAP / APP / explicit 0xFF tail.
      rows = [
        { kind: 'fbl', name: 'FBL', address: '0x08000000 +0x20', size: '32 B' },
        { kind: 'gap', name: 'GAP', address: '0x08000020–0x08007FFF', size: '0x7FE0' },
        { kind: 'app', name: 'APP', address: '0x08008000–0x08009FFF', size: '8 KiB' },
        { kind: 'ff', name: t('segments.explicit-ff'), address: '0x08009FF0–0x08009FFF', size: '16 B' }
      ];
    } else {
      rows = [];
      let imageIndex = 0;
      let gapIndex = 0;
      const segments = summary.segments || [];
      const gaps = summary.gaps || [];
      const merged = segments.map(function (s) { return { kind: 'data', start: s.start, end: s.end, size: s.size }; })
        .concat(gaps.map(function (g) { return { kind: 'gap', start: g.start, end: g.end, size: g.size }; }))
        .sort(function (a, b) { return a.start - b.start; });
      merged.forEach(function (segment) {
        if (segment.kind === 'gap') {
          rows.push({ kind: 'gap', name: 'GAP',
                      address: formatAddress(segment.start) + '–' + formatAddress(segment.end),
                      size: '0x' + hex(segment.size) });
        } else {
          imageIndex += 1;
          rows.push({ kind: imageIndex === 1 ? 'fbl' : 'app', name: 'IMAGE ' + imageIndex,
                      address: formatAddress(segment.start) + '–' + formatAddress(segment.end),
                      size: humanSize(segment.size) });
        }
      });
    }
    elements.segmentList.innerHTML = rows.map(function (row) {
      return '<div class="segment-row is-' + row.kind + '">' +
        '<span class="segment-swatch"></span>' +
        '<div class="segment-main"><div class="segment-name">' + esc(row.name) + '</div>' +
        '<div class="segment-addr">' + esc(row.address) + '</div></div>' +
        '<div class="segment-size">' + esc(row.size) + '</div></div>';
    }).join('');

    const gapBlock = document.querySelector('.gap-block');
    const gaps = rows.filter(function (row) { return row.kind === 'gap'; });
    if (gapBlock) {
      gapBlock.innerHTML = '<div class="section-label">' + esc(t('segments.gap-list')) + '</div>' +
        (gaps.length
          ? gaps.map(function (gap) {
              return '<div class="gap-row"><span class="gap-range">' + esc(gap.address) + '</span>' +
                     '<span class="gap-len">' + esc(gap.size) + '</span></div>';
            }).join('')
          : '<div class="gap-row"><span class="gap-range">' + esc(t('segments.no-gaps')) + '</span>' +
            '<span class="gap-len">—</span></div>');
    }
  }

  // ---- summary / sidebar ----------------------------------------------------

  function renderSummary(summary) {
    const stats = summary.stats;
    const failCount = stats.records - stats.valid;
    elements.fileName.textContent = summary.name;
    elements.topFileName.textContent = summary.name;
    elements.topFormat.textContent = summary['format-label'] || summary.formatLabel;
    elements.statusFormat.textContent = summary['format-label'] || summary.formatLabel;
    const ext = summary.ext && summary.ext !== 'null' ? summary.ext : '';
    const extText = ext
      ? '<code style="font-family:var(--font-mono);color:var(--muted)">.' + esc(ext) + '</code>'
      : esc(t('source.no-extension'));
    elements.fileSubline.innerHTML =
      esc(summary['format-label'] || summary.formatLabel) + ' — ' +
      esc(t('source.sniffed')) + ' ' + extText;
    elements.fileRange.textContent = stats.min === null || stats.min === 'null'
      ? t('source.no-data-records')
      : formatAddress(stats.min) + '–' + formatAddress(stats.max);
    elements.fileBytes.textContent = stats['data-bytes'] + ' B / ' +
      (stats.min === null || stats.min === 'null'
        ? '—'
        : Math.ceil(stats.span / 1024) + ' KiB span');
    elements.fileRecords.textContent = stats.records;
    elements.verifyCount.textContent = stats.valid + ' / ' + stats.records;
    elements.verifyStrip.classList.toggle('is-fail', failCount > 0);
    const verifyCopy = elements.verifyStrip.querySelector('.verify-copy');
    verifyCopy.innerHTML = '<strong>' + esc(t('verify.ok-head')) + ' · ' + failCount + ' ' +
      esc(t('verify.failed')) + '</strong>' + esc(engineString('phrase-verify-copy'));
    elements.summaryValid.textContent = stats.valid + ' / ' + stats.records;
    elements.toolbarSub.textContent = stats.records + ' ' + t('toolbar.records-suffix');
    elements.statusRecords.textContent = stats.records;
    elements.statusChecksum.textContent = stats.valid + ' / ' + stats.records;
    elements.statusDot.className = 'status-dot ' + (failCount ? 'fail' : 'ok');
    elements.topFileTab.setAttribute('aria-label', 'Current file: ' + summary.name);
    renderSegments(summary);
  }

  // ---- table ----------------------------------------------------------------

  function typeCell(record) {
    if (record.malformed) {
      return '<span class="type-chip type-fail"><span class="type-hex">??</span> ' +
        esc(t('record.malformed')) + '</span>';
    }
    if (state.summary && state.summary.kind === 'intel' && record.type === 4) {
      return '<button class="type-chip type-04" type="button" data-explain="04" aria-expanded="false" aria-controls="type04Pop" style="font:inherit">' +
        '<span class="type-hex">04</span> ' + esc(t('record.type-04')) +
        '<svg class="od-icon type-explain-icon" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="8.5"></circle><path d="M12 11v5M12 8v.1"></path></svg>' +
        '</button>';
    }
    const failClass = record.ok ? '' : ' type-fail';
    return '<span class="type-chip' + failClass + '"><span class="type-hex">' + esc(record['type-hex']) +
      '</span> ' + esc(record['type-name']) + '</span>';
  }

  function renderTable() {
    elements.recordBody.innerHTML = state.records.map(function (record, index) {
      const selected = index === state.selected;
      const classes = 'record-row' + (record.ok ? '' : ' is-failed') + (selected ? ' is-selected' : '');
      const data = record.data || [];
      const dataPreview = data.length
        ? data.slice(0, 8).map(function (b) { return hex(b); }).join(' ') + (data.length > 8 ? ' …' : '')
        : '—';
      const absolute = record.absolute === null || record.absolute === 'null'
        ? '—'
        : formatAddress(record.absolute) + (state.summary && state.summary.kind === 'intel' && record.type === 4 ? ' <span class="faint">base</span>' : '');
      const stored = record.stored === null || record.stored === undefined || record.stored === 'null' ? '—' : hex(record.stored);
      const checksum = (record.stored === null || record.stored === undefined || record.stored === 'null')
        ? '<span class="faint">—</span>'
        : '<span class="' + (record.ok ? 'cks-ok' : 'cks-fail') + '">' + stored + '</span>';
      let html = '<tr class="' + classes + '" data-index="' + index + '" tabindex="0" aria-selected="' + (selected ? 'true' : 'false') + '">' +
        '<td class="col-index">' + String(index + 1).padStart(2, '0') + '</td>' +
        '<td class="col-raw"><span class="raw-record" title="' + esc(record.raw) + '">' + esc(record.raw) + '</span></td>' +
        '<td class="num-cell">' + (record.malformed ? '—' : hex(record.count)) + '</td>' +
        '<td class="num-cell">' + (record.malformed ? '—' : '0x' + hex(record.address, 4)) + '</td>' +
        '<td class="addr-cell">' + absolute + '</td>' +
        '<td class="type-cell">' + typeCell(record) + '</td>' +
        '<td class="data-cell" title="' + esc(record['data-hex'] || '') + '">' + dataPreview + '</td>' +
        '<td class="cks-cell">' + checksum + '</td>' +
        '<td><span class="verdict ' + (record.ok ? '' : 'is-fail') + '">' +
          (record.ok ? t('record.verdict-ok') : t('record.verdict-fail')) + '</span></td>' +
      '</tr>';

      if (!record.ok && !record.malformed) {
        const payload = (record.data || []);
        const sumTokens = [record.count, (record.address >> 8) & 255, record.address & 255, record.type]
          .concat(payload).map(function (b) { return hex(b); }).join(' + ');
        html += '<tr class="math-row"><td colspan="9"><div class="math-panel">' +
          '<span class="math-label">' + esc(t('record.math-label')) + '</span>' +
          '<span>sum</span><span class="math-token">' + esc(sumTokens) + '</span>' +
          '<span class="math-arrow">=</span><span class="math-token">0x' + record.sum.toString(16).toUpperCase() + '</span>' +
          '<span class="math-arrow">→</span><span class="math-token">' + esc(t('record.twos-complement')) + ' = 0x' + hex(record.expected) + '</span>' +
          '<span class="math-arrow">→</span><span class="math-token">' + esc(t('record.expected-found')) + ' 0x' + hex(record.expected) + ' · 0x' + hex(record.stored) + '</span>' +
          '<span class="math-result">' + esc(t('record.fail-tag')) + '</span>' +
        '</div></td></tr>';
      }
      return html;
    }).join('');

    Array.prototype.forEach.call(elements.recordBody.querySelectorAll('.record-row'), function (row) {
      row.addEventListener('click', function () { selectRecord(Number(row.dataset.index), false); });
      row.addEventListener('keydown', function (event) {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          selectRecord(Number(row.dataset.index), false);
        }
      });
    });

    Array.prototype.forEach.call(elements.recordBody.querySelectorAll('[data-explain="04"]'), function (button) {
      button.addEventListener('click', function (event) {
        event.stopPropagation();
        selectRecord(0, false);
        openExplain(button);
      });
    });
  }

  // ---- inspector ------------------------------------------------------------

  function renderInspector() {
    const record = state.records[state.selected];
    if (!record) {
      elements.inspectorBody.innerHTML =
        '<div class="empty-side"><strong>' + esc(t('inspector.no-selection')) + '</strong>' +
        esc(t('inspector.choose-record')) + '</div>';
      elements.inspectorCount.textContent = '— / —';
      return;
    }
    const stats = state.summary.stats;
    const number = String(state.selected + 1).padStart(2, '0');
    elements.inspectorCount.textContent = number + ' / ' + String(state.records.length).padStart(2, '0');
    const data = record.data || [];
    const dataFull = data.length ? data.map(function (b) { return hex(b); }).join(' ') : '—';
    const absolute = record.absolute === null || record.absolute === 'null'
      ? '—' : formatAddress(record.absolute);
    const stored = record.stored === null || record.stored === undefined || record.stored === 'null'
      ? '—' : '0x' + hex(record.stored);
    const expected = record.expected === null || record.expected === undefined || record.expected === 'null'
      ? '—' : '0x' + hex(record.expected);

    let verdictCopy = '';
    if (!record.ok && !record.malformed) {
      verdictCopy = '<div class="callout is-fail" style="margin-top:10px"><strong>' +
        esc(engineString('phrase-checksum-mismatch')) + '</strong> ' +
        esc(engineString('phrase-checksum-mismatch-detail')) + '</div>';
    } else if (state.summary.kind === 'intel' && record.type === 4) {
      verdictCopy = '<div class="callout" style="margin-top:10px"><strong>' +
        esc(engineString('phrase-base-record')) + '</strong></div>';
    } else if (record.ok) {
      verdictCopy = '<div class="callout" style="margin-top:10px"><strong>' +
        esc(engineString('phrase-checksum-ok')) + '</strong></div>';
    }

    const checks = [
      { ok: record.ok, label: record.ok ? t('inspector.check-verifies') : t('inspector.check-fails') },
      { ok: true, label: t('inspector.check-decoded') },
      { ok: true, label: t('inspector.check-absolute') }
    ];

    elements.inspectorBody.innerHTML =
      '<div class="inspector-section">' +
        '<div class="inspector-title"><span>' + esc(t('inspector.record-n')) + ' ' + number + '</span>' +
          '<span class="' + (record.ok ? 'badge-ok' : 'badge-fail') + ' badge">' +
          (record.ok ? esc(t('inspector.verified')) : esc(t('inspector.failed'))) + '</span></div>' +
        '<div class="raw-line-box">' + esc(record.raw) + '</div>' +
        '<dl class="kv-list" style="margin-top:10px">' +
          '<dt>' + esc(t('kv.type')) + '</dt><dd>' + esc(record['type-hex']) + ' · ' + esc(record['type-name']) + '</dd>' +
          '<dt>' + esc(t('kv.byte-count')) + '</dt><dd>' + (record.malformed ? '—' : '0x' + hex(record.count)) + '</dd>' +
          '<dt>' + esc(t('kv.record-address')) + '</dt><dd>' + (record.malformed ? '—' : '0x' + hex(record.address, 4)) + '</dd>' +
          '<dt>' + esc(t('kv.absolute')) + '</dt><dd>' + absolute + '</dd>' +
          '<dt>' + esc(t('kv.stored')) + '</dt><dd>' + stored + '</dd>' +
          '<dt>' + esc(t('kv.expected')) + '</dt><dd>' + expected + '</dd>' +
        '</dl>' +
        verdictCopy +
      '</div>' +
      '<div class="inspector-section">' +
        '<div class="inspector-title"><span>' + esc(t('inspector.payload')) + '</span>' +
          '<span class="mono">' + data.length + ' ' + esc(t('inspector.bytes')) + '</span></div>' +
        '<div class="raw-line-box" style="word-break:break-word">' + esc(dataFull) + '</div>' +
      '</div>' +
      '<div class="inspector-section">' +
        '<div class="inspector-title"><span>' + esc(t('inspector.file-verification')) + '</span>' +
          '<span class="mono">' + stats.valid + ' / ' + stats.records + '</span></div>' +
        '<div class="check-list">' + checks.map(function (check) {
          return '<div class="check-row' + (check.ok ? '' : ' is-fail') + '">' +
            '<svg class="od-icon check-icon" viewBox="0 0 24 24" aria-hidden="true">' +
              (check.ok ? '<path d="m5 12.5 4.2 4.2L19 7"></path>' : '<path d="M6 6l12 12M18 6 6 18"></path>') +
            '</svg><span>' + esc(check.label) + '</span></div>';
        }).join('') + '</div>' +
        '<div class="callout" style="margin-top:9px">' + esc(engineString('phrase-live-verify')) + '</div>' +
      '</div>';
  }

  function selectRecord(index, scroll) {
    if (!state.records[index]) return;
    state.selected = index;
    Array.prototype.forEach.call(elements.recordBody.querySelectorAll('.record-row'), function (row) {
      const selected = Number(row.dataset.index) === index;
      row.classList.toggle('is-selected', selected);
      row.setAttribute('aria-selected', selected ? 'true' : 'false');
    });
    renderInspector();
    if (scroll) {
      const row = elements.recordBody.querySelector('.record-row[data-index="' + index + '"]');
      if (row) row.scrollIntoView({ block: 'center', inline: 'nearest' });
    }
  }

  // ---- type 04 explain popover ---------------------------------------------

  function positionPopover(popover, anchor) {
    const rect = anchor.getBoundingClientRect();
    const width = popover.offsetWidth;
    const height = popover.offsetHeight;
    let left = rect.left - 12;
    let top = rect.bottom + 8;
    left = Math.min(Math.max(12, left), window.innerWidth - width - 12);
    if (top + height > window.innerHeight - 42) {
      top = Math.max(10, rect.top - height - 8);
    }
    popover.style.left = left + 'px';
    popover.style.top = top + 'px';
  }

  function openExplain(anchor, focusClose) {
    state.popAnchor = anchor;
    elements.typePop.hidden = false;
    state.openExplain = true;
    Array.prototype.forEach.call(elements.recordBody.querySelectorAll('[data-explain="04"]'), function (button) {
      button.setAttribute('aria-expanded', button === anchor ? 'true' : 'false');
    });
    positionPopover(elements.typePop, anchor);
    if (focusClose !== false) {
      const closeButton = document.getElementById('closeType04');
      if (closeButton) closeButton.focus({ preventScroll: true });
    }
  }

  function closeExplain(restoreFocus) {
    if (!state.openExplain) return;
    state.openExplain = false;
    elements.typePop.hidden = true;
    Array.prototype.forEach.call(elements.recordBody.querySelectorAll('[data-explain="04"]'), function (button) {
      button.setAttribute('aria-expanded', 'false');
    });
    if (restoreFocus && state.popAnchor && document.contains(state.popAnchor)) {
      state.popAnchor.focus({ preventScroll: true });
    }
  }

  // ---- load / empty states ----------------------------------------------------

  function setEmptyState(binMode, message) {
    elements.recordLoaded.hidden = true;
    elements.emptyWorkspace.hidden = false;
    elements.fileSummary.hidden = true;
    elements.emptySide.hidden = false;
    elements.recordActions.style.visibility = 'hidden';
    elements.inspectorBody.innerHTML =
      '<div class="empty-side"><strong>' + esc(t('inspector.no-selection')) + '</strong>' +
      esc(t('inspector.open-first')) + '</div>';
    elements.inspectorCount.textContent = '— / —';
    elements.fileName.textContent = t('empty.no-file');
    elements.topFileName.textContent = t('empty.no-file');
    elements.topFormat.textContent = '—';
    elements.statusFormat.textContent = t('status.no-file');
    elements.statusRecords.textContent = '0';
    elements.statusChecksum.textContent = '—';
    elements.statusDot.className = 'status-dot';
    elements.toolbarSub.textContent = t('status.no-file-loaded');
    elements.emptyTitle.textContent = binMode ? t('empty.bin-title') : t('empty.title');
    elements.emptyCopy.textContent = binMode
      ? t('empty.bin-copy')
      : (message || t('empty.copy'));
    if (state.openExplain) closeExplain();
  }

  function setLoadedState() {
    elements.recordLoaded.hidden = false;
    elements.emptyWorkspace.hidden = true;
    elements.fileSummary.hidden = false;
    elements.emptySide.hidden = true;
    elements.recordActions.style.visibility = 'visible';
  }

  function applyWorkspace(summary, recordsView) {
    if (!summary.loaded) {
      setEmptyState(false);
      return;
    }
    state.summary = summary;
    state.records = recordsView.records || [];
    state.selected = Math.max(0, state.records.findIndex(function (record) { return !record.ok; }));
    if (state.summary.kind === 'bin' || (state.summary.kind !== 'bin' && !state.records.length)) {
      setEmptyState(state.summary.kind === 'bin');
      return;
    }
    setLoadedState();
    renderSummary(summary);
    renderTable();
    renderInspector();
    if (state.openExplain) closeExplain();
    requestAnimationFrame(function () {
      const anchor = elements.recordBody.querySelector('[data-explain="04"]');
      if (anchor && summary.sample) openExplain(anchor, false);
    });
  }

  async function refresh(showToastOnLoad) {
    const summary = await api('api/workspace/state', { lang: window.BitsmithI18n.lang() });
    if (summary && summary.strings) window.BitsmithEngineStrings = summary.strings;
    if (!summary.loaded) {
      setEmptyState(false);
      return;
    }
    const recordsView = summary.kind === 'bin'
      ? { records: [] }
      : await api('api/records/view', { lang: window.BitsmithI18n.lang() });
    applyWorkspace(summary, recordsView);
    if (showToastOnLoad && recordsView && recordsView.records) {
      toast(summary['format-label'] + ' · ' + recordsView.records.length + ' ' + t('toast.records-loaded'),
            summary.stats.valid === summary.stats.records ? 'ok' : 'warn');
    }
  }

  // ---- actions ----------------------------------------------------------------

  async function runAction(path, body, okTone) {
    const result = await api(path, body || { lang: window.BitsmithI18n.lang() });
    if (result && result.phrase) {
      toast(result.phrase, okTone || 'ok');
    }
    await refresh(false);
    return result;
  }

  $('openFirmware').addEventListener('click', async function () {
    await runAction('api/workspace/open', { lang: window.BitsmithI18n.lang() }, 'ok');
  });
  $('emptyOpen').addEventListener('click', async function () {
    await runAction('api/workspace/open', { lang: window.BitsmithI18n.lang() }, 'ok');
  });
  $('restoreSample').addEventListener('click', async function () {
    await runAction('api/workspace/reset', { lang: window.BitsmithI18n.lang() }, 'ok');
  });
  $('closeFile').addEventListener('click', async function () {
    await runAction('api/workspace/close', { lang: window.BitsmithI18n.lang() }, 'ok');
  });

  $('jumpFail').addEventListener('click', function () {
    const failedIndex = state.records.findIndex(function (record) { return !record.ok; });
    if (failedIndex < 0) {
      toast(t('toast.every-verifies'), 'ok');
      return;
    }
    selectRecord(failedIndex, true);
    const row = elements.recordBody.querySelector('.record-row[data-index="' + failedIndex + '"]');
    if (row) row.focus({ preventScroll: true });
  });

  $('verifyAll').addEventListener('click', function () {
    if (!state.summary) return;
    const stats = state.summary.stats;
    toast(stats.valid + ' ' + t('toast.of') + ' ' + stats.records + ' ' + t('toast.verified-suffix'),
          stats.valid === stats.records ? 'ok' : 'warn');
    renderSummary(state.summary);
    renderInspector();
  });

  $('closeType04').addEventListener('click', function () { closeExplain(true); });
  $('type04Pop').addEventListener('click', function (event) { event.stopPropagation(); });

  // Drag-and-drop open (bytes ride the bridge; dialogs stay the primary path).
  const dropZone = $('dropZone');
  if (dropZone) {
    dropZone.addEventListener('dragover', function (event) {
      event.preventDefault();
      dropZone.classList.add('drag-active');
    });
    dropZone.addEventListener('dragleave', function () {
      dropZone.classList.remove('drag-active');
    });
    dropZone.addEventListener('drop', async function (event) {
      event.preventDefault();
      dropZone.classList.remove('drag-active');
      const file = event.dataTransfer && event.dataTransfer.files && event.dataTransfer.files[0];
      if (!file) return;
      const buffer = await file.arrayBuffer();
      const result = await api('api/workspace/load-bytes', {
        data: window.BitsmithBridge.bytesToBase64(new Uint8Array(buffer)),
        name: file.name,
        lang: window.BitsmithI18n.lang()
      });
      if (result && result.ok) {
        await refresh(false);
        toast(result.phrase || t('toast.loaded'), result.summary && result.summary.stats.valid === result.summary.stats.records ? 'ok' : 'warn');
      } else if (result) {
        toast(result.error || t('toast.unreadable'), 'fail');
      }
    });
  }

  // Popover dismissal + keyboard map (keys fire only outside edit fields).
  document.addEventListener('click', function (event) {
    if (!state.openExplain) return;
    if (elements.typePop.contains(event.target)) return;
    if (event.target.closest('[data-explain="04"]')) return;
    closeExplain(false);
  });

  document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape' && state.openExplain) {
      closeExplain(true);
      return;
    }
    if (event.metaKey || event.ctrlKey || event.altKey) {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'o') {
        event.preventDefault();
        runAction('api/workspace/open', { lang: window.BitsmithI18n.lang() }, 'ok');
      }
      return;
    }
    if (event.target.matches('input, textarea, select')) return;
    if (event.key === '1' || event.key === '2' || event.key === '3' || event.key === '4') {
      const routes = { '1': 'records.html', '2': 'image.html', '3': 'operations.html', '4': 'learn.html' };
      window.location.href = routes[event.key];
    }
  });

  document.querySelector('.table-scroll').addEventListener('scroll', function () {
    if (state.openExplain && state.popAnchor) closeExplain(false);
  });

  window.addEventListener('resize', function () {
    if (state.openExplain && state.popAnchor) positionPopover(elements.typePop, state.popAnchor);
  });

  // Boot: restore language, then the workspace.
  window.BitsmithI18n.ready(function () {
    refresh(false);
  });
})();
