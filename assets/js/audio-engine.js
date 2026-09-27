/* =========================================================
   qhun22Music - Audio Engine (Web Audio API)
   Repeat Off/All/One + A-B · Shuffle & True Shuffle · Autoplay
   Queue (play now/next/add, reorder, save playlist) · Crossfade
   Gapless · Fade in-out · EQ 10 band + preset + custom · Bass/
   Treble · Stereo widening · Balance · Mono · Normalization ~
   Sleep timer · Resume phiên nghe · MediaSession (lock screen)
   ========================================================= */
(function (global) {
  'use strict';

  var SETTINGS_KEY = 'qhun22.settings.v1';
  var SESSION_KEY = 'qhun22.session.v1';
  var GAIN_KEY = 'qhun22.gain.v1';
  var EQ_FREQS = [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];

  var PRESETS = {
    flat:       [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    pop:        [-1, 0, 2, 4, 3, 0, -1, 0, 2, 3],
    rock:       [5, 4, 3, 1, -1, -1, 1, 3, 4, 4],
    jazz:       [3, 2, 1, 2, -1, -1, 0, 1, 2, 3],
    classic:    [4, 3, 2, 1, -1, -1, 0, 2, 3, 4],
    electronic: [5, 4, 1, 0, -2, 1, 1, 3, 4, 5],
    dance:      [6, 5, 2, 0, 0, -1, 2, 3, 4, 5],
    acoustic:   [3, 1, 0, 1, 1, 1, 2, 2, 3, 2],
    hiphop:     [5, 4, 1, 2, -1, -1, 1, 2, 3, 3],
    vocal:      [-2, -2, -1, 2, 4, 5, 4, 2, 0, -1],
    bass:       [8, 6, 4, 2, 0, 0, 0, 0, 0, 0],
    treble:     [0, 0, 0, 0, 0, 0, 2, 4, 6, 8]
  };

  var PRESET_LABELS = {
    flat: 'Flat', pop: 'Pop', rock: 'Rock', jazz: 'Jazz', classic: 'Classic',
    electronic: 'Electronic', dance: 'Dance', acoustic: 'Acoustic',
    hiphop: 'Hip-hop', vocal: 'Vocal Boost', bass: 'Bass Boost', treble: 'Treble Boost'
  };

  function zeros() { return [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; }

  function clamp(v, min, max) { return v < min ? min : (v > max ? max : v); }

  function defaultSettings() {
    return {
      volume: 1, muted: false,
      repeat: 'off', shuffle: false, smartShuffle: true, blendRadio: false,
      autoplayNext: true, autoShuffleOnPlay: false, prevRule: true,
      speed: 1, pitch: 0,
      eqEnabled: true, eqPreset: 'flat', eqGain: zeros(), customPresets: {},
      bass: 0, treble: 0, width: 0, balance: 0, mono: false, normalize: false,
      crossfade: 0, gapless: false, fade: 0.2,
      seekStep: 10, doubleTapStep: 10,
      autoplayPeripheral: false, pauseUnplug: true, shake: false,
      resume: true, resumeAutoPlay: false,
      timerEndOfTrack: false, timerFade: true
    };
  }

  function readStore(key, fallback) {
    try {
      var raw = global.localStorage.getItem(key);
      if (!raw) return fallback;
      return JSON.parse(raw);
    } catch (e) { return fallback; }
  }

  function writeStore(key, value) {
    try { global.localStorage.setItem(key, JSON.stringify(value)); } catch (e) { /* ignore */ }
  }

  // Đoán ca sĩ từ tiêu đề: "Tên bài - Ca sĩ" -> "Ca sĩ"
  function artistKey(title) {
    var t = String(title || '').trim();
    var parts = t.split(/\s+-\s+/);
    var guess = parts.length > 1 ? parts[parts.length - 1] : t;
    return guess.toLowerCase().replace(/\s+/g, ' ').slice(0, 32);
  }

  function shuffleArray(arr) {
    for (var i = arr.length - 1; i > 0; i--) {
      var j = Math.floor(Math.random() * (i + 1));
      var tmp = arr[i]; arr[i] = arr[j]; arr[j] = tmp;
    }
    return arr;
  }
  /* ---------------- Deck (mỗi bài phát trên 1 "bo" riêng để crossfade) ---------------- */
  function Deck(engine) {
    this.engine = engine;
    this.el = new Audio();
    this.el.crossOrigin = 'anonymous';
    this.el.preload = 'auto';
    this.el.setAttribute('playsinline', '');
    this.ready = false;
    this.url = '';
    this.trackGain = null;
    this.gain = null;
    this.srcNode = null;
    this.measure = { sum: 0, count: 0, done: true };
  }

  Deck.prototype.build = function () {
    var ctx = this.engine.ctx;
    this.srcNode = ctx.createMediaElementSource(this.el);
    this.trackGain = ctx.createGain();
    this.gain = ctx.createGain();
    this.trackGain.gain.value = 1;
    this.gain.gain.value = 1;
    this.srcNode.connect(this.trackGain);
    this.trackGain.connect(this.gain);
    this.gain.connect(this.engine.busIn);
    this.ready = true;
  };

  Deck.prototype.setGain = function (value, seconds) {
    if (!this.ready) { try { this.el.volume = clamp(value, 0, 1); } catch (e) {} return; }
    var now = this.engine.ctx.currentTime;
    var g = this.gain.gain;
    try { g.cancelScheduledValues(now); } catch (e) {}
    if (!seconds || seconds <= 0.01) {
      g.setValueAtTime(value, now);
    } else {
      g.setValueAtTime(g.value, now);
      g.linearRampToValueAtTime(value, now + seconds);
    }
  };

  Deck.prototype.load = function (url, position) {
    this.url = url;
    this.el.src = url;
    try { this.el.load(); } catch (e) {}
    if (position && position > 0) {
      var el = this.el;
      var onMeta = function () {
        try { el.currentTime = position; } catch (e) {}
        el.removeEventListener('loadedmetadata', onMeta);
      };
      el.addEventListener('loadedmetadata', onMeta);
    }
  };

  Deck.prototype.reset = function () {
    try { this.el.pause(); } catch (e) {}
    this.el.removeAttribute('src');
    try { this.el.load(); } catch (e) {}
    this.url = '';
    this.setGain(1, 0);
    if (this.ready) { this.trackGain.gain.value = 1; }
  };

  /* ---------------- Engine ---------------- */
  function PlayerEngine() {
    this.settings = Object.assign(defaultSettings(), readStore(SETTINGS_KEY, {}));
    this.settings.eqGain = (this.settings.eqGain || zeros()).slice(0, 10);
    while (this.settings.eqGain.length < 10) { this.settings.eqGain.push(0); }
    if (!this.settings.customPresets) { this.settings.customPresets = {}; }

    this.gains = readStore(GAIN_KEY, {});

    this.ctx = null;
    this.graphReady = false;
    this.deckA = new Deck(this);
    this.deckB = new Deck(this);
    this.active = null;
    this.idle = null;

    this.queue = [];         // [{id,title,url,type}]
    this.order = [];         // thứ tự phát (index trong queue)
    this.orderPos = -1;      // vị trí hiện tại trong order
    this.history = [];       // các index đã phát (để Previous khi xáo trộn)
    this.recent = [];        // artistKey của các bài vừa phát (smart shuffle)

    this.isPlaying = false;
    this.crossfading = false;
    this.ab = { a: null, b: null };
    this.sleep = { endsAt: null, minutes: 0, endOfTrack: false, pendingStop: false };
    this.fadeFactor = 1;
    this.listeners = {};
    this.monitorId = null;
    this.saveSessionAt = 0;
    this.loading = false;
  }

  PlayerEngine.prototype.on = function (event, fn) {
    if (!this.listeners[event]) this.listeners[event] = [];
    this.listeners[event].push(fn);
    return this;
  };

  PlayerEngine.prototype.emit = function (event, payload) {
    var list = this.listeners[event] || [];
    for (var i = 0; i < list.length; i++) {
      try { list[i](payload); } catch (e) { /* ignore listener error */ }
    }
  };
  /* ---------------- Đồ thị Web Audio ---------------- */
  PlayerEngine.prototype.ensureAudio = function () {
    if (this.ctx) {
      if (this.ctx.state === 'suspended') { try { this.ctx.resume(); } catch (e) {} }
      return true;
    }
    var Ctx = global.AudioContext || global.webkitAudioContext;
    if (!Ctx) {
      this.emit('warn', 'Trình duyệt không hỗ trợ Web Audio: EQ/DSP sẽ bị tắt, nhạc vẫn phát bình thường.');
      return false;
    }
    try {
      var ctx = new Ctx();
      this.ctx = ctx;
      this.busIn = ctx.createGain();
      this.eqNodes = [];
      for (var i = 0; i < EQ_FREQS.length; i++) {
        var band = ctx.createBiquadFilter();
        band.type = 'peaking';
        band.frequency.value = EQ_FREQS[i];
        band.Q.value = 1.1;
        band.gain.value = 0;
        this.eqNodes.push(band);
      }
      this.lowShelf = ctx.createBiquadFilter();
      this.lowShelf.type = 'lowshelf';
      this.lowShelf.frequency.value = 120;
      this.highShelf = ctx.createBiquadFilter();
      this.highShelf.type = 'highshelf';
      this.highShelf.frequency.value = 8000;

      this.splitter = ctx.createChannelSplitter(2);
      this.merger = ctx.createChannelMerger(2);
      this.gLL = ctx.createGain();   // L -> L
      this.gRL = ctx.createGain();   // R -> L (crossfeed)
      this.gRR = ctx.createGain();   // R -> R
      this.gLR = ctx.createGain();   // L -> R (crossfeed)
      this.masterGain = ctx.createGain();
      this.analyser = ctx.createAnalyser();
      this.analyser.fftSize = 2048;

      var chain = this.eqNodes.concat([this.lowShelf, this.highShelf]);
      var node = this.busIn;
      for (var k = 0; k < chain.length; k++) { node.connect(chain[k]); node = chain[k]; }
      node.connect(this.splitter);

      this.splitter.connect(this.gLL, 0);
      this.splitter.connect(this.gLR, 0);
      this.splitter.connect(this.gRL, 1);
      this.splitter.connect(this.gRR, 1);
      this.gLL.connect(this.merger, 0, 0);
      this.gRL.connect(this.merger, 0, 0);
      this.gLR.connect(this.merger, 0, 1);
      this.gRR.connect(this.merger, 0, 1);

      this.merger.connect(this.masterGain);
      this.masterGain.connect(this.analyser);
      this.analyser.connect(ctx.destination);

      this.deckA.build();
      this.deckB.build();
      this.graphReady = true;
      this.applyEq();
      this.applyTone();
      this.applyMatrix();
      this.applyVolume();
      this.applySpeedPitch();
      return true;
    } catch (e) {
      this.graphReady = false;
      this.emit('warn', 'Không tạo được đồ thị âm thanh (' + e.message + '). EQ/DSP tạm tắt.');
      return false;
    }
  };

  PlayerEngine.prototype.applyEq = function () {
    if (!this.graphReady) return;
    var on = this.settings.eqEnabled;
    for (var i = 0; i < this.eqNodes.length; i++) {
      this.eqNodes[i].gain.value = on ? this.settings.eqGain[i] : 0;
    }
    this.emit('eq', this.settings.eqGain);
  };

  PlayerEngine.prototype.applyTone = function () {
    if (!this.graphReady) return;
    this.lowShelf.gain.value = this.settings.bass;
    this.highShelf.gain.value = this.settings.treble;
    this.emit('tone', { bass: this.settings.bass, treble: this.settings.treble });
  };

  // Trộn kênh: widening (crossfeed âm) + mono (gộp L/R) + cân bằng L/R
  PlayerEngine.prototype.applyMatrix = function () {
    if (!this.graphReady) return;
    var s = this.settings;
    var width = clamp(s.width, 0, 100) / 100;
    var cross = s.mono ? 0.5 : -width;
    var direct = s.mono ? 0.5 : 1;
    var b = clamp(s.balance, -100, 100) / 100;
    var balL = b > 0 ? 1 - b : 1;
    var balR = b < 0 ? 1 + b : 1;
    this.gLL.gain.value = direct * balL;
    this.gRL.gain.value = cross * balL;
    this.gLR.gain.value = cross * balR;
    this.gRR.gain.value = direct * balR;
  };

  PlayerEngine.prototype.applyVolume = function () {
    var s = this.settings;
    var vol = s.muted ? 0 : clamp(s.volume, 0, 1) * this.fadeFactor;
    if (this.graphReady) {
      var now = this.ctx.currentTime;
      try { this.masterGain.gain.setValueAtTime(vol, now); } catch (e) { this.masterGain.gain.value = vol; }
    } else {
      var decks = [this.deckA, this.deckB];
      for (var i = 0; i < decks.length; i++) { try { decks[i].el.volume = vol; } catch (e) {} }
    }
  };

  PlayerEngine.prototype.applySpeedPitch = function () {
    var s = this.settings;
    var rate = clamp(s.speed * Math.pow(2, s.pitch / 12), 0.25, 4);
    var decks = [this.deckA, this.deckB];
    for (var i = 0; i < decks.length; i++) {
      var el = decks[i].el;
      try {
        el.playbackRate = rate;
        if ('preservesPitch' in el) { el.preservesPitch = (s.pitch === 0); }
        if ('mozPreservesPitch' in el) { el.mozPreservesPitch = (s.pitch === 0); }
        if ('webkitPreservesPitch' in el) { el.webkitPreservesPitch = (s.pitch === 0); }
      } catch (e) { /* ignore */ }
    }
    this.emit('rate', { rate: rate, speed: s.speed, pitch: s.pitch });
  };
  /* ---------------- Hàng đợi & thứ tự phát ---------------- */
  PlayerEngine.prototype.currentQueueIndex = function () {
    if (this.orderPos < 0 || this.orderPos >= this.order.length) return -1;
    return this.order[this.orderPos];
  };

  PlayerEngine.prototype.currentSong = function () {
    var i = this.currentQueueIndex();
    return i >= 0 ? this.queue[i] : null;
  };

  PlayerEngine.prototype.remapOrder = function (mapFn) {
    for (var i = 0; i < this.order.length; i++) { this.order[i] = mapFn(this.order[i]); }
  };

  // Xáo trộn thông minh: Fisher-Yates + tránh 2 bài cùng ca sĩ đứng cạnh + đẩy bài vừa nghe ra sau
  PlayerEngine.prototype.buildOrder = function (startIndex) {
    var self = this;
    var idx = [];
    for (var i = 0; i < this.queue.length; i++) { idx.push(i); }
    if (!this.settings.shuffle) {
      this.order = idx;
      this.orderPos = startIndex >= 0 && this.order.indexOf(startIndex) >= 0 ? this.order.indexOf(startIndex) : 0;
      return;
    }
    var rest = idx.filter(function (i) { return i !== startIndex; });
    shuffleArray(rest);
    if (this.settings.smartShuffle) {
      var recentSet = {};
      var r;
      for (r = 0; r < this.recent.length; r++) { recentSet[this.recent[r]] = true; }
      rest.sort(function (a, b) {
        var ra = recentSet[artistKey(self.queue[a].title)] ? 1 : 0;
        var rb = recentSet[artistKey(self.queue[b].title)] ? 1 : 0;
        return ra - rb;
      });
      var fixed = [];
      var pending = rest.slice();
      while (pending.length) {
        var played = fixed.length ? fixed[fixed.length - 1] : startIndex;
        var lastKey = (played !== undefined && played >= 0) ? artistKey(this.queue[played].title) : '';
        var picked = -1;
        for (var p = 0; p < pending.length; p++) {
          if (artistKey(this.queue[pending[p]].title) !== lastKey) { picked = p; break; }
        }
        if (picked < 0) picked = 0;
        fixed.push(pending.splice(picked, 1)[0]);
      }
      rest = fixed;
    }
    this.order = (startIndex >= 0 ? [startIndex] : []).concat(rest);
    this.orderPos = 0;
  };

  PlayerEngine.prototype.setQueue = function (list, startIndex, opts) {
    opts = opts || {};
    var self = this;
    this.queue = (list || []).map(function (s) {
      return { id: s.id, title: s.title, url: s.url, type: s.type || opts.type || '' };
    });
    this.recent = [];
    this.posHistory = [];
    var start = typeof startIndex === 'number' && startIndex >= 0 ? startIndex : 0;
    this.buildOrder(start);
    this.emit('queue');
    return this;
  };
  PlayerEngine.prototype.addToQueue = function (song, type) {
    this.queue.push({ id: song.id, title: song.title, url: song.url, type: type || song.type || '' });
    this.order.push(this.queue.length - 1);
    this.emit('queue', { added: song });
    return this.queue.length - 1;
  };

  PlayerEngine.prototype.playNextSong = function (song, type) {
    var curIdx = this.currentQueueIndex();
    var item = { id: song.id, title: song.title, url: song.url, type: type || song.type || '' };
    if (this.queue.length === 0 || curIdx < 0) {
      return this.addToQueue(song, type) && this.queue.length - 1;
    }
    var insertAt = curIdx + 1;
    this.queue.splice(insertAt, 0, item);
    this.remapOrder(function (i) { return i >= insertAt ? i + 1 : i; });
    this.order.splice(this.orderPos + 1, 0, insertAt);
    this.emit('queue', { added: song });
    return insertAt;
  };

  PlayerEngine.prototype.removeFromQueue = function (queueIndex) {
    if (queueIndex < 0 || queueIndex >= this.queue.length) return;
    var curIdx = this.currentQueueIndex();
    this.queue.splice(queueIndex, 1);
    this.remapOrder(function (i) { return i > queueIndex ? i - 1 : i; });
    var filtered = [];
    for (var i = 0; i < this.order.length; i++) {
      if (this.order[i] !== queueIndex) { filtered.push(this.order[i]); }
    }
    this.order = filtered;
    if (queueIndex === curIdx) {
      if (this.orderPos >= this.order.length) { this.orderPos = this.order.length - 1; }
    } else {
      var newCur = curIdx > queueIndex ? curIdx - 1 : curIdx;
      var back = this.order.indexOf(newCur);
      if (back >= 0) { this.orderPos = back; }
    }
    this.emit('queue');
  };

  PlayerEngine.prototype.reorderQueue = function (from, to) {
    if (from === to || from < 0 || to < 0 || from >= this.queue.length || to >= this.queue.length) return;
    var curIdx = this.currentQueueIndex();
    var item = this.queue.splice(from, 1)[0];
    this.queue.splice(to, 0, item);
    this.remapOrder(function (idx) {
      if (idx === from) return to;
      if (from < to) { return (idx > from && idx <= to) ? idx - 1 : idx; }
      return (idx >= to && idx < from) ? idx + 1 : idx;
    });
    var newCur = curIdx;
    if (curIdx === from) { newCur = to; }
    else if (from < to) { newCur = (curIdx > from && curIdx <= to) ? curIdx - 1 : curIdx; }
    else { newCur = (curIdx >= to && curIdx < from) ? curIdx + 1 : curIdx; }
    var pos = this.order.indexOf(newCur);
    if (pos >= 0) { this.orderPos = pos; }
    this.emit('queue');
  };

  PlayerEngine.prototype.clearQueue = function () {
    this.pause();
    this.queue = [];
    this.order = [];
    this.orderPos = -1;
    this.recent = [];
    this.posHistory = [];
    this.deckA.reset();
    this.deckB.reset();
    this.emit('queue');
    this.emit('track', null);
  };

  PlayerEngine.prototype.queuePlaylist = function () {
    return this.queue.map(function (s) { return { id: s.id, title: s.title, url: s.url }; });
  };

  // Radio: chèn thêm bài cùng thể loại (tương đồng) khi đã phát hết danh sách
  PlayerEngine.prototype.extendRadio = function (library) {
    var pool = (library || []).filter(function (s) { return s.url; });
    var self = this;
    var added = 0;
    shuffleArray(pool.slice()).forEach(function (s) {
      if (added >= 5) { return; }
      var dup = self.queue.some(function (q) { return q.url === s.url; });
      if (dup) { return; }
      self.queue.push({ id: s.id, title: s.title, url: s.url, type: s.type || '' });
      self.order.push(self.queue.length - 1);
      added++;
    });
    if (added) { this.emit('queue', { radio: added }); }
    return added;
  };
  /* ---------------- Phát nhạc ---------------- */
  PlayerEngine.prototype.pushRecent = function (song) {
    if (!song) return;
    if (!this.recent) this.recent = [];
    this.recent.push(artistKey(song.title));
    while (this.recent.length > 8) { this.recent.shift(); }
  };

  PlayerEngine.prototype.trackGainFor = function (url) {
    if (!this.settings.normalize) return 1;
    var v = this.gains[url];
    return typeof v === 'number' ? v : 1;
  };

  PlayerEngine.prototype.loadInto = function (deck, song, position) {
    deck.load(song.url, position);
    if (deck.ready) {
      deck.trackGain.gain.value = this.trackGainFor(song.url);
      deck.measure = {
        sum: 0,
        count: 0,
        done: !this.settings.normalize || typeof this.gains[song.url] === 'number'
      };
    }
  };

  PlayerEngine.prototype.startTrack = function (orderPos, opts) {
    opts = opts || {};
    if (orderPos < 0 || orderPos >= this.order.length) return false;
    var song = this.queue[this.order[orderPos]];
    if (!song) return false;

    this.ensureAudio();
    var self = this;
    var deck = this.idle || this.deckB;
    var old = this.active;
    var fade = Math.max(0, this.settings.fade);

    this.orderPos = orderPos;
    if (!this.posHistory) this.posHistory = [];
    this.posHistory.push(orderPos);
    if (this.posHistory.length > 80) this.posHistory.shift();
    this.pushRecent(song);

    this.loadInto(deck, song, opts.position || 0);
    this.applySpeedPitch();

    if (deck.ready) {
      deck.setGain(opts.crossSeconds > 0 ? 0 : (opts.gapless ? 1 : 0), 0);
    }
    var promise = deck.el.play();
    if (promise && promise.catch) {
      promise.catch(function (err) {
        self.emit('warn', 'Không phát được bài (kiểm tra mạng/CORS): ' + (err && err.message ? err.message : err));
      });
    }
    if (deck.ready) {
      if (opts.crossSeconds > 0) { deck.setGain(1, opts.crossSeconds); }
      else if (!opts.gapless) { deck.setGain(1, fade); }
    }

    this.active = deck;
    this.idle = (deck === this.deckA) ? this.deckB : this.deckA;

    if (old && old !== deck && old.url) {
      if (opts.crossSeconds > 0) {
        old.setGain(0, opts.crossSeconds);
        this.fadeOutEndsAt = (this.ctx ? this.ctx.currentTime : 0) + opts.crossSeconds;
        this.fadingOut = old;
      } else if (opts.gapless) {
        this.fadeOutEndsAt = 0;
        this.fadingOut = old;
      } else {
        var quick = Math.min(fade > 0 ? fade : 0.2, 0.3);
        old.setGain(0, quick);
        this.fadeOutEndsAt = (this.ctx ? this.ctx.currentTime : 0) + quick;
        this.fadingOut = old;
      }
    }

    this.isPlaying = true;
    this.emit('track', song);
    this.emit('state', { playing: true });
    this.startMonitor();
    this.updateMediaSession(song, true);
    this.saveSession(true);
    return true;
  };

  PlayerEngine.prototype.play = function (position) {
    if (!this.queue.length) {
      this.emit('warn', 'Hàng đợi đang trống – hãy chọn bài trong tab Thư viện.');
      return;
    }
    this.ensureAudio();
    var self = this;
    if (this.orderPos < 0 || !this.order.length) { this.buildOrder(0); }
    var song = this.currentSong();
    var deck = this.active;

    if (!deck || deck.url !== song.url) {
      this.startTrack(this.orderPos, { position: position || 0 });
      return;
    }
    if (typeof position === 'number' && position >= 0) {
      try { deck.el.currentTime = position; } catch (e) {}
    }
    if (deck.ready && this.settings.fade > 0) {
      deck.setGain(0, 0);
      deck.setGain(1, this.settings.fade);
    }
    var promise = deck.el.play();
    if (promise && promise.catch) {
      promise.catch(function (err) {
        self.emit('warn', 'Không phát được bài: ' + (err && err.message ? err.message : err));
      });
    }
    this.isPlaying = true;
    this.emit('state', { playing: true });
    this.startMonitor();
    this.updateMediaSession(song, true);
  };

  PlayerEngine.prototype.pause = function (immediate) {
    var self = this;
    var deck = this.active;
    var fade = immediate ? 0 : Math.max(0, this.settings.fade);
    this.isPlaying = false;
    if (deck && deck.ready && fade > 0.05) {
      deck.setGain(0, fade);
      global.setTimeout(function () {
        if (!self.isPlaying) {
          try { deck.el.pause(); } catch (e) {}
          deck.setGain(1, 0);
        }
      }, fade * 1000 + 40);
    } else if (deck) {
      try { deck.el.pause(); } catch (e) {}
      if (deck.ready) { deck.setGain(1, 0); }
    }
    this.emit('state', { playing: false });
    this.updateMediaSession(this.currentSong(), false);
    this.saveSession(true);
  };

  PlayerEngine.prototype.toggle = function () {
    if (this.isPlaying) { this.pause(); } else { this.play(); }
  };
  PlayerEngine.prototype.nextOrderPos = function (auto) {
    var s = this.settings;
    if (!this.order.length || this.orderPos < 0) return null;
    var next = this.orderPos + 1;
    if (next < this.order.length) return next;
    if (s.repeat === 'all') return 0;
    if (auto && s.autoplayNext) return 0;
    return null;
  };

  // auto = true khi bài tự hết (tôn trọng Repeat One / Autoplay / Sleep timer)
  PlayerEngine.prototype.next = function (auto) {
    var s = this.settings;
    if (!this.queue.length) return;

    if (auto && this.sleep && this.sleep.pendingStop) {
      this.sleep.pendingStop = false;
      this.pause();
      this.fadeFactor = 1;
      this.applyVolume();
      this.emit('timer', this.timerInfo());
      this.emit('warn', 'Hết bài – đã tắt nhạc theo hẹn giờ.');
      return;
    }
    if (auto && s.repeat === 'one') { this.seekTo(0); return; }
    if (auto && s.blendRadio && this.orderPos + 1 >= this.order.length && this.library) {
      this.extendRadio(this.library);
    }
    var np = this.nextOrderPos(auto);
    if (np === null) {
      this.emit('queueEnd');
      this.pause();
      return;
    }
    var cf = s.crossfade;
    var crossSeconds = 0;
    if (cf > 0) {
      var remain = this.currentRemaining();
      crossSeconds = auto ? Math.min(cf, remain || cf) : Math.min(cf, 2);
    }
    this.startTrack(np, {
      crossSeconds: crossSeconds,
      gapless: auto && s.gapless && cf <= 0
    });
  };

  PlayerEngine.prototype.prev = function () {
    var deck = this.active;
    if (deck && this.settings.prevRule && (deck.el.currentTime || 0) > 3) {
      this.seekTo(0);
      this.emit('warn', 'Đã tua về đầu bài hiện tại (nhấn Previous lần nữa để lùi bài).');
      return;
    }
    var hist = this.posHistory || [];
    var target = null;
    for (var i = hist.length - 2; i >= 0; i--) {
      if (hist[i] !== this.orderPos) { target = hist[i]; break; }
    }
    if (target === null) {
      if (this.orderPos > 0) { target = this.orderPos - 1; }
      else if (this.settings.repeat === 'all' || this.settings.autoplayNext) { target = this.order.length - 1; }
    }
    if (target === null || target < 0) { this.seekTo(0); return; }
    this.startTrack(target, {});
  };

  PlayerEngine.prototype.seekTo = function (seconds) {
    var deck = this.active;
    if (!deck || !deck.url) { this.emit('warn', 'Chưa có bài nào đang phát.'); return; }
    var dur = deck.el.duration;
    var max = (dur && isFinite(dur)) ? Math.max(0, dur - 0.2) : seconds;
    var t = clamp(seconds, 0, max);
    try { deck.el.currentTime = t; } catch (e) {}
    this.emit('time', { position: t, duration: (dur && isFinite(dur)) ? dur : 0, forced: true });
    this.saveSession(true);
  };

  PlayerEngine.prototype.skip = function (delta) {
    var deck = this.active;
    if (!deck || !deck.url) { this.emit('warn', 'Chưa có bài nào đang phát.'); return; }
    this.seekTo((deck.el.currentTime || 0) + delta);
  };

  PlayerEngine.prototype.currentRemaining = function () {
    var deck = this.active;
    if (!deck || !deck.el.duration || !isFinite(deck.el.duration)) return 0;
    return Math.max(0, deck.el.duration - (deck.el.currentTime || 0));
  };
  /* ---------------- Vòng lặp giám sát (100ms) ---------------- */
  PlayerEngine.prototype.startMonitor = function () {
    if (this.monitorId) return;
    var self = this;
    this.monitorId = global.setInterval(function () { self.tick(); }, 100);
  };

  PlayerEngine.prototype.stopMonitor = function () {
    if (this.monitorId) { global.clearInterval(this.monitorId); this.monitorId = null; }
  };

  PlayerEngine.prototype.measureRms = function () {
    if (!this.analyser) return 0;
    if (!this.rmsBuf || this.rmsBuf.length !== this.analyser.fftSize) {
      this.rmsBuf = new Float32Array(this.analyser.fftSize);
    }
    this.analyser.getFloatTimeDomainData(this.rmsBuf);
    var sum = 0;
    for (var i = 0; i < this.rmsBuf.length; i++) { sum += this.rmsBuf[i] * this.rmsBuf[i]; }
    return Math.sqrt(sum / this.rmsBuf.length);
  };

  PlayerEngine.prototype.tick = function () {
    var deck = this.active;
    var s = this.settings;
    this.timeTick = (this.timeTick || 0) + 1;

    if (deck && deck.url) {
      var dur = deck.el.duration;
      var pos = deck.el.currentTime || 0;
      if (dur && isFinite(dur) && dur > 0) {
        // Lặp đoạn A-B
        if (this.ab.a !== null && this.ab.b !== null && pos >= this.ab.b) {
          this.seekTo(this.ab.a);
        }
        var remain = dur - pos;
        var np = this.nextOrderPos(true);
        if (remain > 0.05 && np !== null && !this.fadingOut && this.isPlaying) {
          if (s.crossfade > 0 && remain <= s.crossfade) { this.next(true); }
          else if (s.gapless && remain <= 0.25) { this.next(true); }
        }
      }
      if (this.timeTick % 3 === 0) {
        this.emit('time', { position: pos, duration: (dur && isFinite(dur)) ? dur : 0 });
      }
      // Cân bằng độ lớn: đo RMS 8 giây đầu của mỗi bài
      if (s.normalize && deck.ready && !deck.measure.done && this.timeTick % 2 === 0 && this.analyser) {
        var rms = this.measureRms();
        if (rms > 0.0005) { deck.measure.sum += rms; deck.measure.count++; }
        if (deck.measure.count >= 40) {
          deck.measure.done = true;
          var avg = deck.measure.sum / deck.measure.count;
          if (avg > 0.004 && deck.url) {
            var g = clamp(0.12 / avg, 0.5, 2);
            this.gains[deck.url] = Math.round(g * 1000) / 1000;
            deck.trackGain.gain.value = g;
            this.saveGains();
          }
        }
      }
    }

    // Dọn deck đang fade-out
    if (this.fadingOut) {
      var now = this.ctx ? this.ctx.currentTime : 0;
      var finished = this.fadingOut.el.paused || this.fadingOut.el.ended ||
        (this.fadeOutEndsAt && now >= this.fadeOutEndsAt);
      if (finished) {
        try { this.fadingOut.el.pause(); } catch (e) {}
        this.fadingOut.reset();
        this.fadingOut = null;
      }
    }

    this.tickSleep();
    if (this.isPlaying && Date.now() - this.saveSessionAt > 5000) { this.saveSession(false); }
  };
  /* ---------------- Hẹn giờ tắt nhạc ---------------- */
  PlayerEngine.prototype.timerInfo = function () {
    var leftMs = this.sleep.endsAt ? Math.max(0, this.sleep.endsAt - Date.now()) : 0;
    return {
      active: !!(this.sleep.endsAt || this.sleep.pendingStop),
      leftMs: leftMs,
      leftText: this.sleep.endsAt ? this.formatClock(Math.round(leftMs / 1000)) : '',
      endOfTrack: !!this.sleep.pendingStop,
      minutes: this.sleep.minutes
    };
  };

  PlayerEngine.prototype.formatClock = function (seconds) {
    seconds = Math.max(0, Math.floor(seconds || 0));
    var h = Math.floor(seconds / 3600);
    var m = Math.floor((seconds % 3600) / 60);
    var s = seconds % 60;
    if (h > 0) { return h + ':' + (m < 10 ? '0' : '') + m + ':' + (s < 10 ? '0' : '') + s; }
    return m + ':' + (s < 10 ? '0' : '') + s;
  };

  PlayerEngine.prototype.startTimer = function (minutes) {
    minutes = clamp(Number(minutes) || 0, 1, 600);
    this.sleep.minutes = minutes;
    this.sleep.endsAt = Date.now() + minutes * 60000;
    this.sleep.endOfTrack = !!this.settings.timerEndOfTrack;
    this.sleep.pendingStop = false;
    this.emit('timer', this.timerInfo());
    this.startMonitor();
  };

  PlayerEngine.prototype.cancelTimer = function () {
    this.sleep.endsAt = null;
    this.sleep.pendingStop = false;
    this.sleep.minutes = 0;
    this.fadeFactor = 1;
    this.applyVolume();
    this.emit('timer', this.timerInfo());
  };

  PlayerEngine.prototype.tickSleep = function () {
    if (!this.sleep.endsAt) {
      if (this.fadeFactor !== 1) { this.fadeFactor = 1; this.applyVolume(); }
      return;
    }
    var left = this.sleep.endsAt - Date.now();
    if (left <= 0) {
      if (this.sleep.endOfTrack && this.isPlaying && this.currentRemaining() > 0.5) {
        this.sleep.pendingStop = true;
        this.sleep.endsAt = null;
        this.fadeFactor = 1;
        this.applyVolume();
        this.emit('timer', this.timerInfo());
        this.emit('warn', 'Hẹn giờ: sẽ tắt sau khi hết bài hiện tại.');
      } else {
        this.sleep.endsAt = null;
        this.sleep.pendingStop = false;
        this.fadeFactor = 1;
        this.applyVolume();
        this.pause();
        this.emit('timer', this.timerInfo());
        this.emit('warn', 'Đã tắt nhạc theo hẹn giờ.');
      }
      return;
    }
    if (this.settings.timerFade && left <= 60000) {
      this.fadeFactor = clamp(left / 60000, 0.02, 1);
      this.applyVolume();
      this.emit('timer', this.timerInfo());
    } else if (this.fadeFactor !== 1) {
      this.fadeFactor = 1;
      this.applyVolume();
    }
  };

  /* ---------------- MediaSession (màn hình khoá / tai nghe) ---------------- */
  PlayerEngine.prototype.setupMediaSession = function () {
    var ms = global.navigator && global.navigator.mediaSession;
    if (!ms) return;
    var self = this;
    var handlers = {
      play: function () { self.play(); },
      pause: function () { self.pause(); },
      previoustrack: function () { self.prev(); },
      nexttrack: function () { self.next(false); },
      stop: function () { self.pause(true); },
      seekbackward: function (d) { self.skip(-((d && d.seekOffset) || self.settings.seekStep)); },
      seekforward: function (d) { self.skip((d && d.seekOffset) || self.settings.seekStep); },
      seekto: function (d) { if (d && typeof d.seekTime === 'number') { self.seekTo(d.seekTime); } }
    };
    Object.keys(handlers).forEach(function (key) {
      try { ms.setActionHandler(key, handlers[key]); } catch (e) { /* không hỗ trợ */ }
    });
  };

  PlayerEngine.prototype.updateMediaSession = function (song, playing) {
    var ms = global.navigator && global.navigator.mediaSession;
    if (!ms) return;
    try {
      if (song) {
        var base = global.location ? global.location.href.replace(/[^/]*$/, '') : '';
        var Meta = global.MediaMetadata;
        if (Meta) {
          ms.metadata = new Meta({
            title: song.title || 'qhun22Music',
            artist: 'qhun22Music',
            album: song.type || 'qhun22Music',
            artwork: [{ src: base + 'var.jpg', sizes: '512x512', type: 'image/jpeg' }]
          });
        }
      }
      if (typeof playing === 'boolean') {
        ms.playbackState = playing ? 'playing' : 'paused';
      }
      var deck = this.active;
      if (deck && deck.el.duration && isFinite(deck.el.duration)) {
        ms.setPositionState({
          duration: deck.el.duration,
          position: Math.min(deck.el.currentTime || 0, deck.el.duration),
          playbackRate: deck.el.playbackRate || 1
        });
      }
    } catch (e) { /* ignore */ }
  };
  /* ---------------- Lưu / khôi phục phiên nghe ---------------- */
  PlayerEngine.prototype.saveSession = function (force) {
    var now = Date.now();
    if (!force && now - this.saveSessionAt < 3000) return;
    this.saveSessionAt = now;
    if (!this.settings.resume) return;
    var song = this.currentSong();
    if (!song) return;
    var deck = this.active;
    writeStore(SESSION_KEY, {
      queue: this.queuePlaylist().map(function (s, i) {
        return { id: s.id, title: s.title, url: s.url };
      }),
      index: this.currentQueueIndex(),
      position: deck ? (deck.el.currentTime || 0) : 0,
      genre: this.libraryGenre || ''
    });
  };

  PlayerEngine.prototype.restoreSession = function () {
    if (!this.settings.resume) return null;
    var data = readStore(SESSION_KEY, null);
    if (!data || !data.queue || !data.queue.length) return null;
    return data;
  };

  PlayerEngine.prototype.clearSession = function () {
    try { global.localStorage.removeItem(SESSION_KEY); } catch (e) {}
  };

  PlayerEngine.prototype.saveGains = function () {
    var keys = Object.keys(this.gains);
    if (keys.length > 400) {
      var trimmed = {};
      for (var i = keys.length - 400; i < keys.length; i++) { trimmed[keys[i]] = this.gains[keys[i]]; }
      this.gains = trimmed;
    }
    writeStore(GAIN_KEY, this.gains);
  };

  PlayerEngine.prototype.persistSettings = function () {
    writeStore(SETTINGS_KEY, this.settings);
  };

  PlayerEngine.prototype.setLibrary = function (list, genre) {
    this.library = list || [];
    this.libraryGenre = genre || '';
  };

  PlayerEngine.prototype.resetStorage = function () {
    try {
      global.localStorage.removeItem(SETTINGS_KEY);
      global.localStorage.removeItem(SESSION_KEY);
      global.localStorage.removeItem(GAIN_KEY);
    } catch (e) {}
    this.gains = {};
    this.settings = defaultSettings();
    this.applyEq();
    this.applyTone();
    this.applyMatrix();
    this.applyVolume();
    this.applySpeedPitch();
    this.emit('settings', this.settings);
  };

  /* ---------------- Các hàm setter (đồng bộ UI <-> engine) ---------------- */
  PlayerEngine.prototype.setVolume = function (v) {
    this.settings.volume = clamp(Number(v), 0, 1);
    if (this.settings.volume > 0) { this.settings.muted = false; }
    this.applyVolume();
    this.persistSettings();
    this.emit('settings', this.settings);
  };

  PlayerEngine.prototype.toggleMute = function () {
    this.settings.muted = !this.settings.muted;
    this.applyVolume();
    this.persistSettings();
    this.emit('settings', this.settings);
    return this.settings.muted;
  };

  PlayerEngine.prototype.setSpeed = function (v) {
    this.settings.speed = clamp(Number(v) || 1, 0.5, 2);
    this.applySpeedPitch();
    this.persistSettings();
    this.emit('settings', this.settings);
  };

  PlayerEngine.prototype.setPitch = function (semitones) {
    this.settings.pitch = clamp(Math.round(Number(semitones) || 0), -12, 12);
    this.applySpeedPitch();
    this.persistSettings();
    this.emit('settings', this.settings);
  };

  PlayerEngine.prototype.setRepeat = function (mode) {
    if (['off', 'all', 'one'].indexOf(mode) < 0) { mode = 'off'; }
    this.settings.repeat = mode;
    this.persistSettings();
    this.emit('repeat', mode);
  };

  PlayerEngine.prototype.cycleRepeat = function () {
    var modes = ['off', 'all', 'one'];
    var i = modes.indexOf(this.settings.repeat);
    this.setRepeat(modes[(i + 1) % modes.length]);
    return this.settings.repeat;
  };

  PlayerEngine.prototype.setShuffle = function (on) {
    this.settings.shuffle = !!on;
    this.persistSettings();
    var cur = this.currentQueueIndex();
    if (this.queue.length) { this.buildOrder(cur >= 0 ? cur : 0); }
    this.emit('shuffle', this.settings.shuffle);
    this.emit('queue');
  };

  PlayerEngine.prototype.reshuffle = function () {
    var cur = this.currentQueueIndex();
    this.buildOrder(cur >= 0 ? cur : 0);
    this.emit('queue');
  };
  PlayerEngine.prototype.updateSetting = function (key, value) {
    this.settings[key] = value;
    if (key === 'smartShuffle' && this.settings.shuffle && this.queue.length) { this.reshuffle(); }
    if (key === 'shuffle') { return this.setShuffle(value); }
    if (key === 'normalize') {
      var decks = [this.deckA, this.deckB];
      for (var i = 0; i < decks.length; i++) {
        if (decks[i].ready && decks[i].url) {
          decks[i].trackGain.gain.value = this.trackGainFor(decks[i].url);
          decks[i].measure = {
            sum: 0, count: 0,
            done: !this.settings.normalize || typeof this.gains[decks[i].url] === 'number'
          };
        }
      }
    }
    this.persistSettings();
    this.emit('settings', this.settings);
    return this.settings[key];
  };

  /* ---------------- EQ / DSP ---------------- */
  PlayerEngine.prototype.setEqBand = function (index, gain) {
    index = Math.round(Number(index));
    if (index < 0 || index > 9) return;
    this.settings.eqGain[index] = clamp(Number(gain) || 0, -12, 12);
    this.settings.eqPreset = 'custom';
    this.applyEq();
    this.persistSettings();
  };

  PlayerEngine.prototype.setEqEnabled = function (on) {
    this.settings.eqEnabled = !!on;
    this.applyEq();
    this.persistSettings();
    this.emit('settings', this.settings);
  };

  PlayerEngine.prototype.applyEqPreset = function (name) {
    if (!PRESETS[name]) return false;
    this.settings.eqGain = PRESETS[name].slice();
    this.settings.eqPreset = name;
    this.settings.eqEnabled = true;
    this.applyEq();
    this.persistSettings();
    this.emit('settings', this.settings);
    return true;
  };

  PlayerEngine.prototype.saveCustomPreset = function (name) {
    name = String(name || '').trim();
    if (!name) return false;
    this.settings.customPresets[name] = this.settings.eqGain.slice();
    this.settings.eqPreset = name;
    this.persistSettings();
    this.emit('presets', this.settings.customPresets);
    return true;
  };

  PlayerEngine.prototype.loadCustomPreset = function (name) {
    var p = this.settings.customPresets[name];
    if (!p) return false;
    this.settings.eqGain = p.slice();
    this.settings.eqPreset = name;
    this.settings.eqEnabled = true;
    this.applyEq();
    this.persistSettings();
    this.emit('settings', this.settings);
    return true;
  };

  PlayerEngine.prototype.deleteCustomPreset = function (name) {
    if (!this.settings.customPresets[name]) return false;
    delete this.settings.customPresets[name];
    this.persistSettings();
    this.emit('presets', this.settings.customPresets);
    return true;
  };

  PlayerEngine.prototype.setBass = function (v) {
    this.settings.bass = clamp(Number(v) || 0, -12, 12);
    this.applyTone();
    this.persistSettings();
    this.emit('settings', this.settings);
  };

  PlayerEngine.prototype.setTreble = function (v) {
    this.settings.treble = clamp(Number(v) || 0, -12, 12);
    this.applyTone();
    this.persistSettings();
    this.emit('settings', this.settings);
  };

  PlayerEngine.prototype.setWidth = function (v) {
    this.settings.width = clamp(Number(v) || 0, 0, 100);
    this.applyMatrix();
    this.persistSettings();
    this.emit('settings', this.settings);
  };

  PlayerEngine.prototype.setBalance = function (v) {
    this.settings.balance = clamp(Number(v) || 0, -100, 100);
    this.applyMatrix();
    this.persistSettings();
    this.emit('settings', this.settings);
  };

  PlayerEngine.prototype.setMono = function (on) {
    this.settings.mono = !!on;
    this.applyMatrix();
    this.persistSettings();
    this.emit('settings', this.settings);
  };

  PlayerEngine.prototype.setCrossfade = function (sec) {
    this.settings.crossfade = clamp(Number(sec) || 0, 0, 12);
    this.persistSettings();
    this.emit('settings', this.settings);
  };

  PlayerEngine.prototype.setGapless = function (on) {
    this.settings.gapless = !!on;
    this.persistSettings();
    this.emit('settings', this.settings);
  };

  PlayerEngine.prototype.setFade = function (sec) {
    this.settings.fade = clamp(Number(sec) || 0, 0, 1);
    this.persistSettings();
    this.emit('settings', this.settings);
  };
  /* ---------------- Lặp đoạn A-B ---------------- */
  PlayerEngine.prototype.cycleAB = function () {
    var deck = this.active;
    if (!deck || !deck.url) {
      this.emit('warn', 'Chưa có bài nào đang phát để đặt điểm A-B.');
      return this.ab;
    }
    var t = deck.el.currentTime || 0;
    if (this.ab.a === null) {
      this.ab.a = t;
      this.ab.b = null;
      this.emit('warn', 'Đã đặt điểm A = ' + this.formatClock(t) + ' · bấm A-B lần nữa để đặt điểm B.');
    } else if (this.ab.b === null) {
      if (t - this.ab.a < 1) {
        this.emit('warn', 'Điểm B phải sau điểm A ít nhất 1 giây.');
        return this.ab;
      }
      this.ab.b = t;
      this.emit('warn', 'Đang lặp đoạn ' + this.formatClock(this.ab.a) + ' → ' + this.formatClock(this.ab.b) + ' · bấm A-B lần nữa để tắt.');
    } else {
      this.ab.a = null;
      this.ab.b = null;
      this.emit('warn', 'Đã tắt lặp đoạn A-B.');
    }
    this.emit('ab', this.ab);
    return this.ab;
  };

  PlayerEngine.prototype.clearAB = function () {
    this.ab.a = null;
    this.ab.b = null;
    this.emit('ab', this.ab);
  };

  /* ---------------- Thiết bị âm thanh ngoài (best-effort) ---------------- */
  PlayerEngine.prototype.watchDevices = function (onChange) {
    var md = global.navigator && global.navigator.mediaDevices;
    if (!md || !md.addEventListener) return false;
    var self = this;
    var countOutputs = function (list) {
      return list.filter(function (d) { return d.kind === 'audiooutput'; }).length;
    };
    try {
      md.enumerateDevices().then(function (list) { self.outputCount = countOutputs(list); }).catch(function () {});
    } catch (e) { /* ignore */ }
    md.addEventListener('devicechange', function () {
      try {
        md.enumerateDevices().then(function (list) {
          var count = countOutputs(list);
          var prev = self.outputCount;
          self.outputCount = count;
          if (typeof prev !== 'number') return;
          if (count > prev) { onChange('connected'); }
          else if (count < prev) { onChange('disconnected'); }
        }).catch(function () {});
      } catch (e) { /* ignore */ }
    });
    return true;
  };

  /* ---------------- Khởi tạo ---------------- */
  PlayerEngine.prototype.init = function () {
    var self = this;
    var decks = [this.deckA, this.deckB];
    decks.forEach(function (deck) {
      deck.el.addEventListener('ended', function () {
        if (deck !== self.active) { return; }
        self.next(true);
      });
      deck.el.addEventListener('error', function () {
        if (deck.url) { self.emit('warn', 'Không tải được bài: ' + deck.url); }
      });
      deck.el.addEventListener('play', function () {
        if (deck === self.active) {
          self.isPlaying = true;
          self.emit('state', { playing: true });
        }
      });
      deck.el.addEventListener('pause', function () {
        if (deck === self.active && self.isPlaying && !self.fadingOut) {
          self.isPlaying = false;
          self.emit('state', { playing: false });
        }
      });
    });
    this.setupMediaSession();
    this.startMonitor();
    return this;
  };

  PlayerEngine.prototype.destroy = function () {
    this.stopMonitor();
    this.deckA.reset();
    this.deckB.reset();
    if (this.ctx && this.ctx.close) { try { this.ctx.close(); } catch (e) {} }
    this.ctx = null;
    this.graphReady = false;
  };

  global.PlayerEngine = PlayerEngine;
})(window);











