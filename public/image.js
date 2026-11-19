// Image view — address-true hex dump fed by api/image/view rows.
//
// Selection, goto and the byte popover are view state; the byte data,
// segments, gaps and basis all come from the engine.

(function () {
  'use strict';

  const api = window.BitsmithBridge.apiPost;
  const $ = function (id) { return document.getElementById(id); };

  const state = {
    summary: null,
    rows: [],            // [{start, cells: [16]}]
    rowTruncated: false,
    byStart: new Map(),
    populated: new Set(),
    selected: null,
    anchor: null,
    rangeStart: null,
    rangeEnd: null,
    popOpen: false,
    popAnchor: null
  };

  const elements = {
    hexRows: $('hexRows'),
    inspectorBody: $('inspectorBody'),
    inspectorOffset: $('inspectorOffset'),
    binBanner: $('binBanner'),
    binToggle: $('binToggle'),
    binSwitchLabel: $('binSwitchLabel'),
    fileName: $('fileName'),
    fileFormatLine: $('fileFormatLine'),
    formatValue: $('formatValue'),
    topFileName: $('topFileName'),
    topFormat: $('topFormat'),
    topFileTab: $('topFileTab'),
    recordedValue: $('recordedValue'),
    mapNote: $('mapNote'),
    legendBasis: $('legendBasis'),
    statusBasis: $('statusBasis'),
    statusCursor: $('statusCursor'),
    statusSelection: $('statusSelection'),
    statusEncoding: $('statusEncoding'),
    bytePop: $('bytePop'),
    popValue: $('popValue'),
    popDec: $('popDec'),
    popAscii: $('popAscii'),
    popAddress: $('popAddress'),
    popSegment: $('popSegment'),
    popOffset: $('popOffset'),
    popRow: $('popRow'),
    mapTip: $('mapTip'),
    toastStack: $('toastStack'),
    hexScroll: $('hexScroll'),
    gotoForm: $('gotoForm'),
    gotoInput: $('gotoInput'),
    focusBase: $('focusBase'),
    baseReadout: $('baseReadout')
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

  function isPrintable(byte) {
    return byte >= 0x20 && byte <= 0x7E;
  }

  function charFor(byte) {
    return isPrintable(byte) ? String.fromCharCode(byte) : '.';
  }

  function segmentFor(address) {
    // From the engine's segments (exact ranges) plus gap detection; names
    // IMAGE N with the sample keeping FBL/APP presentation.
    const summary = state.summary;
    if (summary && summary.sample && summary.kind === 'intel') {
      if (address < 0x08000020) return { name: 'FBL', start: 0x08000000 };
      if (address < 0x08008000) return { name: 'GAP', start: 0x08000020 };
      if (address >= 0x08009FF0) return { name: 'APP · ' + t('segments.explicit-ff'), start: 0x08008000 };
      return { name: 'APP', start: 0x08008000 };
    }
    const segments = (summary && summary.segments) || [];
    for (const segment of segments) {
      if (address >= segment.start && address <= segment.end) {
        const index = segments.indexOf(segment) + 1;
        return { name: 'IMAGE ' + index, start: segment.start };
      }
    }
    const gaps = (summary && summary.gaps) || [];
    for (const gap of gaps) {
      if (address >= gap.start && address <= gap.end) return { name: 'GAP', start: gap.start };
    }
    return { name: '—', start: address };
  }

  // ---- rendering --------------------------------------------------------------

  function rowHasSelection(start) {
    return state.rangeStart !== null && state.rangeStart <= start + 15 && state.rangeEnd >= start;
  }

  function renderHex() {
    const fragments = [];
    let previousEnd = null;
    state.rows.forEach(function (row) {
      const rowStart = row.start;
      const cells = row.cells;
      if (previousEnd !== null && rowStart > previousEnd + 1) {
        const gapStart = previousEnd + 1;
        const gapEnd = rowStart - 1;
        const gapLength = gapEnd - gapStart + 1;
        fragments.push(
          '<div class="hex-skip">' +
            '<span class="skip-copy"><span class="skip-badge">' + esc(t('skip.gap')) + '</span>' +
            formatAddress(gapStart) + '–' + formatAddress(gapEnd) + ' · ' + gapLength.toLocaleString() + ' B' +
            '<span class="faint">' + esc(t('skip.no-records')) + '</span></span>' +
          '</div>'
        );
      }

      const selectedInRow = rowHasSelection(rowStart);
      let byteCells = '';
      let asciiCells = '';
      for (let offset = 0; offset < 16; offset += 1) {
        const address = rowStart + offset;
        const byte = cells[offset];
        if (byte === null || byte === undefined || byte === false) {
          byteCells += '<span class="hex-byte is-missing" aria-hidden="true">··</span>';
          asciiCells += '<span class="is-missing"> </span>';
          continue;
        }
        const selected = address === state.selected;
        const inSelection = state.rangeStart !== null && address >= state.rangeStart && address <= state.rangeEnd;
        const explicitFF = byte === 0xFF;
        const classes = 'hex-byte' +
          (selected ? ' is-selected' : '') +
          (inSelection && !selected ? ' is-in-selection' : '') +
          (explicitFF ? ' is-erased' : '') +
          (byte === 0 ? ' is-zero' : '');
        const asciiClass = (selected ? 'is-selected' : '') + (inSelection && !selected ? ' is-in-selection' : '') + (explicitFF ? ' is-erased' : '');
        byteCells += '<button class="' + classes + '" type="button" data-address="' + address + '" aria-label="Byte at ' + formatAddress(address) + ', value 0x' + hex(byte) + '">' + hex(byte) + '</button>';
        asciiCells += '<span class="' + asciiClass + '">' + esc(charFor(byte)) + '</span>';
      }

      fragments.push(
        '<div class="hex-row' + (selectedInRow ? ' is-selected-row' : '') + '" data-row-start="' + rowStart + '">' +
          '<span class="hex-addr">' + formatAddress(rowStart) + '</span>' +
          '<div class="hex-bytes">' + byteCells + '</div>' +
          '<span class="hex-ascii" aria-label="ASCII gutter">' + asciiCells + '</span>' +
        '</div>'
      );
      previousEnd = rowStart + 15;
    });
    elements.hexRows.innerHTML = fragments.join('');
    Array.prototype.forEach.call(elements.hexRows.querySelectorAll('.hex-byte[data-address]'), function (button) {
      button.addEventListener('click', function (event) {
        selectByte(Number(button.dataset.address), event.shiftKey);
      });
    });
  }

  function selectByte(address, extend) {
    if (!state.populated.has(address)) return;
    if (extend && state.anchor !== null) {
      state.rangeStart = Math.min(state.anchor, address);
      state.rangeEnd = Math.max(state.anchor, address);
    } else {
      state.anchor = address;
      state.rangeStart = address;
      state.rangeEnd = address;
    }
    state.selected = address;
    renderHex();
    renderInspector();
    updateStatus();
    updatePopoverContent();
    const newAnchor = elements.hexRows.querySelector('.hex-byte.is-selected');
    if (newAnchor) {
      if (state.popOpen) {
        state.popAnchor = newAnchor;
        positionPopover(elements.bytePop, newAnchor);
      } else {
        openPopover(newAnchor, false);
      }
    }
  }

  function selectionCount() {
    if (state.rangeStart === null) return 0;
    return state.rangeEnd - state.rangeStart + 1;
  }

  function renderInspector() {
    if (state.selected === null) {
      elements.inspectorBody.innerHTML =
        '<div class="empty-side"><strong>' + esc(t('inspector.no-byte')) + '</strong>' +
        esc(t('inspector.click-byte')) + '</div>';
      elements.inspectorOffset.textContent = '—';
      return;
    }
    const selectedByte = state.populated.get(state.selected);
    const segment = segmentFor(state.selected);
    const ascii = charFor(selectedByte);
    const rangeText = formatAddress(state.rangeStart) + '–' + formatAddress(state.rangeEnd);
    const rangeBytes = selectionCount();
    const binMode = state.summary && state.summary.kind === 'bin';
    elements.inspectorOffset.textContent = segment.name + ' +0x' + hex(state.selected - segment.start, 4);
    elements.inspectorBody.innerHTML =
      '<div class="inspector-section">' +
        '<div class="inspector-title"><span>' + esc(t('inspector.selected-byte')) + '</span>' +
          '<span class="badge">' + formatAddress(state.selected) + '</span></div>' +
        '<div class="byte-inspector-hero">' +
          '<span class="byte-value">' + hex(selectedByte) + '</span>' +
          '<span class="byte-base"><strong>' + esc(t('pop.byte-hero')) + '</strong>' + selectedByte + ' ' + esc(t('pop.dec-suffix')) + '</span>' +
          '<span class="byte-ascii">' + esc(ascii) + '</span>' +
        '</div>' +
        '<dl class="kv-list" style="margin-top:10px">' +
          '<dt>' + esc(t('kv.address')) + '</dt><dd>' + formatAddress(state.selected) + '</dd>' +
          '<dt>' + esc(t('kv.segment')) + '</dt><dd>' + esc(segment.name) + '</dd>' +
          '<dt>' + esc(t('kv.offset')) + '</dt><dd>+0x' + hex(state.selected - segment.start, 4) + '</dd>' +
          '<dt>' + esc(t('kv.row')) + '</dt><dd>' + formatAddress(state.selected - (state.selected % 16)) + ' +0x' + hex(state.selected % 16) + '</dd>' +
          '<dt>' + esc(t('kv.ascii')) + '</dt><dd>' + (isPrintable(selectedByte) ? esc(ascii) : esc(t('inspector.non-printable'))) + '</dd>' +
        '</dl>' +
      '</div>' +
      '<div class="inspector-section">' +
        '<div class="inspector-title"><span>' + esc(t('inspector.selection')) + '</span>' +
          '<span class="mono">' + rangeBytes + ' B</span></div>' +
        '<dl class="kv-list">' +
          '<dt>' + esc(t('kv.start')) + '</dt><dd>' + formatAddress(state.rangeStart) + '</dd>' +
          '<dt>' + esc(t('kv.end')) + '</dt><dd>' + formatAddress(state.rangeEnd) + '</dd>' +
          '<dt>' + esc(t('kv.basis')) + '</dt><dd>' + esc(binMode ? t('basis.bin') : t('basis.hex')) + '</dd>' +
        '</dl>' +
        '<p class="callout" style="margin-top:9px">' +
          (rangeBytes > 1 ? esc(t('inspector.range-active')) : esc(t('inspector.range-hint'))) + '</p>' +
      '</div>' +
      '<div class="inspector-section">' +
        '<div class="inspector-title"><span>' + esc(t('inspector.basis-title')) + '</span>' +
          '<span class="mono">' + esc(binMode ? t('basis.assumed') : t('basis.recorded')) + '</span></div>' +
        '<div class="' + (binMode ? 'callout is-warn' : 'callout') + '">' +
          esc(binMode ? engineString('phrase-hex-basis-bin') : engineString('phrase-hex-basis-hex')) +
        '</div>' +
      '</div>' +
      '<div class="inspector-section">' +
        '<div class="inspector-title"><span>' + esc(t('inspector.map-title')) + '</span></div>' +
        '<div class="check-list">' +
          '<div class="check-row"><svg class="od-icon check-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="m5 12.5 4.2 4.2L19 7"></path></svg><span>' + esc(t('map.check-gaps')) + '</span></div>' +
          '<div class="check-row"><svg class="od-icon check-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="m5 12.5 4.2 4.2L19 7"></path></svg><span>' + esc(t('map.check-ff')) + '</span></div>' +
          '<div class="check-row"><svg class="od-icon check-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="m5 12.5 4.2 4.2L19 7"></path></svg><span>' + esc(t('map.check-absolute')) + '</span></div>' +
        '</div>' +
      '</div>';
  }

  function updateStatus() {
    if (state.selected === null) return;
    elements.statusCursor.textContent = formatAddress(state.selected);
    const count = selectionCount();
    elements.statusSelection.textContent = formatAddress(state.rangeStart) + '–' + formatAddress(state.rangeEnd) + ' (' + count + ' B)';
    const binMode = state.summary && state.summary.kind === 'bin';
    elements.statusBasis.textContent = binMode
      ? 'BIN · ' + t('basis.assumed')
      : ((state.summary ? state.summary['format-label'] : '') + ' · ' + t('basis.recorded'));
    elements.statusEncoding.textContent = t('status.encoding');
    elements.legendBasis.textContent = elements.statusBasis.textContent;
  }

  function updatePopoverContent() {
    if (state.selected === null) return;
    const selectedByte = state.populated.get(state.selected);
    const segment = segmentFor(state.selected);
    $('bytePopTitle').textContent = t('pop.byte-title') + ' ' + formatAddress(state.selected);
    elements.popValue.textContent = hex(selectedByte);
    elements.popDec.textContent = selectedByte + ' ' + t('pop.dec-suffix');
    elements.popAscii.textContent = isPrintable(selectedByte) ? charFor(selectedByte) : '·';
    elements.popAddress.textContent = formatAddress(state.selected);
    elements.popSegment.textContent = segment.name;
    elements.popOffset.textContent = '+0x' + hex(state.selected - segment.start, 4);
    elements.popRow.textContent = formatAddress(state.selected - (state.selected % 16)) + ' +0x' + hex(state.selected % 16);
  }

  function positionPopover(popover, anchor) {
    const rect = anchor.getBoundingClientRect();
    const width = popover.offsetWidth;
    const height = popover.offsetHeight;
    let left = rect.left + rect.width / 2 - width / 2;
    let top = rect.bottom + 9;
    left = Math.min(Math.max(10, left), window.innerWidth - width - 10);
    if (top + height > window.innerHeight - 38) top = Math.max(10, rect.top - height - 9);
    popover.style.left = left + 'px';
    popover.style.top = top + 'px';
  }

  function openPopover(anchor, focusClose) {
    state.popAnchor = anchor;
    state.popOpen = true;
    elements.bytePop.hidden = false;
    updatePopoverContent();
    positionPopover(elements.bytePop, anchor);
    if (focusClose !== false) {
      const closeButton = document.getElementById('closeBytePop');
      if (closeButton) closeButton.focus({ preventScroll: true });
    }
  }

  function closePopover(restoreFocus) {
    if (!state.popOpen) return;
    state.popOpen = false;
    elements.bytePop.hidden = true;
    if (restoreFocus && state.popAnchor && document.contains(state.popAnchor)) {
      state.popAnchor.focus({ preventScroll: true });
    }
  }

  // ---- segment map ------------------------------------------------------------

  function renderSegmentMap(summary) {
    const track = document.querySelector('.segment-track');
    const scale = document.querySelector('.map-scale-labels');
    const axis = document.querySelector('.axis');
    if (!track) return;
    const segments = summary.segments || [];
    const gaps = summary.gaps || [];
    const stats = summary.stats;
    if (stats.min === null || stats.min === 'null' || !segments.length) {
      track.innerHTML = '<div class="segment-block gap" style="left:0;width:100%"><span class="block-label">' +
        esc(t('map.empty')) + '</span></div>';
      if (scale) scale.innerHTML = '';
      if (axis) axis.innerHTML = '';
      return;
    }
    const lo = stats.min;
    const span = Math.max(stats.span, 1);
    function place(start, end, extraClass, label, tip) {
      const left = ((start - lo) / span) * 100;
      const width = Math.max(((end - start + 1) / span) * 100, 0.08);
      const min = width < 1 ? 'min-width:4px' : '';
      return '<button class="segment-block ' + extraClass + '" type="button" ' +
        'style="left:' + left + '%;width:' + width + '%;' + min + '" ' +
        'data-tip="' + esc(tip) + '">' +
        '<span class="block-label">' + esc(label) + '</span></button>';
    }
    let html = '';
    let imageIndex = 0;
    const merged = segments.map(function (s) { return { kind: 'data', start: s.start, end: s.end, size: s.size }; })
      .concat(gaps.map(function (g) { return { kind: 'gap', start: g.start, end: g.end, size: g.size }; }))
      .sort(function (a, b) { return a.start - b.start; });
    merged.forEach(function (segment) {
      if (segment.kind === 'gap') {
        html += place(segment.start, segment.end, 'gap',
          'GAP · ' + t('skip.gap') + ' · 0x' + hex(segment.size),
          'GAP | ' + formatAddress(segment.start) + '–' + formatAddress(segment.end) + ' | ' +
          segment.size.toLocaleString() + ' B | ' + t('map.tip-gap'));
      } else {
        imageIndex += 1;
        html += place(segment.start, segment.end, imageIndex === 1 ? 'fbl' : 'app',
          'IMAGE ' + imageIndex + ' · ' + segment.size.toLocaleString() + ' B',
          'IMAGE ' + imageIndex + ' | ' + formatAddress(segment.start) + '–' + formatAddress(segment.end) +
          ' | ' + segment.size.toLocaleString() + ' B | ' + t('map.tip-data'));
      }
    });
    track.innerHTML = html;
    Array.prototype.forEach.call(track.querySelectorAll('.segment-block'), function (block) {
      block.addEventListener('mouseenter', function (event) { showMapTip(block.dataset.tip, event); });
      block.addEventListener('mousemove', function (event) { showMapTip(block.dataset.tip, event); });
      block.addEventListener('mouseleave', hideMapTip);
      block.addEventListener('focus', function () { showMapTip(block.dataset.tip, null); });
      block.addEventListener('blur', hideMapTip);
    });
    // Axis ticks: first and last address.
    if (axis) {
      axis.innerHTML = '<span class="axis-tick" style="left:0">' + formatAddress(lo) + '</span>' +
        '<span class="axis-tick" style="left:100%">' + formatAddress(stats.max) + '</span>';
    }
  }

  function showMapTip(text, event) {
    const tip = elements.mapTip;
    const parts = (text || '').split('|');
    tip.innerHTML = parts.map(function (part, index) {
      return index === 0 ? '<strong>' + esc(part) + '</strong>' : '<span>' + esc(part) + '</span>';
    }).join('');
    tip.hidden = false;
    const x = event && event.clientX ? event.clientX : tip.getBoundingClientRect().left + 12;
    const y = event && event.clientY ? event.clientY : tip.getBoundingClientRect().top - 8;
    tip.style.left = Math.min(x + 14, window.innerWidth - tip.offsetWidth - 12) + 'px';
    tip.style.top = Math.min(y + 16, window.innerHeight - tip.offsetHeight - 12) + 'px';
  }

  function hideMapTip() {
    elements.mapTip.hidden = true;
  }

  // ---- sidebar / chrome ---------------------------------------------------------

  function renderChrome(summary) {
    const binMode = summary.kind === 'bin';
    elements.binBanner.hidden = !binMode;
    if (elements.binToggle) {
      elements.binToggle.setAttribute('aria-checked', binMode ? 'true' : 'false');
    }
    elements.fileName.textContent = summary.name;
    elements.topFileName.textContent = summary.name;
    elements.topFormat.textContent = summary['format-label'];
    elements.topFileTab.setAttribute('aria-label', 'Current file: ' + summary.name);
    elements.formatValue.textContent = summary['format-label'];
    elements.fileFormatLine.textContent = binMode
      ? t('file.subline-bin')
      : t('file.subline-hex');
    elements.recordedValue.textContent = summary.stats['data-bytes'] + ' B / ' +
      state.rows.length + ' ' + t('file.rows');
    elements.mapNote.innerHTML =
      '<svg class="od-icon" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="8.5"></circle><path d="M12 11v5M12 8v.1"></path></svg>' +
      esc(binMode ? t('map.note-bin') : t('map.note-hex'));
    if (elements.baseReadout) {
      elements.baseReadout.value = summary.stats.min === null || summary.stats.min === 'null'
        ? '—' : formatAddress(summary.stats.min);
    }
    renderSegmentMap(summary);
    updateStatus();
    renderInspector();
  }

  // ---- load ----------------------------------------------------------------------

  async function refresh() {
    const summary = await api('api/workspace/state', { lang: window.BitsmithI18n.lang() });
    if (summary && summary.strings) window.BitsmithEngineStrings = summary.strings;
    state.summary = summary;
    if (!summary.loaded) {
      state.rows = [];
      state.populated = new Map();
      elements.hexRows.innerHTML = '';
      elements.binBanner.hidden = true;
      renderInspector();
      return;
    }
    const view = await api('api/image/view', { lang: window.BitsmithI18n.lang(), limit: 8192 });
    state.rows = view.rows || [];
    state.rowTruncated = !!view['row-truncated'];
    state.byStart = new Map(state.rows.map(function (row) { return [row.start, row]; }));
    state.populated = new Map();
    state.rows.forEach(function (row) {
      row.cells.forEach(function (byte, offset) {
        if (byte !== null && byte !== undefined && byte !== false) {
          state.populated.set(row.start + offset, byte);
        }
      });
    });
    if (!state.populated.size) {
      renderChrome(summary);
      return;
    }
    // Keep a sensible default selection near the top of the second segment.
    if (state.selected === null || !state.populated.has(state.selected)) {
      state.selected = state.populated.keys().next().value;
      state.anchor = state.selected;
      state.rangeStart = state.selected;
      state.rangeEnd = state.selected;
    }
    renderHex();
    renderChrome(summary);
  }

  // ---- actions ---------------------------------------------------------------------

  elements.gotoForm.addEventListener('submit', function (event) {
    event.preventDefault();
    const raw = elements.gotoInput.value.trim().replace(/^0x/i, '');
    if (!/^[0-9a-fA-F]+$/.test(raw)) {
      toast(t('toast.enter-address'), 'fail');
      return;
    }
    const address = parseInt(raw, 16);
    const rowStart = address - (address % 16);
    const row = state.byStart.get(rowStart);
    if (!row) {
      toast(t('toast.no-byte') + ' ' + formatAddress(address), 'warn');
      return;
    }
    const offset = address - rowStart;
    const cell = row.cells[offset];
    if (cell === null || cell === undefined || cell === false) {
      toast(t('toast.row-no-byte') + ' ' + formatAddress(rowStart), 'warn');
      return;
    }
    selectByte(address, false);
    const domRow = elements.hexRows.querySelector('.hex-row[data-row-start="' + rowStart + '"]');
    if (domRow) domRow.scrollIntoView({ block: 'center', inline: 'nearest' });
  });

  $('closeBytePop').addEventListener('click', function () { closePopover(true); });
  elements.bytePop.addEventListener('click', function (event) { event.stopPropagation(); });
  if (elements.focusBase) {
    elements.focusBase.addEventListener('click', function () {
      elements.baseReadout.focus();
      elements.baseReadout.select();
    });
  }

  document.addEventListener('click', function (event) {
    if (!state.popOpen) return;
    if (elements.bytePop.contains(event.target)) return;
    if (event.target.closest('.hex-byte')) return;
    closePopover(false);
  });

  document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape' && state.popOpen) {
      closePopover(true);
      return;
    }
    if (event.metaKey || event.ctrlKey || event.altKey) return;
    if (event.target.matches('input, textarea, select')) return;
    if (event.key === '1' || event.key === '2' || event.key === '3' || event.key === '4') {
      const routes = { '1': 'records.html', '2': 'image.html', '3': 'operations.html', '4': 'learn.html' };
      window.location.href = routes[event.key];
    }
  });

  elements.hexScroll.addEventListener('scroll', function () {
    if (state.popOpen) closePopover(false);
    hideMapTip();
  });

  window.addEventListener('resize', function () {
    if (state.popOpen && state.popAnchor) positionPopover(elements.bytePop, state.popAnchor);
    hideMapTip();
  });

  window.BitsmithI18n.ready(function () {
    refresh();
  });
})();
