/* =========================================================
   qhun22Music - UI (Trình phát / Thư viện / Quản trị)
   Kết nối PlayerEngine với giao diện trắng - xanh basic
   ========================================================= */
(function () {
  'use strict';

  var engine = new window.PlayerEngine();
  var LIB_GENRES = ['remix', 'lofi'];

  var state = {
    view: 'player',
    activeTab: 'remix',
    songs: { remix: [], lofi: [] },
    config: { username: 'qhun22', repo: 'AppMusic' },
    queueSelectMode: false,
    queueSelected: {},
    dragFrom: null
  };

  function $(id) { return document.getElementById(id); }
  function $$(sel, root) {
    return Array.prototype.slice.call((root || document).querySelectorAll(sel));
  }

  function escapeHtml(str) {
    return String(str == null ? '' : str).replace(/[&<>"']/g, function (m) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[m];
    });
  }

  var toastEl = $('toast');
  var toastTimer = null;
  function showToast(message, type) {
    if (!toastEl) return;
    toastEl.textContent = message;
    toastEl.className = 'toast show' + (type ? ' ' + type : '');
    if (toastTimer) { clearTimeout(toastTimer); }
    toastTimer = setTimeout(function () { toastEl.className = 'toast'; }, 3600);
  }

  window.copyToClipboard = function (text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(function () {
        showToast('Đã copy đường dẫn bài hát!', 'success');
      }).catch(function () { showToast('Không thể sao chép!', 'error'); });
    } else {
      showToast('Trình duyệt không hỗ trợ clipboard.', 'error');
    }
  };

  /* ---------------- Cấu hình repo GitHub Pages ---------------- */
  var cfgUsername = $('cfgUsername');
  var cfgRepo = $('cfgRepo');

  function initRepoConfig() {
    var hostname = window.location.hostname;
    var pathname = window.location.pathname.split('/').filter(Boolean);
    var savedUser = null;
    var savedRepo = null;
    try {
      savedUser = localStorage.getItem('music_hub_gh_user');
      savedRepo = localStorage.getItem('music_hub_gh_repo');
    } catch (e) { /* ignore */ }

    if (!savedUser && hostname.endsWith('.github.io')) { savedUser = hostname.split('.')[0]; }
    if (!savedRepo && pathname.length > 0) { savedRepo = pathname[0]; }

    state.config.username = savedUser || 'qhun22';
    state.config.repo = savedRepo || 'AppMusic';
    cfgUsername.value = state.config.username;
    cfgRepo.value = state.config.repo;
    updateUrlPreview();
  }

  function saveConfig() {
    state.config.username = cfgUsername.value.trim() || 'qhun22';
    state.config.repo = cfgRepo.value.trim() || 'AppMusic';
    try {
      localStorage.setItem('music_hub_gh_user', state.config.username);
      localStorage.setItem('music_hub_gh_repo', state.config.repo);
    } catch (e) { /* ignore */ }
    updateUrlPreview();
  }

  cfgUsername.addEventListener('input', saveConfig);
  cfgRepo.addEventListener('input', saveConfig);

  function buildSongUrl(genre, filename) {
    return 'https://' + state.config.username + '.github.io/' + state.config.repo +
      '/songs/' + genre + '/' + encodeURIComponent(filename);
  }

  function updateUrlPreview() {
    var preview = $('urlPreview');
    if (!preview) return;
    var genre = $('songGenre').value;
    var filename = $('songFilename').value.trim() || 'example.mp3';
    var safeFilename = /\.mp3$/i.test(filename) ? filename : filename + '.mp3';
    preview.textContent = buildSongUrl(genre, safeFilename);
  }

  $('songGenre').addEventListener('change', updateUrlPreview);
  $('songFilename').addEventListener('input', updateUrlPreview);

  /* ---------------- Chuyển view & mở sheet ---------------- */
  $$('#viewTabs .view-tab').forEach(function (btn) {
    btn.addEventListener('click', function () { switchView(btn.getAttribute('data-view')); });
  });

  function switchView(view) {
    state.view = view;
    $$('.view').forEach(function (v) { v.classList.remove('active'); });
    var target = $('view-' + view);
    if (target) { target.classList.add('active'); }
    $$('#viewTabs .view-tab').forEach(function (b) {
      b.classList.toggle('active', b.getAttribute('data-view') === view);
    });
  }

  var sheet = $('sheet');
  var sheetBackdrop = $('sheetBackdrop');

  function openSheet(panel) {
    if (!sheet) return;
    sheet.classList.add('open');
    sheet.setAttribute('aria-hidden', 'false');
    sheetBackdrop.classList.add('open');
    setSheetPanel(panel || 'queue');
  }

  function closeSheet() {
    if (!sheet) return;
    sheet.classList.remove('open');
    sheet.setAttribute('aria-hidden', 'true');
    sheetBackdrop.classList.remove('open');
  }

  function setSheetPanel(name) {
    $$('.sheet-panel').forEach(function (p) {
      p.classList.toggle('active', p.getAttribute('data-panel') === name);
    });
    $$('.sheet-tab').forEach(function (t) {
      t.classList.toggle('active', t.getAttribute('data-sheet') === name);
    });
  }

  $$('[data-open]').forEach(function (btn) {
    btn.addEventListener('click', function () { openSheet(btn.getAttribute('data-open')); });
  });
  $$('.sheet-tab').forEach(function (tab) {
    tab.addEventListener('click', function () { setSheetPanel(tab.getAttribute('data-sheet')); });
  });
  $('sheetClose').addEventListener('click', closeSheet);
  sheetBackdrop.addEventListener('click', closeSheet);

  /* ---------------- Thư viện: nạp & hiển thị ---------------- */
  function normalizeSongUrl(url, genre) {
    var u = String(url || '').trim();
    if (!u) { return u; }
    var m = u.match(/songs\/(remix|lofi)\/(.+)$/i);
    if (!m) {
      var name = u.split('/').pop();
      if (!name) { return u; }
      return 'https://' + state.config.username + '.github.io/' + state.config.repo +
        '/songs/' + genre + '/' + name;
    }
    return 'https://' + state.config.username + '.github.io/' + state.config.repo +
      '/songs/' + m[1].toLowerCase() + '/' + m[2];
  }

  function genreLabel(genre) { return genre === 'remix' ? 'Remix' : 'Lofi'; }

  function fetchLibrary(genre) {
    var url = 'https://' + state.config.username + '.github.io/' + state.config.repo +
      '/' + genre + '.json?t=' + Date.now();
    return fetch(url, { cache: 'no-store' })
      .then(function (res) {
        if (!res.ok) { throw new Error('HTTP ' + res.status); }
        return res.json();
      })
      .then(function (data) {
        state.songs[genre] = (Array.isArray(data) ? data : []).map(function (s) {
          return {
            id: s.id,
            title: s.title,
            url: normalizeSongUrl(s.url, genre),
            type: genreLabel(genre),
            genre: genre
          };
        });
        return state.songs[genre];
      });
  }

  function loadAll(silent) {
    return Promise.all(LIB_GENRES.map(function (g) {
      return fetchLibrary(g).catch(function (err) {
        showToast('Không tải được ' + g + '.json (' + err.message + ')', 'error');
        return [];
      });
    })).then(function () {
      updateBadges();
      renderLibrary();
      if (!silent) {
        var total = state.songs.remix.length + state.songs.lofi.length;
        showToast('Đã nạp ' + total + ' bài hát từ GitHub Pages.', 'success');
      }
    });
  }

  function updateBadges() {
    $('badgeRemix').textContent = state.songs.remix.length;
    $('badgeLofi').textContent = state.songs.lofi.length;
    $('statTotal').textContent = state.songs[state.activeTab].length;
    $('statGenre').textContent = genreLabel(state.activeTab);
  }

  function normalizeVi(str) {
    return String(str || '')
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/đ/g, 'd')
      .replace(/Đ/g, 'D')
      .toLowerCase()
      .trim();
  }

  function visibleList() {
    var list = state.songs[state.activeTab] || [];
    var q = normalizeVi($('searchSongs').value);
    if (!q) { return list.slice(); }
    return list.filter(function (s) { return normalizeVi(s.title).indexOf(q) >= 0; });
  }

  function renderLibrary() {
    var container = $('songListContainer');
    var list = visibleList();
    state.visible = list;
    var current = engine.currentSong();
    var currentUrl = current ? current.url : '';
    if (!list.length) {
      container.innerHTML =
        '<div class="empty-state">Không có bài hát nào để hiển thị.<br>' +
        'Hãy kiểm tra GitHub User/Repo ở góc trên, hoặc thêm bài mới trong tab Quản trị.</div>';
      return;
    }
    container.innerHTML = list.map(function (song, index) {
      var playing = song.url === currentUrl;
      return '' +
        '<div class="song-card' + (playing ? ' playing' : '') + '" data-index="' + index + '">' +
          '<div class="song-id">#' + escapeHtml(song.id) + '</div>' +
          '<div class="song-info">' +
            '<div class="song-title" title="' + escapeHtml(song.title) + '">' + escapeHtml(song.title) + '</div>' +
            '<div class="song-url" data-act="copy" title="Bấm để copy link">' + escapeHtml(song.url) + '</div>' +
          '</div>' +
          '<div class="song-actions">' +
            '<button type="button" class="mini-btn play" data-act="play">Phát ngay</button>' +
            '<button type="button" class="mini-btn" data-act="next">Phát tiếp theo</button>' +
            '<button type="button" class="mini-btn" data-act="queue">+ Hàng đợi</button>' +
            '<button type="button" class="mini-btn" data-act="copy">Copy</button>' +
            '<button type="button" class="mini-btn danger" data-act="remove">Xoá</button>' +
          '</div>' +
        '</div>';
    }).join('');
  }

  function playFromVisible(index, forceShuffle) {
    var list = (state.visible && state.visible.length) ? state.visible : state.songs[state.activeTab];
    if (!list.length) { showToast('Danh sách đang trống.', 'error'); return; }
    if (forceShuffle) { engine.setShuffle(true); }
    else if (engine.settings.autoShuffleOnPlay && !engine.settings.shuffle) { engine.setShuffle(true); }
    engine.setLibrary(state.songs[state.activeTab], state.activeTab);
    engine.setQueue(list, index, { type: genreLabel(state.activeTab) });
    engine.play();
    switchView('player');
    renderLibrary();
    showToast('Đang phát: ' + list[index].title, 'success');
  }

  $('genreTabs').addEventListener('click', function (e) {
    var btn = e.target.closest('.seg-btn');
    if (!btn) { return; }
    state.activeTab = btn.getAttribute('data-tab');
    $$('#genreTabs .seg-btn').forEach(function (b) {
      b.classList.toggle('active', b.getAttribute('data-tab') === state.activeTab);
    });
    updateBadges();
    renderLibrary();
    engine.setLibrary(state.songs[state.activeTab], state.activeTab);
  });

  $('searchSongs').addEventListener('input', renderLibrary);
  $('btnPlayAll').addEventListener('click', function () { playFromVisible(0, false); });
  $('btnShufflePlay').addEventListener('click', function () { playFromVisible(0, true); });

  $('songListContainer').addEventListener('click', function (e) {
    var actBtn = e.target.closest('[data-act]');
    var card = e.target.closest('.song-card');
    if (!card) { return; }
    var index = Number(card.getAttribute('data-index'));
    var song = (state.visible || [])[index];
    if (!song) { return; }
    var act = actBtn ? actBtn.getAttribute('data-act') : '';
    if (act === 'play') { playFromVisible(index, false); }
    else if (act === 'next') {
      engine.playNextSong(song, genreLabel(state.activeTab));
      showToast('Sẽ phát tiếp theo: ' + song.title, 'success');
    } else if (act === 'queue') {
      engine.addToQueue(song, genreLabel(state.activeTab));
      showToast('Đã thêm vào cuối hàng đợi: ' + song.title, 'success');
    } else if (act === 'copy') {
      window.copyToClipboard(song.url);
    } else if (act === 'remove') {
      removeSong(state.activeTab, song.id);
    }
  });

  /* ---------------- Trình phát: điều khiển ---------------- */
  var seekBar = $('seekBar');
  var volBar = $('volBar');
  var seeking = false;

  function fmtTime(seconds) {
    seconds = Math.max(0, Math.floor(seconds || 0));
    var h = Math.floor(seconds / 3600);
    var m = Math.floor((seconds % 3600) / 60);
    var s = seconds % 60;
    if (h > 0) { return h + ':' + (m < 10 ? '0' : '') + m + ':' + (s < 10 ? '0' : ''); }
    return m + ':' + (s < 10 ? '0' : '') + s;
  }

  function flash(side, text) {
    var el = $(side === 'left' ? 'flashLeft' : 'flashRight');
    if (!el) { return; }
    if (text) { el.textContent = text; }
    el.classList.add('show');
    setTimeout(function () { el.classList.remove('show'); }, 550);
  }

  $('btnPlay').addEventListener('click', function () {
    if (!engine.queue.length) {
      if (state.songs[state.activeTab].length) { playFromVisible(0, false); return; }
      showToast('Chưa có bài hát nào trong kho.', 'error');
      return;
    }
    engine.toggle();
  });

  $('btnPrev').addEventListener('click', function () { engine.prev(); });
  $('btnNext').addEventListener('click', function () { engine.next(false); });
  $('btnBack').addEventListener('click', function () {
    engine.skip(-engine.settings.seekStep);
    flash('left', '-' + engine.settings.seekStep + 's');
  });
  $('btnFwd').addEventListener('click', function () {
    engine.skip(engine.settings.seekStep);
    flash('right', '+' + engine.settings.seekStep + 's');
  });
  $('btnShuffle').addEventListener('click', function () {
    engine.setShuffle(!engine.settings.shuffle);
    showToast(engine.settings.shuffle
      ? 'Đã bật xáo trộn' + (engine.settings.smartShuffle ? ' (thông minh)' : '')
      : 'Đã tắt xáo trộn', 'success');
  });
  $('btnRepeat').addEventListener('click', function () {
    var mode = engine.cycleRepeat();
    showToast('Chế độ lặp lại: ' + repeatLabel(mode), 'success');
  });
  $('btnAB').addEventListener('click', function () { engine.cycleAB(); });
  $('btnMute').addEventListener('click', function () {
    var muted = engine.toggleMute();
    showToast(muted ? 'Đã tắt tiếng' : 'Đã bật lại tiếng', 'success');
  });

  function repeatLabel(mode) {
    if (mode === 'all') { return 'Lặp toàn bộ'; }
    if (mode === 'one') { return 'Lặp 1 bài'; }
    return 'Tắt';
  }

  seekBar.addEventListener('input', function () {
    seeking = true;
    var dur = engine.active && engine.active.el.duration;
    if (dur && isFinite(dur)) {
      var pos = dur * (Number(seekBar.value) / 1000);
      $('timeElapsed').textContent = fmtTime(pos);
      $('timeRemaining').textContent = '-' + fmtTime(dur - pos);
    }
  });
  seekBar.addEventListener('change', function () {
    var dur = engine.active && engine.active.el.duration;
    if (dur && isFinite(dur)) { engine.seekTo(dur * (Number(seekBar.value) / 1000)); }
    seeking = false;
  });

  volBar.addEventListener('input', function () {
    engine.setVolume(Number(volBar.value) / 100);
    $('volVal').textContent = volBar.value;
  });

  /* ---------------- Cử chỉ: vuốt đổi bài + chạm 2 lần tua ---------------- */
  (function bindGestures() {
    var area = $('coverArea');
    if (!area) { return; }
    var startX = 0;
    var startY = 0;
    var moved = false;
    var lastTapAt = 0;
    var lastTapSide = '';

    area.addEventListener('touchstart', function (e) {
      var t = e.changedTouches[0];
      startX = t.clientX;
      startY = t.clientY;
      moved = false;
    }, { passive: true });

    area.addEventListener('touchmove', function (e) {
      var t = e.changedTouches[0];
      if (Math.abs(t.clientX - startX) > 12 || Math.abs(t.clientY - startY) > 12) { moved = true; }
    }, { passive: true });

    area.addEventListener('touchend', function (e) {
      var t = e.changedTouches[0];
      var dx = t.clientX - startX;
      var dy = t.clientY - startY;
      if (Math.abs(dx) > 55 && Math.abs(dx) > Math.abs(dy)) {
        if (dx < 0) { engine.next(false); showToast('Vuốt trái → bài kế tiếp', 'success'); }
        else { engine.prev(); showToast('Vuốt phải → bài trước', 'success'); }
        return;
      }
      if (!moved) { handleTap(e); }
    }, { passive: true });

    area.addEventListener('click', function (e) {
      // Desktop: bấm 2 lần liên tiếp (trong 330ms) ở nửa trái/phải để tua ±step
      if (!moved) { doubleTapAt(e.clientX); }
    });

    function handleTap(e) {
      doubleTapAt(e.changedTouches ? e.changedTouches[0].clientX : e.clientX);
    }

    function doubleTapAt(clientX) {
      var now = Date.now();
      var side = clientX < area.getBoundingClientRect().left + area.clientWidth / 2 ? 'left' : 'right';
      if (now - lastTapAt < 330 && side === lastTapSide) {
        var step = engine.settings.doubleTapStep;
        if (side === 'left') { engine.skip(-step); flash('left', '-' + step + 's'); }
        else { engine.skip(step); flash('right', '+' + step + 's'); }
        lastTapAt = 0;
        return;
      }
      lastTapAt = now;
      lastTapSide = side;
    }
  })();

  /* ---------------- Đồng bộ UI với engine ---------------- */
  function setPlayIcon(playing) {
    var icon = $('iconPlay');
    if (icon) {
      icon.innerHTML = playing
        ? '<path d="M6 5h4v14H6zM14 5h4v14h-4z"/>'
        : '<path d="M8 5v14l11-7z"/>';
    }
    $('btnPlay').setAttribute('title', playing ? 'Tạm dừng (Space)' : 'Phát (Space)');
    $('nowStatus').textContent = playing ? 'Đang phát' : 'Tạm dừng';
  }

  function updateNowPlaying(song) {
    $('nowTitle').textContent = song ? song.title : 'Chưa chọn bài hát';
    $('nowGenre').textContent = song ? (song.type || '—') : '—';
    var total = engine.order ? engine.order.length : 0;
    $('nowIndex').textContent = total ? ((engine.orderPos + 1) + ' / ' + total) : '0 / 0';
    $('statPlayed').textContent = total ? ((engine.orderPos + 1) + ' / ' + total) : '0';
    $('statTotal').textContent = engine.queue.length || state.songs[state.activeTab].length;
    document.title = song ? (song.title + ' • qhun22Music') : 'qhun22Music · Trình phát nhạc & Quản trị';
  }

  function updateTime(info) {
    if (seeking) { return; }
    var dur = info.duration || 0;
    var pos = info.position || 0;
    if (dur > 0) {
      seekBar.value = Math.round(1000 * clampNumber(pos / dur, 0, 1));
      $('timeElapsed').textContent = fmtTime(pos);
      $('timeRemaining').textContent = '-' + fmtTime(dur - pos);
    }
  }

  function clampNumber(v, min, max) { return v < min ? min : (v > max ? max : v); }

  function renderAB(ab) {
    var info = $('abInfo');
    var btn = $('btnAB');
    if (!ab || ab.a === null) {
      info.classList.remove('show');
      btn.classList.remove('active');
      info.textContent = '';
      return;
    }
    btn.classList.add('active');
    info.classList.add('show');
    if (ab.b === null) {
      info.textContent = 'Điểm A = ' + fmtTime(ab.a) + ' · bấm A-B lần nữa để đặt điểm B';
    } else {
      info.textContent = 'Đang lặp đoạn A-B: ' + fmtTime(ab.a) + ' → ' + fmtTime(ab.b) +
        ' (dài ' + fmtTime(ab.b - ab.a) + ') · bấm A-B để tắt';
    }
  }

  function renderTimer(info) {
    var tag = info.active ? (info.endOfTrack ? 'Hết bài' : info.leftText) : 'Tắt';
    $('timerTag').textContent = tag;
    $('statTimer').textContent = tag;
    $('timerStatus').textContent = info.active
      ? (info.endOfTrack
        ? 'Sẽ tắt sau khi hết bài hiện tại.'
        : ('Còn lại ' + info.leftText + ' (tổng ' + info.minutes + ' phút).'))
      : 'Chưa hẹn giờ.';
  }

  function renderUpNext() {
    var box = $('upNextList');
    var order = engine.order || [];
    var rows = [];
    for (var i = engine.orderPos + 1; i < order.length && rows.length < 6; i++) {
      var song = engine.queue[order[i]];
      if (!song) { continue; }
      rows.push('<div class="upnext-item" data-pos="' + i + '">' +
        '<span class="n">' + (rows.length + 1) + '</span>' +
        '<span class="t">' + escapeHtml(song.title) + '</span>' +
        '<span class="m">' + escapeHtml(song.type || '') + '</span></div>');
    }
    box.innerHTML = rows.length
      ? rows.join('')
      : '<div class="empty-state" style="padding:16px 6px">Chưa có bài nào phía sau. Thêm bài trong tab Thư viện.</div>';
  }

  function updateQueueTag() {
    var total = engine.order ? engine.order.length : 0;
    var after = total ? Math.max(0, total - engine.orderPos - 1) : 0;
    $('queueTag').textContent = String(total);
    $('queueCount2').textContent = String(after);
    var now = engine.currentSong();
    $('queueNow').textContent = now ? now.title : '—';
  }

  $('upNextList').addEventListener('click', function (e) {
    var item = e.target.closest('[data-pos]');
    if (!item) { return; }
    engine.startTrack(Number(item.getAttribute('data-pos')), {});
  });

  engine.on('track', function (song) {
    updateNowPlaying(song);
    renderUpNext();
    renderQueue();
    renderLibrary();
    updateQueueTag();
  });
  engine.on('state', function (s) { setPlayIcon(!!s.playing); });
  engine.on('time', updateTime);
  engine.on('queue', function () {
    renderQueue();
    renderUpNext();
    renderLibrary();
    updateQueueTag();
  });
  engine.on('repeat', function (mode) {
    $('repeatTag').textContent = repeatLabel(mode);
    $('btnRepeat').classList.toggle('active', mode !== 'off');
  });
  engine.on('shuffle', function (on) { $('btnShuffle').classList.toggle('active', !!on); });
  engine.on('ab', renderAB);
  engine.on('settings', function () { syncSettingsUI(); });
  engine.on('presets', renderCustomPresets);
  engine.on('timer', renderTimer);
  engine.on('warn', function (msg) { showToast(msg); });
  engine.on('queueEnd', function () { showToast('Đã phát hết danh sách (chế độ lặp đang tắt).'); });
  engine.on('rate', function (r) {
    $('speedTag').textContent = r.speed.toFixed(2).replace(/0+$/, '').replace(/\.$/, '') + 'x';
    $('pitchTag').textContent = (r.pitch > 0 ? '+' : '') + r.pitch;
  });

  /* ---------------- Hàng đợi: hiển thị & kéo-thả ---------------- */
  function renderQueue() {
    var box = $('queueList');
    var current = engine.currentQueueIndex();
    var html = engine.queue.map(function (song, i) {
      var isCurrent = i === current;
      var checked = state.queueSelected[i] ? ' checked' : '';
      return '<div class="queue-item' + (isCurrent ? ' playing' : '') + '" draggable="' +
        (state.queueSelectMode ? 'false' : 'true') + '" data-index="' + i + '">' +
        (state.queueSelectMode
          ? '<input type="checkbox" data-check="' + i + '"' + checked + '>'
          : '<span class="q-handle" title="Kéo để đổi thứ tự">&#8942;&#8942;</span>') +
        '<span class="q-idx">' + (isCurrent ? '&#9658;' : '#' + escapeHtml(song.id)) + '</span>' +
        '<span class="q-title" title="' + escapeHtml(song.title) + '">' + escapeHtml(song.title) +
        ' <span class="muted">' + escapeHtml(song.type || '') + '</span></span>' +
        '<button type="button" class="q-del" data-del="' + i + '" title="Xoá khỏi hàng đợi">&#10005;</button>' +
        '</div>';
    }).join('');
    box.innerHTML = html || '<div class="empty-state" style="padding:16px">Hàng đợi đang trống.</div>';
    updateQueueTag();
  }

  $('queueList').addEventListener('dragstart', function (e) {
    var item = e.target.closest('.queue-item');
    if (!item || state.queueSelectMode) { return; }
    state.dragFrom = Number(item.getAttribute('data-index'));
    item.classList.add('dragging');
    try { e.dataTransfer.setData('text/plain', String(state.dragFrom)); } catch (err) { /* ignore */ }
  });

  $('queueList').addEventListener('dragover', function (e) {
    var item = e.target.closest('.queue-item');
    if (!item || state.dragFrom === null) { return; }
    e.preventDefault();
    $$('.queue-item', $('queueList')).forEach(function (el) { el.classList.remove('drop-target'); });
    item.classList.add('drop-target');
  });

  $('queueList').addEventListener('drop', function (e) {
    var item = e.target.closest('.queue-item');
    if (!item || state.dragFrom === null) { return; }
    e.preventDefault();
    var to = Number(item.getAttribute('data-index'));
    if (state.dragFrom !== to) { engine.reorderQueue(state.dragFrom, to); }
    state.dragFrom = null;
  });

  $('queueList').addEventListener('dragend', function () {
    state.dragFrom = null;
    $$('.queue-item').forEach(function (el) {
      el.classList.remove('dragging');
      el.classList.remove('drop-target');
    });
  });

  $('queueList').addEventListener('click', function (e) {
    var del = e.target.closest('[data-del]');
    if (del) {
      engine.removeFromQueue(Number(del.getAttribute('data-del')));
      return;
    }
    var check = e.target.closest('[data-check]');
    if (check) {
      var idx = Number(check.getAttribute('data-check'));
      if (check.checked) { state.queueSelected[idx] = true; }
      else { delete state.queueSelected[idx]; }
      return;
    }
    if (state.queueSelectMode) { return; }
    var item = e.target.closest('.queue-item');
    if (!item) { return; }
    var qi = Number(item.getAttribute('data-index'));
    var pos = engine.order.indexOf(qi);
    var song = engine.queue[qi];
    if (pos >= 0 && song) {
      engine.startTrack(pos, {});
      showToast('Đang phát: ' + song.title, 'success');
    }
  });

  $('btnQueueSelect').addEventListener('click', function () {
    state.queueSelectMode = !state.queueSelectMode;
    state.queueSelected = {};
    this.textContent = state.queueSelectMode ? 'Xong' : 'Chọn nhiều';
    $('btnQueueRemoveSelected').hidden = !state.queueSelectMode;
    renderQueue();
  });

  $('btnQueueRemoveSelected').addEventListener('click', function () {
    var keys = Object.keys(state.queueSelected);
    if (!keys.length) { showToast('Chưa chọn bài nào.', 'error'); return; }
    keys.sort(function (a, b) { return Number(b) - Number(a); }).forEach(function (k) {
      engine.removeFromQueue(Number(k));
    });
    state.queueSelected = {};
    renderQueue();
    showToast('Đã xoá ' + keys.length + ' bài khỏi hàng đợi.', 'success');
  });

  $('btnQueueClear').addEventListener('click', function () {
    if (!engine.queue.length) { showToast('Hàng đợi đã trống.', 'error'); return; }
    if (confirm('Xoá sạch hàng đợi và dừng nhạc?')) {
      engine.clearQueue();
      showToast('Đã xoá sạch hàng đợi.', 'success');
    }
  });

  $('btnQueueSave').addEventListener('click', function () {
    if (!engine.queue.length) { showToast('Hàng đợi đang trống.', 'error'); return; }
    var name = prompt('Tên playlist (sẽ tải về file JSON):', 'playlist-qhun22');
    if (!name) { return; }
    var safe = name.replace(/[\\/:*?"<>|]+/g, '-').trim() || 'playlist';
    downloadJSON(safe + '.json', engine.queuePlaylist());
  });

  /* ---------------- EQ & DSP ---------------- */
  var EQ_FREQS_UI = [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];

  function buildEqBands() {
    $('eqBands').innerHTML = EQ_FREQS_UI.map(function (f, i) {
      var label = f >= 1000 ? (f / 1000) + 'k' : String(f);
      return '<div class="eq-band">' +
        '<input type="range" data-band="' + i + '" min="-12" max="12" step="1" value="0" title="' + f + ' Hz">' +
        '<span class="db" data-db="' + i + '">0</span>' +
        '<span class="hz">' + label + '</span>' +
        '</div>';
    }).join('');
  }
  buildEqBands();

  $('eqBands').addEventListener('input', function (e) {
    var input = e.target.closest('[data-band]');
    if (!input) { return; }
    var band = Number(input.getAttribute('data-band'));
    var value = Number(input.value);
    engine.setEqBand(band, value);
    var label = $('eqBands').querySelector('[data-db="' + band + '"]');
    if (label) { label.textContent = (value > 0 ? '+' : '') + value; }
    $$('#eqPresetRow .chip').forEach(function (c) { c.classList.remove('active'); });
  });

  $('eqPresetRow').addEventListener('click', function (e) {
    var chip = e.target.closest('[data-preset]');
    if (!chip) { return; }
    engine.applyEqPreset(chip.getAttribute('data-preset'));
    showToast('Đã áp dụng preset: ' + chip.textContent.trim(), 'success');
  });

  $('btnEqReset').addEventListener('click', function () {
    engine.applyEqPreset('flat');
    showToast('EQ đã về 0 dB (Flat).', 'success');
  });

  $('btnEqSave').addEventListener('click', function () {
    var name = prompt('Tên preset riêng (lưu trong máy):', 'Preset của tôi');
    if (!name) { return; }
    if (engine.saveCustomPreset(name)) { showToast('Đã lưu preset: ' + name, 'success'); }
  });

  function renderCustomPresets(presets) {
    var keys = Object.keys(presets || {});
    if (!keys.length) {
      $('customPresets').innerHTML = '<span class="hint-line">Chưa có preset riêng nào.</span>';
      return;
    }
    $('customPresets').innerHTML = keys.map(function (k) {
      return '<span class="preset-chip" data-load-preset="' + escapeHtml(k) + '">' + escapeHtml(k) +
        '<button type="button" data-del-preset="' + escapeHtml(k) + '" title="Xoá preset">&#10005;</button></span>';
    }).join('');
  }

  $('customPresets').addEventListener('click', function (e) {
    var del = e.target.closest('[data-del-preset]');
    if (del) {
      engine.deleteCustomPreset(del.getAttribute('data-del-preset'));
      showToast('Đã xoá preset.', 'success');
      return;
    }
    var chip = e.target.closest('[data-load-preset]');
    if (chip) { engine.loadCustomPreset(chip.getAttribute('data-load-preset')); }
  });

  $('eqEnabled').addEventListener('change', function () { engine.setEqEnabled(this.checked); });
  $('bassBar').addEventListener('input', function () {
    engine.setBass(Number(this.value));
    $('bassVal').textContent = Number(this.value).toFixed(1).replace(/\.0$/, '') + ' dB';
  });
  $('trebleBar').addEventListener('input', function () {
    engine.setTreble(Number(this.value));
    $('trebleVal').textContent = Number(this.value).toFixed(1).replace(/\.0$/, '') + ' dB';
  });
  $('widthBar').addEventListener('input', function () {
    engine.setWidth(Number(this.value));
    $('widthVal').textContent = this.value + '%';
  });
  $('balanceBar').addEventListener('input', function () {
    var v = Number(this.value);
    engine.setBalance(v);
    $('balanceVal').textContent = v === 0 ? 'Giữa' : (v < 0 ? ('Trái ' + Math.abs(v) + '%') : ('Phải ' + v + '%'));
  });
  $('monoSwitch').addEventListener('change', function () { engine.setMono(this.checked); });
  $('normSwitch').addEventListener('change', function () {
    engine.updateSetting('normalize', this.checked);
    showToast(this.checked ? 'Bật cân bằng độ lớn (ước lượng).' : 'Đã tắt cân bằng độ lớn.', 'success');
  });

  /* ---------------- Tốc độ & Cao độ ---------------- */
  $('speedRow').addEventListener('click', function (e) {
    var chip = e.target.closest('[data-speed]');
    if (!chip) { return; }
    engine.setSpeed(Number(chip.getAttribute('data-speed')));
    showToast('Tốc độ phát: ' + chip.textContent.trim(), 'success');
  });
  $('speedBar').addEventListener('input', function () {
    engine.setSpeed(Number(this.value));
    $('speedBarVal').textContent = Number(this.value).toFixed(2) + 'x';
  });
  $('pitchRow').addEventListener('click', function (e) {
    var chip = e.target.closest('[data-pitch]');
    if (!chip) { return; }
    var v = Number(chip.getAttribute('data-pitch'));
    engine.setPitch(v);
    showToast(v === 0
      ? 'Đã trở về cao độ gốc.'
      : ('Cao độ: ' + (v > 0 ? '+' : '') + v + ' nửa cung (tempo đổi theo).'), 'success');
  });
  $('pitchBar').addEventListener('input', function () {
    engine.setPitch(Number(this.value));
    $('pitchBarVal').textContent = this.value;
  });

  /* ---------------- Hẹn giờ tắt nhạc ---------------- */
  $('timerRow').addEventListener('click', function (e) {
    var chip = e.target.closest('[data-timer]');
    if (!chip) { return; }
    var minutes = Number(chip.getAttribute('data-timer'));
    engine.startTimer(minutes);
    showToast('Đã hẹn giờ tắt nhạc sau ' + minutes + ' phút.', 'success');
  });
  $('timerBar').addEventListener('input', function () {
    $('timerBarVal').textContent = this.value + ' phút';
  });
  $('timerEndOfTrack').addEventListener('change', function () {
    engine.updateSetting('timerEndOfTrack', this.checked);
  });
  $('timerFade').addEventListener('change', function () {
    engine.updateSetting('timerFade', this.checked);
  });
  $('btnTimerStart').addEventListener('click', function () {
    var minutes = Number($('timerBar').value);
    engine.startTimer(minutes);
    showToast('Đã hẹn giờ tắt nhạc sau ' + minutes + ' phút.', 'success');
  });
  $('btnTimerCancel').addEventListener('click', function () {
    engine.cancelTimer();
    showToast('Đã huỷ hẹn giờ.', 'success');
  });

  /* ---------------- Cài đặt hành vi phát ---------------- */
  $('setAutoShuffleOnPlay').addEventListener('change', function () {
    engine.updateSetting('autoShuffleOnPlay', this.checked);
  });
  $('setSmartShuffle').addEventListener('change', function () {
    engine.updateSetting('smartShuffle', this.checked);
    showToast(this.checked ? 'Xáo trộn thông minh: đã bật.' : 'Xáo trộn thông minh: đã tắt.', 'success');
  });
  $('setBlendRadio').addEventListener('change', function () {
    engine.updateSetting('blendRadio', this.checked);
    showToast(this.checked ? 'Radio: sẽ tự chèn bài cùng thể loại khi hết danh sách.' : 'Radio: đã tắt.', 'success');
  });
  $('setAutoplayNext').addEventListener('change', function () {
    engine.updateSetting('autoplayNext', this.checked);
  });
  $('setPrevRule').addEventListener('change', function () {
    engine.updateSetting('prevRule', this.checked);
  });
  $('setAutoplayPeripheral').addEventListener('change', function () {
    engine.updateSetting('autoplayPeripheral', this.checked);
  });
  $('setPauseUnplug').addEventListener('change', function () {
    engine.updateSetting('pauseUnplug', this.checked);
  });
  $('setShake').addEventListener('change', function () {
    engine.updateSetting('shake', this.checked);
    if (this.checked) { requestMotionPermission(true); }
    else { window.removeEventListener('devicemotion', onMotion); }
  });
  $('btnShakePermission').addEventListener('click', function () { requestMotionPermission(false); });

  var lastShakeAt = 0;

  function onMotion(e) {
    if (!engine.settings.shake) { return; }
    var a = e.accelerationIncludingGravity || e.acceleration;
    if (!a) { return; }
    var magnitude = Math.abs(a.x || 0) + Math.abs(a.y || 0) + Math.abs(a.z || 0);
    if (magnitude > 38 && Date.now() - lastShakeAt > 1500) {
      lastShakeAt = Date.now();
      engine.next(false);
      showToast('Lắc máy → bài kế tiếp', 'success');
    }
  }

  function requestMotionPermission(silent) {
    var DME = window.DeviceMotionEvent;
    if (!DME) {
      if (!silent) { showToast('Thiết bị không hỗ trợ cảm biến chuyển động.', 'error'); }
      return;
    }
    if (typeof DME.requestPermission === 'function') {
      DME.requestPermission().then(function (res) {
        if (res === 'granted') {
          window.addEventListener('devicemotion', onMotion);
          engine.updateSetting('shake', true);
          showToast('Đã bật lắc máy để đổi bài.', 'success');
        } else {
          showToast('Bạn chưa cho phép truy cập cảm biến chuyển động.', 'error');
        }
      }).catch(function () { showToast('Không xin được quyền cảm biến.', 'error'); });
    } else {
      window.addEventListener('devicemotion', onMotion);
      if (!silent) { showToast('Đã bật lắc máy để đổi bài.', 'success'); }
    }
  }

  $('setSeekStep').addEventListener('change', function () {
    var v = Number(this.value);
    engine.updateSetting('seekStep', v);
    $('tagBack').textContent = v + 's';
    $('tagFwd').textContent = v + 's';
  });
  $('setDoubleTapStep').addEventListener('change', function () {
    engine.updateSetting('doubleTapStep', Number(this.value));
  });
  $('setGapless').addEventListener('change', function () {
    engine.setGapless(this.checked);
    showToast(this.checked ? 'Gapless: giảm tối đa khoảng lặng giữa 2 bài.' : 'Gapless: đã tắt.', 'success');
  });
  $('setCrossfadeBar').addEventListener('input', function () {
    var v = Number(this.value);
    engine.setCrossfade(v);
    $('setCrossfadeVal').textContent = v === 0 ? 'Tắt' : (v + 's');
  });
  $('setFadeBar').addEventListener('input', function () {
    var v = Number(this.value);
    engine.setFade(v);
    $('setFadeVal').textContent = v.toFixed(2) + 's';
  });
  $('setResume').addEventListener('change', function () {
    engine.updateSetting('resume', this.checked);
    if (!this.checked) { engine.clearSession(); }
  });
  $('setResumeAutoPlay').addEventListener('change', function () {
    engine.updateSetting('resumeAutoPlay', this.checked);
  });
  $('btnResetData').addEventListener('click', function () {
    if (!confirm('Xoá toàn bộ cài đặt, phiên nghe và dữ liệu cân bằng âm lượng đã lưu?')) { return; }
    engine.resetStorage();
    syncSettingsUI();
    showToast('Đã xoá dữ liệu đã lưu.', 'success');
  });

  /* ---------------- Đồng bộ toàn bộ control theo settings ---------------- */
  function fmtDb(v) {
    var n = Number(v) || 0;
    return (n > 0 ? '+' : '') + (Math.round(n * 10) / 10) + ' dB';
  }

  function syncSettingsUI() {
    var s = engine.settings;
    volBar.value = Math.round(s.volume * 100);
    $('volVal').textContent = String(Math.round(s.volume * 100));
    $('btnShuffle').classList.toggle('active', !!s.shuffle);
    $('btnRepeat').classList.toggle('active', s.repeat !== 'off');
    $('repeatTag').textContent = repeatLabel(s.repeat);
    $('speedBar').value = s.speed;
    $('speedBarVal').textContent = Number(s.speed).toFixed(2) + 'x';
    $('speedTag').textContent = Number(s.speed).toFixed(2).replace(/0+$/, '').replace(/\.$/, '') + 'x';
    $('pitchBar').value = s.pitch;
    $('pitchBarVal').textContent = String(s.pitch);
    $('pitchTag').textContent = (s.pitch > 0 ? '+' : '') + s.pitch;
    $$('#speedRow .chip').forEach(function (c) {
      c.classList.toggle('active', Number(c.getAttribute('data-speed')) === Number(s.speed));
    });
    $$('#pitchRow .chip').forEach(function (c) {
      c.classList.toggle('active', Number(c.getAttribute('data-pitch')) === Number(s.pitch));
    });
    $('eqEnabled').checked = !!s.eqEnabled;
    $$('#eqPresetRow .chip').forEach(function (c) {
      c.classList.toggle('active', c.getAttribute('data-preset') === s.eqPreset);
    });
    (s.eqGain || []).forEach(function (v, i) {
      var input = $('eqBands').querySelector('[data-band="' + i + '"]');
      var db = $('eqBands').querySelector('[data-db="' + i + '"]');
      if (input) { input.value = v; }
      if (db) { db.textContent = (v > 0 ? '+' : '') + v; }
    });
    $('bassBar').value = s.bass;
    $('bassVal').textContent = fmtDb(s.bass);
    $('trebleBar').value = s.treble;
    $('trebleVal').textContent = fmtDb(s.treble);
    $('widthBar').value = s.width;
    $('widthVal').textContent = s.width + '%';
    $('balanceBar').value = s.balance;
    $('balanceVal').textContent = s.balance === 0 ? 'Giữa'
      : (s.balance < 0 ? ('Trái ' + Math.abs(s.balance) + '%') : ('Phải ' + s.balance + '%'));
    $('monoSwitch').checked = !!s.mono;
    $('normSwitch').checked = !!s.normalize;
    $('setAutoShuffleOnPlay').checked = !!s.autoShuffleOnPlay;
    $('setSmartShuffle').checked = !!s.smartShuffle;
    $('setBlendRadio').checked = !!s.blendRadio;
    $('setAutoplayNext').checked = !!s.autoplayNext;
    $('setPrevRule').checked = !!s.prevRule;
    $('setAutoplayPeripheral').checked = !!s.autoplayPeripheral;
    $('setPauseUnplug').checked = !!s.pauseUnplug;
    $('setShake').checked = !!s.shake;
    $('setSeekStep').value = String(s.seekStep);
    $('tagBack').textContent = s.seekStep + 's';
    $('tagFwd').textContent = s.seekStep + 's';
    $('setDoubleTapStep').value = String(s.doubleTapStep);
    $('setGapless').checked = !!s.gapless;
    $('setCrossfadeBar').value = s.crossfade;
    $('setCrossfadeVal').textContent = Number(s.crossfade) === 0 ? 'Tắt' : (s.crossfade + 's');
    $('setFadeBar').value = s.fade;
    $('setFadeVal').textContent = Number(s.fade).toFixed(2) + 's';
    $('setResume').checked = !!s.resume;
    $('setResumeAutoPlay').checked = !!s.resumeAutoPlay;
    $('timerEndOfTrack').checked = !!s.timerEndOfTrack;
    $('timerFade').checked = !!s.timerFade;
    renderCustomPresets(s.customPresets);
  }

  /* ---------------- Phím tắt ---------------- */
  document.addEventListener('keydown', function (e) {
    var tag = (e.target.tagName || '').toLowerCase();
    if (tag === 'input' || tag === 'textarea' || tag === 'select' || e.target.isContentEditable) { return; }
    var step = engine.settings.seekStep;
    var key = e.key;
    if (key === ' ') { e.preventDefault(); engine.toggle(); }
    else if (key === 'ArrowRight') {
      e.preventDefault();
      if (e.ctrlKey || e.metaKey) { engine.next(false); } else { engine.skip(step); flash('right', '+' + step + 's'); }
    } else if (key === 'ArrowLeft') {
      e.preventDefault();
      if (e.ctrlKey || e.metaKey) { engine.prev(); } else { engine.skip(-step); flash('left', '-' + step + 's'); }
    } else if (key === 'ArrowUp') { e.preventDefault(); engine.setVolume(engine.settings.volume + 0.05); }
    else if (key === 'ArrowDown') { e.preventDefault(); engine.setVolume(engine.settings.volume - 0.05); }
    else if (key === 's' || key === 'S') { engine.setShuffle(!engine.settings.shuffle); }
    else if (key === 'r' || key === 'R') { engine.cycleRepeat(); }
    else if (key === 'm' || key === 'M') { engine.toggleMute(); }
    else if (key === 'q' || key === 'Q') { openSheet('queue'); }
    else if (key === 'e' || key === 'E') { openSheet('eq'); }
    else if (key === 'Escape') { closeSheet(); }
  });

  /* ---------------- Thiết bị âm thanh ngoài ---------------- */
  var devicesSupported = engine.watchDevices(function (change) {
    if (change === 'disconnected' && engine.settings.pauseUnplug && engine.isPlaying) {
      engine.pause();
      showToast('Đã rút tai nghe / ngắt Bluetooth – tạm dừng nhạc.');
    } else if (change === 'connected' && engine.settings.autoplayPeripheral && !engine.isPlaying) {
      engine.play();
      showToast('Đã kết nối thiết bị âm thanh – tự phát nhạc.', 'success');
    }
  });

  /* ---------------- Quản trị: thêm bài / gợi ý / cảnh báo trùng ---------------- */
  var fileInput = $('fileInput');
  var fileNotice = $('fileNotice');
  var songTitle = $('songTitle');
  var songFilename = $('songFilename');
  var songGenre = $('songGenre');
  var titleSuggestions = $('titleSuggestions');
  var dupeAlert = $('dupeAlert');
  var suggestState = { items: [], activeIndex: -1 };

  fileInput.addEventListener('change', function (e) {
    var file = e.target.files[0];
    if (!file) { return; }
    fileNotice.textContent = file.name;
    songTitle.value = file.name.replace(/\.[^/.]+$/, '');
    // Giữ NGUYÊN tên file thật (kể cả dấu cách) để URL khớp chính xác file mp3 trên repo
    songFilename.value = file.name;
    updateUrlPreview();
    updateDupeAlert();
    renderTitleSuggestions(songTitle.value);
  });

  function collectAllTitles() {
    var all = [];
    LIB_GENRES.forEach(function (genre) {
      (state.songs[genre] || []).forEach(function (song) {
        all.push({ id: song.id, title: song.title, url: song.url, genre: genre });
      });
    });
    return all;
  }

  function getExactDupe(title) {
    var target = normalizeVi(title);
    if (!target) { return null; }
    var found = null;
    collectAllTitles().some(function (entry) {
      if (normalizeVi(entry.title) === target) { found = entry; return true; }
      return false;
    });
    return found;
  }

  function findTitleMatches(query) {
    var q = normalizeVi(query);
    if (!q) { return []; }
    var starts = [];
    var contains = [];
    collectAllTitles().forEach(function (entry) {
      var pos = normalizeVi(entry.title).indexOf(q);
      if (pos === 0) { starts.push(entry); }
      else if (pos > 0) { contains.push(entry); }
    });
    return starts.concat(contains).slice(0, 8);
  }

  function highlightMatch(raw, query) {
    var q = normalizeVi(query);
    if (!q) { return escapeHtml(raw); }
    var norm = '';
    var map = [];
    for (var i = 0; i < raw.length; i++) {
      var n = normalizeVi(raw[i]);
      for (var j = 0; j < n.length; j++) { map.push(i); }
      norm += n;
    }
    var p = norm.indexOf(q);
    if (p < 0) { return escapeHtml(raw); }
    var start = map[p];
    var end = map[Math.min(p + q.length - 1, map.length - 1)] + 1;
    return escapeHtml(raw.slice(0, start)) + '<mark>' + escapeHtml(raw.slice(start, end)) +
      '</mark>' + escapeHtml(raw.slice(end));
  }

  function renderTitleSuggestions(query) {
    var matches = findTitleMatches(query);
    suggestState.items = matches;
    suggestState.activeIndex = -1;
    if (!matches.length) {
      titleSuggestions.classList.remove('open');
      titleSuggestions.innerHTML = '';
      return;
    }
    titleSuggestions.innerHTML =
      '<div class="suggest-head">Đã có trong kho (' + matches.length + ') – bấm để dùng tên này</div>' +
      matches.map(function (entry, i) {
        return '<div class="suggest-item" data-suggest="' + i + '">' +
          '<span class="suggest-title">' + highlightMatch(entry.title, query) + '</span>' +
          '<span class="suggest-meta">' +
            '<span class="suggest-badge genre-' + entry.genre + '">' + genreLabel(entry.genre) + '</span>' +
            '<span class="suggest-badge">#' + escapeHtml(entry.id) + '</span>' +
          '</span></div>';
      }).join('');
    titleSuggestions.classList.add('open');
  }

  function markActiveSuggestion() {
    $$('.suggest-item', titleSuggestions).forEach(function (el, i) {
      el.classList.toggle('active', i === suggestState.activeIndex);
    });
  }

  function applySuggestion(i) {
    var entry = suggestState.items[i];
    if (!entry) { return; }
    songTitle.value = entry.title;
    titleSuggestions.classList.remove('open');
    updateDupeAlert();
    showToast('Đã dùng tên có sẵn #' + entry.id + ' – ' + genreLabel(entry.genre) + '.', 'success');
  }

  titleSuggestions.addEventListener('click', function (e) {
    var item = e.target.closest('[data-suggest]');
    if (!item) { return; }
    applySuggestion(Number(item.getAttribute('data-suggest')));
  });

  songTitle.addEventListener('input', function () {
    renderTitleSuggestions(songTitle.value);
    updateDupeAlert();
  });
  songTitle.addEventListener('focus', function () {
    if (songTitle.value.trim().length >= 2) { renderTitleSuggestions(songTitle.value); }
  });
  songTitle.addEventListener('keydown', function (e) {
    if (!titleSuggestions.classList.contains('open')) { return; }
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      suggestState.activeIndex = Math.min(suggestState.activeIndex + 1, suggestState.items.length - 1);
      markActiveSuggestion();
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      suggestState.activeIndex = Math.max(suggestState.activeIndex - 1, 0);
      markActiveSuggestion();
    } else if (e.key === 'Enter' && suggestState.activeIndex >= 0) {
      e.preventDefault();
      applySuggestion(suggestState.activeIndex);
    } else if (e.key === 'Escape') {
      titleSuggestions.classList.remove('open');
    }
  });
  document.addEventListener('click', function (e) {
    if (!e.target.closest('.autocomplete')) { titleSuggestions.classList.remove('open'); }
  });

  function updateDupeAlert() {
    var title = songTitle.value.trim();
    if (!title) {
      dupeAlert.className = 'dupe-alert';
      dupeAlert.textContent = '';
      return;
    }
    var dupe = getExactDupe(title);
    if (dupe) {
      dupeAlert.className = 'dupe-alert show';
      dupeAlert.innerHTML = 'Bài <b>' + escapeHtml(dupe.title) + '</b> đã có trong kho (' +
        genreLabel(dupe.genre) + ' #' + escapeHtml(dupe.id) + '). Bấm Thêm vẫn được nhưng sẽ bị trùng.';
    } else {
      dupeAlert.className = 'dupe-alert ok show';
      dupeAlert.textContent = 'Tên này chưa có trong kho – có thể thêm mới.';
    }
  }

  $('btnAddSong').addEventListener('click', function () {
    var genre = songGenre.value;
    var title = songTitle.value.trim();
    var filename = songFilename.value.trim();
    if (!title) { showToast('Chưa nhập tên bài hát.', 'error'); return; }
    if (!filename) { showToast('Chưa nhập tên file trên repo.', 'error'); return; }
    var dupe = getExactDupe(title);
    if (dupe && !confirm('Bài "' + dupe.title + '" đã có trong kho (' + genreLabel(dupe.genre) + '). Vẫn thêm?')) {
      return;
    }
    var ids = (state.songs[genre] || []).map(function (s) { return Number(s.id) || 0; });
    var nextId = ids.length ? Math.max.apply(null, ids) + 1 : 1;
    var safeName = /\.mp3$/i.test(filename) ? filename : filename + '.mp3';
    state.songs[genre].push({
      id: nextId,
      title: title,
      url: buildSongUrl(genre, safeName),
      type: genreLabel(genre),
      genre: genre
    });
    state.activeTab = genre;
    $$('#genreTabs .seg-btn').forEach(function (b) {
      b.classList.toggle('active', b.getAttribute('data-tab') === genre);
    });
    updateBadges();
    renderLibrary();
    showToast('Đã thêm "' + title + '" vào ' + genreLabel(genre) + '. Nhớ tải JSON và commit lên GitHub!', 'success');
    fileInput.value = '';
    fileNotice.textContent = 'Chưa chọn file nào';
    songTitle.value = '';
    songFilename.value = '';
    updateUrlPreview();
    updateDupeAlert();
  });

  function removeSong(genre, id) {
    var list = state.songs[genre] || [];
    var idx = -1;
    for (var i = 0; i < list.length; i++) {
      if (String(list[i].id) === String(id)) { idx = i; break; }
    }
    if (idx < 0) { showToast('Không tìm thấy bài để xoá.', 'error'); return; }
    if (!confirm('Xoá "' + list[idx].title + '" khỏi danh sách ' + genreLabel(genre) + '?')) { return; }
    list.splice(idx, 1);
    updateBadges();
    renderLibrary();
    if (titleSuggestions.classList.contains('open')) { renderTitleSuggestions(songTitle.value); }
    updateDupeAlert();
    showToast('Đã xoá khỏi danh sách – nhớ tải JSON để đồng bộ lên GitHub.', 'success');
  }
  window.removeSong = removeSong;

  function downloadJSON(filename, data) {
    var jsonStr = JSON.stringify(data, null, 2);
    var blob = new Blob([jsonStr], { type: 'application/json' });
    var url = URL.createObjectURL(blob);
    var a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    showToast('Đã xuất file ' + filename + '!', 'success');
  }

  function playlistOf(genre) {
    return (state.songs[genre] || []).map(function (s) {
      return { id: s.id, title: s.title, url: s.url };
    });
  }

  $('btnDownloadRemix').addEventListener('click', function () {
    downloadJSON('remix.json', playlistOf('remix'));
  });
  $('btnDownloadLofi').addEventListener('click', function () {
    downloadJSON('lofi.json', playlistOf('lofi'));
  });

  $('btnReloadRepo').addEventListener('click', function () {
    showToast('Đang tải lại remix.json & lofi.json…');
    loadAll(false);
  });

  /* ---------------- Import JSON ---------------- */
  function detectGenreFromFile(fileName, list) {
    var n = String(fileName || '').toLowerCase();
    if (n.indexOf('remix') >= 0) { return 'remix'; }
    if (n.indexOf('lofi') >= 0) { return 'lofi'; }
    for (var i = 0; i < list.length; i++) {
      var u = String(list[i].url || '').toLowerCase();
      if (u.indexOf('/songs/remix/') >= 0) { return 'remix'; }
      if (u.indexOf('/songs/lofi/') >= 0) { return 'lofi'; }
    }
    return null;
  }

  $('importJsonInput').addEventListener('change', function (e) {
    var files = Array.prototype.slice.call(e.target.files || []);
    if (!files.length) { return; }
    var mode = $('importMode').value;
    var forced = $('importGenre').value;

    var tasks = files.map(function (file) {
      return file.text().then(function (text) {
        var data = JSON.parse(text);
        if (!Array.isArray(data)) { throw new Error('File ' + file.name + ' không phải mảng JSON hợp lệ'); }
        var genre = forced !== 'auto' ? forced : (detectGenreFromFile(file.name, data) || 'lofi');
        return { genre: genre, list: data, name: file.name };
      });
    });

    Promise.all(tasks).then(function (results) {
      var summary = { added: 0, skipped: 0 };
      results.forEach(function (r) {
        if (mode === 'replace') { state.songs[r.genre] = []; }
        var target = state.songs[r.genre];
        r.list.forEach(function (item) {
          var title = String(item.title || '').trim();
          var url = normalizeSongUrl(item.url, r.genre);
          if (!title || !url) { return; }
          var dup = target.some(function (s) {
            return s.url === url || normalizeVi(s.title) === normalizeVi(title);
          });
          if (dup) { summary.skipped++; return; }
          var ids = target.map(function (s) { return Number(s.id) || 0; });
          target.push({
            id: ids.length ? Math.max.apply(null, ids) + 1 : 1,
            title: title,
            url: url,
            type: genreLabel(r.genre),
            genre: r.genre
          });
          summary.added++;
        });
      });
      updateBadges();
      renderLibrary();
      showToast('Import xong: thêm ' + summary.added + ' bài, bỏ qua ' + summary.skipped +
        ' bài trùng. Nhớ tải JSON để commit lên GitHub.', 'success');
    }).catch(function (err) {
      showToast('Import lỗi: ' + err.message, 'error');
    });

    e.target.value = '';
  });

  /* ---------------- Phiên nghe: khôi phục ---------------- */
  function restoreFromSession() {
    var data = engine.restoreSession();
    if (!data) { return false; }
    var genre = data.genre || state.activeTab;
    engine.setLibrary(state.songs[genre] || [], genre);
    engine.setQueue(data.queue, data.index, {});
    var song = engine.currentSong();
    if (!song) { return false; }
    engine.active = engine.deckA;
    engine.idle = engine.deckB;
    engine.loadInto(engine.deckA, song, Math.max(0, data.position || 0));
    engine.emit('track', song);
    engine.emit('time', { position: data.position || 0, duration: 0 });
    engine.saveSession(true);
    if (engine.settings.resumeAutoPlay) {
      showToast('Bấm vào trang hoặc nút Play để tiếp tục "' + song.title + '".');
      var once = function () {
        document.removeEventListener('pointerdown', once);
        document.removeEventListener('keydown', once);
        engine.play();
      };
      document.addEventListener('pointerdown', once, { once: true });
      document.addEventListener('keydown', once, { once: true });
    } else {
      showToast('Sẵn sàng tiếp tục: ' + song.title + ' tại ' + fmtTime(data.position || 0) + ' – bấm Play.', 'success');
    }
    return true;
  }

  /* ---------------- Khởi động ---------------- */
  function init() {
    initRepoConfig();
    engine.init();
    setPlayIcon(false);
    syncSettingsUI();
    renderAB(engine.ab);
    renderTimer(engine.timerInfo());
    renderQueue();
    renderUpNext();
    loadAll(true).then(function () {
      var restored = restoreFromSession();
      if (!restored) {
        engine.setLibrary(state.songs[state.activeTab], state.activeTab);
      }
      renderLibrary();
      updateQueueTag();
      if (!devicesSupported) {
        console.info('Trình duyệt không hỗ trợ theo dõi thiết bị âm thanh: tự phát khi kết nối tai nghe / tạm dừng khi rút tai nghe sẽ không hoạt động.');
      }
    });
  }

  window.addEventListener('beforeunload', function () { engine.saveSession(true); });
  document.addEventListener('visibilitychange', function () {
    if (document.visibilityState === 'hidden') { engine.saveSession(true); }
  });

  window.qhun22Engine = engine;
  init();
})();












