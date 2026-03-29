// ── Estado global ──────────────────────────────────────────────
let playlists = [];
let activeId  = null;
let ytPlayer  = null;
let ytReady   = false;
let isPlaying = false;
let bars      = [];
let waveTimer = null;
let progTimer = null;

// ── Referencias DOM ────────────────────────────────────────────
const vinyl    = document.getElementById('vinyl');
const tonearm  = document.getElementById('tonearm');
const playBtn  = document.getElementById('playBtn');
const pauseBtn = document.getElementById('pauseBtn');
const stopBtn  = document.getElementById('stopBtn');
const prevBtn  = document.getElementById('prevBtn');
const nextBtn  = document.getElementById('nextBtn');
const progFill = document.getElementById('progFill');
const tCur     = document.getElementById('tCur');
const tTot     = document.getElementById('tTot');
const wfEl     = document.getElementById('wf');
const volSl    = document.getElementById('volSl');
const volVal   = document.getElementById('volVal');
const d1       = document.getElementById('d1');
const d2       = document.getElementById('d2');
const d3       = document.getElementById('d3');
const tiName   = document.getElementById('tiName');
const tiSub    = document.getElementById('tiSub');
const sysmsg   = document.getElementById('sysmsg');
const plList   = document.getElementById('plList');
const counter  = document.getElementById('counter');

// ── Tema claro/oscuro ──────────────────────────────────────────
function loadTheme() {
  const saved = localStorage.getItem('neovox_theme');
  if (saved === 'light') document.body.classList.add('light');
}

document.getElementById('themeBtn').addEventListener('click', () => {
  document.body.classList.toggle('light');
  const isLight = document.body.classList.contains('light');
  localStorage.setItem('neovox_theme', isLight ? 'light' : 'dark');
});

loadTheme();

// ── Utilidades ─────────────────────────────────────────────────
function fmt(s) {
  if (!s || isNaN(s)) return '0:00';
  s = Math.floor(s);
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
}

function setMsg(t) {
  sysmsg.textContent = t;
}

function extractId(url) {
  const m = url.match(/[?&]list=([a-zA-Z0-9_-]+)/);
  return m ? m[1] : null;
}

// ── API (reemplaza localStorage) ───────────────────────────────
async function loadFromAPI() {
  try {
    const res = await fetch('/api/playlists');
    if (!res.ok) throw new Error(res.statusText);
    playlists = await res.json();
  } catch (e) {
    console.error('NEOVOX: Error cargando playlists:', e);
    playlists = [];
  }
}

async function savePlaylistAPI(name, ytId) {
  const res = await fetch('/api/playlists', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name, ytId })
  });
  if (res.status === 409) {
    setMsg('LIMITE 20 PLAYLISTS ALCANZADO');
    return null;
  }
  if (!res.ok) throw new Error(res.statusText);
  return res.json();
}

async function removePlaylistAPI(id) {
  const res = await fetch(`/api/playlists/${id}`, { method: 'DELETE' });
  if (!res.ok && res.status !== 404) throw new Error(res.statusText);
}

// ── Render lista playlists ─────────────────────────────────────
function renderList() {
  counter.textContent = `${playlists.length} LISTA${playlists.length !== 1 ? 'S' : ''} · MAX 20`;

  if (!playlists.length) {
    plList.innerHTML = `
      <div style="text-align:center;padding:40px 20px;font-family:'Share Tech Mono',monospace;font-size:9px;color:var(--pl-id-color);letter-spacing:2px;line-height:2.2">
        · VAULT VACÍA ·<br>AÑADE TU PRIMERA PLAYLIST
      </div>`;
    return;
  }

  plList.innerHTML = '';
  playlists.forEach(pl => {
    const isActive = pl.id === activeId;
    const el = document.createElement('div');
    el.className = 'pl-item' + (isActive ? ' active' : '');
    el.innerHTML = `
      <div style="width:36px;height:36px;border-radius:8px;background:var(--pl-icon-bg);border:1px solid var(--pl-icon-border);display:flex;align-items:center;justify-content:center;flex-shrink:0">
        <div style="width:22px;height:22px;border-radius:50%;background:var(--pl-icon-vinyl);border:1px solid var(--pl-icon-vinyl-border);display:flex;align-items:center;justify-content:center">
          <div style="width:6px;height:6px;border-radius:50%;background:var(--pl-icon-dot)"></div>
        </div>
      </div>
      <div style="flex:1;min-width:0">
        <div style="font-size:9px;letter-spacing:1px;color:${isActive ? 'var(--pl-name-active)' : 'var(--pl-name)'};font-weight:700;margin-bottom:2px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${pl.name}</div>
        <div style="font-family:'Share Tech Mono',monospace;font-size:7px;color:var(--pl-id-color);letter-spacing:1px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${pl.ytId}</div>
        <div style="margin-top:3px">
          <span style="font-size:6px;letter-spacing:1px;color:var(--pl-badge-color);background:var(--pl-badge-bg);border:1px solid var(--pl-badge-border);border-radius:3px;padding:1px 5px">YT PLAYLIST</span>
        </div>
      </div>
      <div style="display:flex;gap:5px;flex-shrink:0">
        <button class="play-pl-btn" data-id="${pl.id}"
          style="width:28px;height:28px;border-radius:6px;border:1px solid var(--pl-btn-border);background:var(--pl-btn-bg);cursor:pointer;display:flex;align-items:center;justify-content:center;transition:all 0.15s">
          <svg width="10" height="10" viewBox="0 0 10 10" style="fill:var(--pl-btn-fill)"><polygon points="3,2 8,5 3,8"/></svg>
        </button>
        <button class="del-btn" data-id="${pl.id}"
          style="width:28px;height:28px;border-radius:6px;border:1px solid var(--pl-btn-border);background:var(--pl-btn-bg);cursor:pointer;display:flex;align-items:center;justify-content:center;transition:all 0.15s">
          <svg width="10" height="10" viewBox="0 0 10 10"><line x1="2" y1="2" x2="8" y2="8" stroke="var(--del-stroke)" stroke-width="1.5" stroke-linecap="round"/><line x1="8" y1="2" x2="2" y2="8" stroke="var(--del-stroke)" stroke-width="1.5" stroke-linecap="round"/></svg>
        </button>
      </div>`;

    el.querySelector('.play-pl-btn').addEventListener('click', e => { e.stopPropagation(); loadPlaylist(pl.id); });
    el.querySelector('.del-btn').addEventListener('click', e => { e.stopPropagation(); deletePlaylist(pl.id); });
    el.addEventListener('click', () => loadPlaylist(pl.id));
    plList.appendChild(el);
  });
}

// ── Cargar playlist en el player ───────────────────────────────
function loadPlaylist(id) {
  const pl = playlists.find(p => p.id === id);
  if (!pl) return;
  activeId = id;
  renderList();

  if (!ytReady) {
    setMsg('API NO LISTA · ESPERA...');
    return;
  }

  try {
    isPlaying = false;
    vinyl.classList.remove('animate-spin-vinyl');
    setArmRest();
    animWf(false);
    updateDots('stopped');
    playBtn.classList.remove('active');
    pauseBtn.classList.remove('active');
    progFill.style.width = '0%';
    tCur.textContent = '0:00';
    tTot.textContent = '0:00';
    stopProg();

    tiName.textContent = pl.name.toUpperCase();
    tiSub.textContent  = 'YT: ' + pl.ytId.substring(0, 18) + '...';
    setMsg('CARGANDO PLAYLIST...');

    ytPlayer.loadPlaylist({ listType: 'playlist', list: pl.ytId, index: 0, startSeconds: 0 });
    ytPlayer.setVolume(parseInt(volSl.value));
  } catch (e) {
    setMsg('ERROR: ' + e.message);
    console.error('NEOVOX loadPlaylist error:', e);
  }
}

// ── Eliminar playlist ──────────────────────────────────────────
async function deletePlaylist(id) {
  try {
    await removePlaylistAPI(id);
    playlists = playlists.filter(p => p.id !== id);
    if (activeId === id) {
      activeId = null;
      doStop();
      tiName.textContent = '· NEOVOX YT-V ·';
      tiSub.textContent  = 'SELECCIONA UNA PLAYLIST';
      setMsg('SELECCIONA UNA PLAYLIST DEL PANEL');
    }
    renderList();
  } catch (e) {
    setMsg('ERROR AL ELIMINAR');
    console.error('NEOVOX delete error:', e);
  }
}

// ── Añadir playlist ────────────────────────────────────────────
document.getElementById('addBtn').addEventListener('click', async () => {
  const name = document.getElementById('plName').value.trim();
  const url  = document.getElementById('plUrl').value.trim();
  if (!name) { setMsg('INTRODUCE UN NOMBRE'); return; }
  const ytId = extractId(url);
  if (!ytId) { setMsg('URL INVÁLIDA · USA ?list=...'); return; }

  try {
    const created = await savePlaylistAPI(name, ytId);
    if (!created) return;
    playlists.unshift(created);
    renderList();
    document.getElementById('plName').value = '';
    document.getElementById('plUrl').value  = '';
    setMsg('✓ PLAYLIST GUARDADA EN VAULT');
  } catch (e) {
    setMsg('ERROR AL GUARDAR');
    console.error('NEOVOX save error:', e);
  }
});

// ── Waveform ───────────────────────────────────────────────────
function buildWf() {
  wfEl.innerHTML = '';
  bars = [];
  for (let i = 0; i < 52; i++) {
    const b = document.createElement('div');
    b.className = 'wf-bar';
    const h = 4 + Math.random() * 10;
    b.style.height = h + 'px';
    b.dataset.base = h;
    wfEl.appendChild(b);
    bars.push(b);
  }
}

function animWf(on) {
  if (waveTimer) { clearInterval(waveTimer); waveTimer = null; }
  bars.forEach(b => {
    b.classList.toggle('active', on);
    b.style.animationDelay = (Math.random() * 0.6) + 's';
    b.style.height = b.dataset.base + 'px';
    if (on) b.style.animation = `wave ${0.5 + Math.random() * 0.6}s ease-in-out infinite alternate`;
    else b.style.animation = '';
  });
  if (on) {
    waveTimer = setInterval(() => {
      bars.forEach((b, i) => {
        const base = 6 + Math.sin(Date.now() / 300 + i * 0.4) * 10 + Math.random() * 8;
        const eq = getEqMultiplier(i, bars.length);
        const h = base * eq;
        b.style.height = Math.max(3, Math.min(h, 28)) + 'px';
      });
    }, 80);
  }
}

// ── Brazo y estado visual ──────────────────────────────────────
const ARM_REST  =   0;
const ARM_START =  25;
const ARM_END   =  55;

function setArmRest() {
  tonearm.style.transform = `rotate(${ARM_REST}deg)`;
}

function setArmProgress(pct) {
  if (isDragging) return;
  const clamped = Math.max(0, Math.min(100, pct));
  const angle = ARM_START + (ARM_END - ARM_START) * (clamped / 100);
  tonearm.style.transform = `rotate(${angle}deg)`;
}

// ── Drag de la aguja ───────────────────────────────────────────
let isDragging = false;
let dragAngle  = 0;

function getPivotCenter() {
  const pivotEl = tonearm.querySelector('.tonearm-pivot');
  const pRect = pivotEl.getBoundingClientRect();
  return {
    x: pRect.left + pRect.width / 2,
    y: pRect.top + pRect.height / 2
  };
}

function angleFromMouse(e) {
  const clientX = e.touches ? e.touches[0].clientX : e.clientX;
  const clientY = e.touches ? e.touches[0].clientY : e.clientY;
  const pivot = getPivotCenter();
  const dx = clientX - pivot.x;
  const dy = clientY - pivot.y;
  let angle = Math.atan2(-dx, dy) * (180 / Math.PI);
  return Math.max(ARM_REST, Math.min(ARM_END, angle));
}

function onDragStart(e) {
  e.preventDefault();
  isDragging = true;
  tonearm.classList.add('dragging');
  document.addEventListener('mousemove', onDragMove);
  document.addEventListener('mouseup', onDragEnd);
  document.addEventListener('touchmove', onDragMove, { passive: false });
  document.addEventListener('touchend', onDragEnd);
}

function onDragMove(e) {
  if (!isDragging) return;
  e.preventDefault();
  dragAngle = angleFromMouse(e);
  tonearm.style.transform = `rotate(${dragAngle}deg)`;
}

function onDragEnd() {
  if (!isDragging) return;
  isDragging = false;
  tonearm.classList.remove('dragging');
  document.removeEventListener('mousemove', onDragMove);
  document.removeEventListener('mouseup', onDragEnd);
  document.removeEventListener('touchmove', onDragMove);
  document.removeEventListener('touchend', onDragEnd);

  // Soltó sobre el disco: reproducir desde esa posición
  if (dragAngle >= ARM_START && activeId && ytReady) {
    const pct = (dragAngle - ARM_START) / (ARM_END - ARM_START) * 100;
    try {
      const duration = ytPlayer.getDuration() || 0;
      if (duration > 0) {
        ytPlayer.seekTo((pct / 100) * duration, true);
      }
      ytPlayer.playVideo();
    } catch {}
  } else {
    // Soltó fuera del disco
    if (isPlaying) {
      try {
        const c = ytPlayer.getCurrentTime() || 0;
        const d = ytPlayer.getDuration() || 0;
        setArmProgress(d > 0 ? (c / d) * 100 : 0);
      } catch { setArmProgress(0); }
    } else {
      setArmRest();
    }
  }
}

tonearm.addEventListener('mousedown', onDragStart);
tonearm.addEventListener('touchstart', onDragStart, { passive: false });

function updateDots(state) {
  const on = 'var(--dot-on)';
  const off = 'var(--dot-off)';
  d1.style.background = state === 'stopped' ? on : off;
  d2.style.background = state === 'paused'  ? on : off;
  d3.style.background = state === 'playing' ? on : off;
  d1.style.boxShadow  = state === 'stopped' ? '0 0 7px var(--dot-on)' : 'none';
  d2.style.boxShadow  = state === 'paused'  ? '0 0 7px var(--dot-on)' : 'none';
  d3.style.boxShadow  = state === 'playing' ? '0 0 7px var(--dot-on)' : 'none';
}

// ── Progreso ───────────────────────────────────────────────────
function startProg() {
  if (progTimer) clearInterval(progTimer);
  progTimer = setInterval(() => {
    if (!ytPlayer || !ytReady) return;
    try {
      const c = ytPlayer.getCurrentTime() || 0;
      const d = ytPlayer.getDuration()    || 0;
      const pct = d > 0 ? (c / d) * 100 : 0;
      tCur.textContent     = fmt(c);
      tTot.textContent     = fmt(d);
      progFill.style.width = pct + '%';
      if (isPlaying) setArmProgress(pct);
    } catch {}
  }, 500);
}

function stopProg() {
  if (progTimer) { clearInterval(progTimer); progTimer = null; }
}

// ── MediaSession API (segundo plano) ───────────────────────────
function updateMediaSession(title, artist) {
  if (!('mediaSession' in navigator)) return;
  const artwork = currentVideoId ? [
    { src: `https://img.youtube.com/vi/${currentVideoId}/default.jpg`, sizes: '120x90', type: 'image/jpeg' },
    { src: `https://img.youtube.com/vi/${currentVideoId}/hqdefault.jpg`, sizes: '480x360', type: 'image/jpeg' },
    { src: `https://img.youtube.com/vi/${currentVideoId}/maxresdefault.jpg`, sizes: '1280x720', type: 'image/jpeg' }
  ] : [];
  navigator.mediaSession.metadata = new MediaMetadata({
    title: title || 'NEOVOX YT-V',
    artist: artist || 'YouTube Playlist',
    album: 'NEOVOX',
    artwork
  });
  navigator.mediaSession.setActionHandler('play', () => {
    if (ytReady && activeId) ytPlayer.playVideo();
  });
  navigator.mediaSession.setActionHandler('pause', () => {
    if (ytReady && isPlaying) ytPlayer.pauseVideo();
  });
  navigator.mediaSession.setActionHandler('previoustrack', () => {
    if (ytReady && activeId) try { ytPlayer.previousVideo(); } catch {}
  });
  navigator.mediaSession.setActionHandler('nexttrack', () => {
    if (ytReady && activeId) try { ytPlayer.nextVideo(); } catch {}
  });
  navigator.mediaSession.setActionHandler('stop', () => {
    if (ytReady) { try { ytPlayer.stopVideo(); } catch {} doStop(); }
  });
}

// ── Carátula del vinilo ─────────────────────────────────────────
const labelCover = document.getElementById('labelCover');
const labelText1 = document.getElementById('labelText1');
const labelText2 = document.getElementById('labelText2');
let currentVideoId = null;

function updateCover(videoId) {
  if (!videoId || videoId === currentVideoId) return;
  currentVideoId = videoId;
  // YouTube thumbnail: maxresdefault > hqdefault > 0
  const thumbUrl = `https://img.youtube.com/vi/${videoId}/hqdefault.jpg`;
  // Precargar imagen para transición suave
  const img = new Image();
  img.onload = () => {
    labelCover.style.backgroundImage = `url(${thumbUrl})`;
    labelCover.classList.add('visible');
    labelText1.style.fontSize = 'clamp(3px,1vw,5px)';
    labelText2.style.display = 'none';
  };
  img.onerror = () => {
    // Fallback: intentar con 0.jpg
    labelCover.style.backgroundImage = `url(https://img.youtube.com/vi/${videoId}/0.jpg)`;
    labelCover.classList.add('visible');
  };
  img.src = thumbUrl;
}

function clearCover() {
  labelCover.classList.remove('visible');
  currentVideoId = null;
  labelText1.textContent = 'CYBER';
  labelText1.style.fontSize = '';
  labelText2.style.display = '';
  labelText2.textContent = '33\u2153';
}

// ── Acciones play / pause / stop ───────────────────────────────
function doPlay() {
  isPlaying = true;
  vinyl.classList.add('animate-spin-vinyl');
  try {
    const c = ytPlayer.getCurrentTime() || 0;
    const d = ytPlayer.getDuration() || 0;
    setArmProgress(d > 0 ? (c / d) * 100 : 0);
  } catch { setArmProgress(0); }
  animWf(true);
  updateDots('playing');
  playBtn.classList.add('active');
  pauseBtn.classList.remove('active');
  document.getElementById('playIco').innerHTML = '<polygon points="6,3 15,9 6,15" style="fill:var(--btn-hover-fill)"/>';
  startProg();
  setMsg('▶ REPRODUCIENDO');

  let trackTitle = '';
  try {
    const data = ytPlayer.getVideoData();
    if (data?.title) {
      trackTitle = data.title;
      tiName.textContent = trackTitle.toUpperCase();
      const idx = ytPlayer.getPlaylistIndex?.() ?? 0;
      tiSub.textContent = 'TRACK ' + String(idx + 1).padStart(2, '0');
      // Carátula: texto corto en la etiqueta
      labelText1.textContent = trackTitle.substring(0, 14).toUpperCase();
    }
    // Thumbnail del video como carátula del vinilo
    if (data?.video_id) {
      updateCover(data.video_id);
    }
  } catch {}

  // Actualizar controles del sistema (segundo plano)
  if ('mediaSession' in navigator) {
    navigator.mediaSession.playbackState = 'playing';
  }
  updateMediaSession(trackTitle || 'NEOVOX YT-V');
}

function doPause() {
  isPlaying = false;
  vinyl.classList.remove('animate-spin-vinyl');
  animWf(false);
  updateDots('paused');
  playBtn.classList.remove('active');
  pauseBtn.classList.add('active');
  document.getElementById('playIco').innerHTML = '<polygon points="6,3 15,9 6,15"/>';
  stopProg();
  setMsg('❚❚ PAUSA');

  if ('mediaSession' in navigator) {
    navigator.mediaSession.playbackState = 'paused';
  }
}

function doStop() {
  isPlaying = false;
  vinyl.classList.remove('animate-spin-vinyl');
  setArmRest();
  clearCover();
  animWf(false);
  updateDots('stopped');
  playBtn.classList.remove('active');
  pauseBtn.classList.remove('active');
  document.getElementById('playIco').innerHTML = '<polygon points="6,3 15,9 6,15"/>';
  progFill.style.width = '0%';
  tCur.textContent = '0:00';
  tTot.textContent = '0:00';
  stopProg();
  setMsg('■ DETENIDO');

  if ('mediaSession' in navigator) {
    navigator.mediaSession.playbackState = 'none';
  }
}

// ── YouTube IFrame API ─────────────────────────────────────────
window.onYouTubeIframeAPIReady = function () {
  ytPlayer = new YT.Player('yt-player', {
    height: '1',
    width: '1',
    playerVars: {
      autoplay: 0,
      controls: 0,
      modestbranding: 1,
      origin: location.origin
    },
    events: {
      onReady: () => {
        ytReady = true;
        setMsg('SISTEMA LISTO · SELECCIONA UNA PLAYLIST');
        console.log('NEOVOX: YouTube Player listo');
      },
      onStateChange: e => {
        console.log('NEOVOX: YT state =', e.data);
        if (e.data === YT.PlayerState.PLAYING)      doPlay();
        else if (e.data === YT.PlayerState.PAUSED)   doPause();
        else if (e.data === YT.PlayerState.ENDED)    { try { ytPlayer.nextVideo(); } catch {} }
        else if (e.data === YT.PlayerState.BUFFERING) setMsg('BUFFERING...');
        else if (e.data === YT.PlayerState.CUED)      setMsg('LISTO · PULSE PLAY');
      },
      onError: e => {
        console.error('NEOVOX: YT error =', e.data);
        setMsg('ERROR ' + e.data + ' · SALTANDO TRACK...');
        setTimeout(() => { try { ytPlayer.nextVideo(); } catch {} }, 1500);
      }
    }
  });
};

// ── Ecualizador ────────────────────────────────────────────────
const eqSliders = document.querySelectorAll('.eq-slider');
const eqPresetBtns = document.querySelectorAll('.eq-preset-btn');
let eqValues = [0, 0, 0, 0, 0, 0, 0, 0]; // 8 bandas

const EQ_PRESETS = {
  flat:   [0, 0, 0, 0, 0, 0, 0, 0],
  bass:   [10, 8, 5, 1, 0, 0, -1, -2],
  vocal:  [-2, -1, 2, 6, 6, 3, 0, -2],
  treble: [-3, -2, 0, 1, 3, 6, 9, 10]
};

function applyEqPreset(name) {
  const vals = EQ_PRESETS[name];
  if (!vals) return;
  eqValues = [...vals];
  eqSliders.forEach((sl, i) => { sl.value = vals[i]; });
  eqPresetBtns.forEach(b => b.classList.toggle('active', b.dataset.preset === name));
  setMsg(`EQ: ${name.toUpperCase()}`);
}

eqPresetBtns.forEach(btn => {
  btn.addEventListener('click', () => applyEqPreset(btn.dataset.preset));
});

eqSliders.forEach((sl, i) => {
  sl.addEventListener('input', () => {
    eqValues[i] = parseInt(sl.value);
    // Quitar preset activo al mover manualmente
    eqPresetBtns.forEach(b => b.classList.remove('active'));
  });
});

// Los valores del EQ se usan en la animación del waveform
function getEqMultiplier(barIndex, totalBars) {
  const bandIndex = Math.floor((barIndex / totalBars) * eqValues.length);
  const clamped = Math.min(bandIndex, eqValues.length - 1);
  return 1 + (eqValues[clamped] / 12) * 0.8; // rango 0.2 - 1.8
}

// ── Velocidad de reproducción ───────────────────────────────────
let currentSpeed = 1;
const speedBtns = document.querySelectorAll('.speed-btn');

speedBtns.forEach(btn => {
  btn.addEventListener('click', () => {
    const speed = parseFloat(btn.dataset.speed);
    currentSpeed = speed;
    speedBtns.forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    if (ytReady && ytPlayer) {
      try { ytPlayer.setPlaybackRate(speed); } catch {}
    }
    setMsg(`VELOCIDAD: ${speed}x`);
  });
});

// ── Listeners controles ────────────────────────────────────────
playBtn.addEventListener('click', () => {
  if (!ytReady) { setMsg('ESPERANDO API DE YOUTUBE...'); return; }
  if (!activeId) { setMsg('SELECCIONA UNA PLAYLIST PRIMERO'); return; }
  if (isPlaying) {
    ytPlayer.pauseVideo();
  } else {
    ytPlayer.playVideo();
  }
});

pauseBtn.addEventListener('click', () => {
  if (ytReady && isPlaying) ytPlayer.pauseVideo();
});

stopBtn.addEventListener('click', () => {
  if (!ytReady) return;
  try { ytPlayer.stopVideo(); } catch {}
  doStop();
});

prevBtn.addEventListener('click', () => {
  if (ytReady && activeId) try { ytPlayer.previousVideo(); } catch {}
});

nextBtn.addEventListener('click', () => {
  if (ytReady && activeId) try { ytPlayer.nextVideo(); } catch {}
});

document.getElementById('progBg').addEventListener('click', e => {
  if (!ytReady || !isPlaying) return;
  const r = e.currentTarget.getBoundingClientRect();
  const ratio = (e.clientX - r.left) / r.width;
  try { ytPlayer.seekTo(ratio * (ytPlayer.getDuration() || 0), true); } catch {}
});

volSl.addEventListener('input', () => {
  const v = volSl.value;
  volVal.textContent = v;
  volSl.style.background = `linear-gradient(to right, var(--vol-fill) ${v}%, var(--vol-track) ${v}%)`;
  if (ytReady && ytPlayer) try { ytPlayer.setVolume(parseInt(v)); } catch {}
});

// ── Init ───────────────────────────────────────────────────────
(async () => {
  await loadFromAPI();
  buildWf();
  setArmRest();
  updateDots('stopped');
  renderList();
})();
