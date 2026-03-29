// ── Auth: cuenta anónima estilo Mullvad ────────────────────────
let currentAccount = localStorage.getItem('neovox_account');

const authScreen   = document.getElementById('authScreen');
const authCreate   = document.getElementById('authCreate');
const authShow     = document.getElementById('authShow');
const authLogin    = document.getElementById('authLogin');
const authNumberEl = document.getElementById('authNumberDisplay');
const confirmCheck = document.getElementById('confirmCheck');
const enterBtn     = document.getElementById('enterBtn');
const loginInput   = document.getElementById('loginInput');
const loginError   = document.getElementById('loginError');

function formatAccountNumber(num) {
  return num.replace(/(\d{4})(?=\d)/g, '$1 ');
}

// Formateo automático del input de login
loginInput.addEventListener('input', () => {
  const raw = loginInput.value.replace(/\D/g, '').slice(0, 16);
  loginInput.value = formatAccountNumber(raw);
  loginError.style.display = 'none';
});

// Crear cuenta
document.getElementById('createAccBtn').addEventListener('click', async () => {
  try {
    const res = await fetch('/api/account/create', { method: 'POST' });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error);

    authNumberEl.textContent = formatAccountNumber(data.accountNumber);
    authNumberEl.dataset.raw = data.accountNumber;
    authCreate.style.display = 'none';
    authShow.style.display = '';
  } catch (e) {
    console.error('Error creando cuenta:', e);
  }
});

// Copiar número
document.getElementById('copyAccBtn').addEventListener('click', () => {
  const num = authNumberEl.dataset.raw;
  navigator.clipboard.writeText(num).then(() => {
    document.getElementById('copyAccBtn').textContent = 'COPIADO';
    setTimeout(() => { document.getElementById('copyAccBtn').textContent = 'COPIAR'; }, 2000);
  });
});

// Descargar número como .txt
document.getElementById('downloadAccBtn').addEventListener('click', () => {
  const num = authNumberEl.dataset.raw;
  const blob = new Blob([`NEOVOX YT-V — Cuenta anonima\n\nNumero de cuenta: ${num}\n\nGuarda este archivo en un lugar seguro.\n`], { type: 'text/plain' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = `neovox-cuenta-${num.slice(0, 4)}.txt`;
  a.click();
  URL.revokeObjectURL(a.href);
});

// Checkbox confirmar
confirmCheck.addEventListener('change', () => {
  enterBtn.disabled = !confirmCheck.checked;
});

// Entrar tras crear cuenta
enterBtn.addEventListener('click', () => {
  const num = authNumberEl.dataset.raw;
  localStorage.setItem('neovox_account', num);
  currentAccount = num;
  authScreen.classList.add('hidden');
  initApp();
});

// Mostrar login
document.getElementById('showLoginBtn').addEventListener('click', () => {
  authCreate.style.display = 'none';
  authLogin.style.display = '';
});

// Mostrar crear
document.getElementById('showCreateBtn').addEventListener('click', () => {
  authLogin.style.display = 'none';
  authCreate.style.display = '';
});

// Login
document.getElementById('loginBtn').addEventListener('click', async () => {
  const num = loginInput.value.replace(/\D/g, '');
  if (num.length !== 16) {
    loginError.textContent = 'EL NUMERO DEBE TENER 16 DIGITOS';
    loginError.style.display = '';
    return;
  }
  try {
    const res = await fetch('/api/account/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ accountNumber: num })
    });
    if (res.status === 404) {
      loginError.textContent = 'CUENTA NO ENCONTRADA';
      loginError.style.display = '';
      return;
    }
    if (!res.ok) throw new Error('Error de servidor');

    localStorage.setItem('neovox_account', num);
    currentAccount = num;
    authScreen.classList.add('hidden');
    initApp();
  } catch (e) {
    loginError.textContent = 'ERROR DE CONEXION';
    loginError.style.display = '';
  }
});

// Auto-login si ya tiene cuenta guardada
if (currentAccount) {
  authScreen.classList.add('hidden');
  // initApp se llama abajo al final del archivo
}

// Header: botón logout
function addLogoutButton() {
  const header = document.querySelector('.app-header .flex');
  if (document.getElementById('logoutBtn')) return;
  const btn = document.createElement('button');
  btn.id = 'logoutBtn';
  btn.className = 'theme-btn';
  btn.title = 'Cerrar sesion';
  btn.style.marginLeft = '8px';
  btn.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--btn-fill)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>';
  btn.addEventListener('click', () => {
    localStorage.removeItem('neovox_account');
    location.reload();
  });
  header.appendChild(btn);
}

// ── Estado global ──────────────────────────────────────────────
let playlists  = [];
let activeId   = null;
let isPlaying  = false;
let bars       = [];
let waveTimer  = null;

// ── Audio nativo (reemplaza YouTube IFrame) ───────────────────
const audio       = document.getElementById('audioPlayer');
let trackList     = [];   // videos de la playlist activa: [{videoId, title, duration, thumbnail}]
let currentIndex  = 0;

// ── Keep-alive para segundo plano (Web Lock + Wake Lock + SW heartbeat) ──
// El <audio> nativo ya mantiene MediaSession, pero estas capas extra
// evitan que el navegador descarte la pestaña o apague la pantalla.

let wakeLockSentinel = null;
let swHeartbeatTimer = null;
let watchdogTimer = null;

// ── Web Locks API (evita discard de pestaña) ──
let webLockHeld = false;

function acquireWebLock() {
  if (webLockHeld || !navigator.locks) return;
  webLockHeld = true;
  navigator.locks.request('neovox-playback-lock', () => {
    return new Promise(resolve => { window._releaseWebLock = resolve; });
  }).catch(() => { webLockHeld = false; });
}

function releaseWebLock() {
  if (!webLockHeld) return;
  webLockHeld = false;
  if (window._releaseWebLock) { window._releaseWebLock(); window._releaseWebLock = null; }
}

// ── Wake Lock API (pantalla activa en móvil) ──
async function acquireWakeLock() {
  if (!('wakeLock' in navigator)) return;
  try {
    wakeLockSentinel = await navigator.wakeLock.request('screen');
    wakeLockSentinel.addEventListener('release', () => {
      wakeLockSentinel = null;
      if (isPlaying) acquireWakeLock();
    });
  } catch {}
}

function releaseWakeLock() {
  if (wakeLockSentinel) { wakeLockSentinel.release().catch(() => {}); wakeLockSentinel = null; }
}

// ── Service Worker heartbeat ──
function startSwHeartbeat() {
  if (swHeartbeatTimer) return;
  swHeartbeatTimer = setInterval(() => {
    if (navigator.serviceWorker?.controller) {
      navigator.serviceWorker.controller.postMessage({ type: 'keepalive', ts: Date.now() });
    }
  }, 15000);
}

function stopSwHeartbeat() {
  if (swHeartbeatTimer) { clearInterval(swHeartbeatTimer); swHeartbeatTimer = null; }
}

// ── Watchdog — reanuda si el sistema pausó el audio ──
function startWatchdog() {
  if (watchdogTimer) return;
  let lastCheckTime = Date.now();
  watchdogTimer = setInterval(() => {
    const now = Date.now();
    const elapsed = now - lastCheckTime;
    lastCheckTime = now;
    if (!isPlaying) return;
    // Si pasaron más de 5s, el sistema nos suspendió
    if (audio.paused && (elapsed > 5000 || !audio.ended)) {
      console.log('NEOVOX: Watchdog reanudando (elapsed=' + elapsed + 'ms)');
      audio.play().catch(() => {});
    }
  }, 2000);
}

function stopWatchdog() {
  if (watchdogTimer) { clearInterval(watchdogTimer); watchdogTimer = null; }
}

// ── Loop de silencio (iOS standalone) ──
// iOS suspende PWAs en modo standalone aunque haya <audio> activo.
// Un segundo <audio> con loop de silencio le indica al OS que hay un
// "cliente de audio" permanente, evitando la suspensión.
let silentAudio = null;

function createSilentWav() {
  const sampleRate = 8000;
  const numSamples = sampleRate * 2; // 2 segundos
  const headerSize = 44;
  const dataSize = numSamples;
  const buffer = new ArrayBuffer(headerSize + dataSize);
  const view = new DataView(buffer);
  const w = (off, str) => { for (let i = 0; i < str.length; i++) view.setUint8(off + i, str.charCodeAt(i)); };
  w(0, 'RIFF'); view.setUint32(4, 36 + dataSize, true); w(8, 'WAVE');
  w(12, 'fmt '); view.setUint32(16, 16, true); view.setUint16(20, 1, true);
  view.setUint16(22, 1, true); view.setUint32(24, sampleRate, true);
  view.setUint32(28, sampleRate, true); view.setUint16(32, 1, true); view.setUint16(34, 8, true);
  w(36, 'data'); view.setUint32(40, dataSize, true);
  for (let i = 0; i < numSamples; i++) view.setUint8(headerSize + i, 128 + (i % 3 === 0 ? 1 : 0));
  return URL.createObjectURL(new Blob([buffer], { type: 'audio/wav' }));
}

function startSilentLoop() {
  if (silentAudio) return;
  try {
    silentAudio = new Audio(createSilentWav());
    silentAudio.loop = true;
    silentAudio.volume = 0.01;
    silentAudio.setAttribute('playsinline', '');
    silentAudio.setAttribute('webkit-playsinline', '');
    silentAudio.play().catch(() => {});
  } catch {}
}

function stopSilentLoop() {
  if (silentAudio) { silentAudio.pause(); silentAudio.src = ''; silentAudio = null; }
}

// ── Orquestador ──
function startKeepAlive() {
  startSilentLoop();
  acquireWebLock();
  acquireWakeLock();
  startSwHeartbeat();
  startWatchdog();
}

function stopKeepAlive() {
  stopSilentLoop();
  releaseWebLock();
  releaseWakeLock();
  stopSwHeartbeat();
  stopWatchdog();
}

// ── Ciclo de vida: reanudar al volver de segundo plano ──
document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible' && isPlaying) {
    acquireWakeLock();
    if (audio.paused && !audio.ended) audio.play().catch(() => {});
    if (silentAudio && silentAudio.paused) silentAudio.play().catch(() => {});
  }
});

document.addEventListener('resume', () => {
  if (isPlaying) {
    acquireWakeLock();
    if (audio.paused && !audio.ended) audio.play().catch(() => {});
    if (silentAudio && silentAudio.paused) silentAudio.play().catch(() => {});
  }
});

// ── Picture-in-Picture: mini-player flotante ──────────────────
// Engaña al OS: ve un video activo en PiP → no suspende la página.
// De paso muestra carátula + progreso en un mini-player flotante.
const pipCanvas  = document.getElementById('pipCanvas');
const pipVideo   = document.getElementById('pipVideo');
const pipBtn     = document.getElementById('pipBtn');
const pipCtx     = pipCanvas.getContext('2d');
let pipActive    = false;
let pipDrawTimer = null;
let pipCoverImg  = null;

// Mostrar botón solo si el navegador soporta PiP
if (document.pictureInPictureEnabled) {
  pipBtn.style.display = '';
}

// Dibujar frame en el canvas: carátula + título + barra de progreso
function pipDrawFrame() {
  const W = pipCanvas.width;
  const H = pipCanvas.height;

  // Fondo oscuro
  pipCtx.fillStyle = '#0a0a0f';
  pipCtx.fillRect(0, 0, W, H);

  // Carátula centrada
  if (pipCoverImg && pipCoverImg.complete && pipCoverImg.naturalWidth) {
    const size = Math.min(W, H) * 0.55;
    const x = (W - size) / 2;
    const y = 20;
    // Sombra
    pipCtx.shadowColor = '#00f0ff44';
    pipCtx.shadowBlur = 20;
    pipCtx.drawImage(pipCoverImg, x, y, size, size);
    pipCtx.shadowBlur = 0;
  }

  // Título del track
  const track = typeof trackList !== 'undefined' && trackList[currentIndex];
  pipCtx.fillStyle = '#00f0ff';
  pipCtx.font = 'bold 22px Orbitron, monospace';
  pipCtx.textAlign = 'center';
  const title = track ? track.title.substring(0, 35).toUpperCase() : 'NEOVOX YT-V';
  pipCtx.fillText(title, W / 2, H - 70);

  // Info de track
  pipCtx.fillStyle = '#8888aa';
  pipCtx.font = '16px monospace';
  if (track) {
    pipCtx.fillText(`TRACK ${currentIndex + 1} / ${trackList.length}`, W / 2, H - 48);
  }

  // Barra de progreso
  const d = audio.duration || 0;
  const c = audio.currentTime || 0;
  const pct = d > 0 ? c / d : 0;
  const barY = H - 25;
  const barW = W - 80;
  const barX = 40;
  // Fondo barra
  pipCtx.fillStyle = '#1a1a2e';
  pipCtx.fillRect(barX, barY, barW, 8);
  // Progreso
  pipCtx.fillStyle = '#00f0ff';
  pipCtx.fillRect(barX, barY, barW * pct, 8);
  // Glow
  pipCtx.shadowColor = '#00f0ff';
  pipCtx.shadowBlur = 6;
  pipCtx.fillRect(barX, barY, barW * pct, 8);
  pipCtx.shadowBlur = 0;

  // Tiempo
  pipCtx.fillStyle = '#aaaacc';
  pipCtx.font = '13px monospace';
  pipCtx.textAlign = 'left';
  pipCtx.fillText(fmt(c), barX, barY - 5);
  pipCtx.textAlign = 'right';
  pipCtx.fillText(fmt(d), barX + barW, barY - 5);
}

function pipStart() {
  if (pipActive) return;

  // Conectar canvas al video via captureStream
  const stream = pipCanvas.captureStream(30); // 30fps
  pipVideo.srcObject = stream;
  pipVideo.muted = true;
  pipVideo.play().catch(() => {});

  // Dibujar continuamente
  pipDrawTimer = setInterval(pipDrawFrame, 100);

  // Solicitar PiP
  pipVideo.requestPictureInPicture().then(pipWin => {
    pipActive = true;
    pipBtn.classList.add('active');
    pipWin.addEventListener('resize', () => {});
  }).catch(err => {
    console.error('NEOVOX: PiP error:', err);
    clearInterval(pipDrawTimer);
    pipDrawTimer = null;
  });
}

function pipStop() {
  if (!pipActive) return;
  pipActive = false;
  pipBtn.classList.remove('active');
  if (document.pictureInPictureElement) {
    document.exitPictureInPicture().catch(() => {});
  }
  if (pipDrawTimer) { clearInterval(pipDrawTimer); pipDrawTimer = null; }
  pipVideo.srcObject = null;
}

// Detectar cuando el usuario cierra el PiP manualmente
pipVideo.addEventListener('leavepictureinpicture', () => {
  pipActive = false;
  pipBtn.classList.remove('active');
  if (pipDrawTimer) { clearInterval(pipDrawTimer); pipDrawTimer = null; }
});

// Botón toggle PiP
pipBtn.addEventListener('click', () => {
  if (pipActive) pipStop();
  else pipStart();
});

// Actualizar la imagen de carátula para el PiP cuando cambie el track
function pipUpdateCover(videoId) {
  if (!videoId) return;
  const img = new Image();
  img.crossOrigin = 'anonymous';
  img.onload = () => { pipCoverImg = img; };
  img.src = `https://img.youtube.com/vi/${videoId}/hqdefault.jpg`;
}

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

// ── API (con cuenta anónima) ──────────────────────────────────
function authHeaders(extra = {}) {
  return { 'X-Account-Number': currentAccount, ...extra };
}

async function loadFromAPI() {
  try {
    const res = await fetch('/api/playlists', { headers: authHeaders() });
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
    headers: authHeaders({ 'Content-Type': 'application/json' }),
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
  const res = await fetch(`/api/playlists/${id}`, { method: 'DELETE', headers: authHeaders() });
  if (!res.ok && res.status !== 404) throw new Error(res.statusText);
}

// ── Render lista playlists ─────────────────────────────────────
function renderList() {
  counter.textContent = `${playlists.length} LISTA${playlists.length !== 1 ? 'S' : ''} · MAX 20`;

  if (!playlists.length) {
    plList.innerHTML = `
      <div style="text-align:center;padding:40px 20px;font-family:'Share Tech Mono',monospace;font-size:12px;color:var(--pl-id-color);letter-spacing:2px;line-height:2.2">
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
        <div style="font-size:12px;letter-spacing:1px;color:${isActive ? 'var(--pl-name-active)' : 'var(--pl-name)'};font-weight:700;margin-bottom:2px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${pl.name}</div>
        <div style="font-family:'Share Tech Mono',monospace;font-size:10px;color:var(--pl-id-color);letter-spacing:1px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${pl.ytId}</div>
        <div style="margin-top:3px">
          <span style="font-size:9px;letter-spacing:1px;color:var(--pl-badge-color);background:var(--pl-badge-bg);border:1px solid var(--pl-badge-border);border-radius:3px;padding:2px 6px">YT PLAYLIST</span>
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

// ── Cargar playlist desde el proxy ─────────────────────────────
async function loadPlaylist(id) {
  const pl = playlists.find(p => p.id === id);
  if (!pl) return;
  activeId = id;
  renderList();

  // Reset visual
  isPlaying = false;
  audio.pause();
  vinyl.classList.remove('animate-spin-vinyl');
  setArmRest();
  animWf(false);
  updateDots('stopped');
  playBtn.classList.remove('active');
  pauseBtn.classList.remove('active');
  progFill.style.width = '0%';
  tCur.textContent = '0:00';
  tTot.textContent = '0:00';

  tiName.textContent = pl.name.toUpperCase();
  tiSub.textContent  = 'CARGANDO...';
  setMsg('OBTENIENDO PLAYLIST...');

  try {
    const res = await fetch(`/api/yt/playlist/${pl.ytId}`);
    if (!res.ok) throw new Error('Error ' + res.status);
    const data = await res.json();
    trackList = data.items || [];

    if (!trackList.length) {
      setMsg('PLAYLIST VACÍA O PRIVADA');
      return;
    }

    setMsg(`${trackList.length} TRACKS CARGADOS`);
    currentIndex = 0;
    loadTrack(0);
  } catch (e) {
    setMsg('ERROR: ' + e.message);
    console.error('NEOVOX loadPlaylist error:', e);
  }
}

// ── Cargar un track individual vía proxy de audio ─────────────
let skipCount = 0; // evitar skip en cadena infinito

function loadTrack(index) {
  if (!trackList.length) return;
  // Wrap around
  if (index >= trackList.length) index = 0;
  if (index < 0) index = trackList.length - 1;

  // Protección: si ya saltamos demasiados tracks seguidos, parar
  if (skipCount >= trackList.length) {
    skipCount = 0;
    setMsg('ERROR: NO SE PUEDE REPRODUCIR NINGÚN TRACK');
    doStop();
    return;
  }

  currentIndex = index;
  const track = trackList[index];

  tiName.textContent = track.title.toUpperCase();
  tiSub.textContent  = `TRACK ${String(index + 1).padStart(2, '0')} / ${trackList.length}`;
  setMsg('CARGANDO: ' + track.title.substring(0, 30) + '...');
  updateCover(track.videoId);
  updateMediaSession(track.title, 'YouTube Playlist');

  // Configurar audio y esperar a canplay antes de reproducir
  audio.src = `/api/yt/audio/${track.videoId}`;
  audio.volume = parseInt(volSl.value) / 100;
  audio.playbackRate = currentSpeed || 1;

  const onCanPlay = () => {
    audio.removeEventListener('canplay', onCanPlay);
    skipCount = 0; // reset — track cargó bien
    audio.play().catch(err => {
      console.error('NEOVOX: Play error:', err);
      setMsg('ERROR AL REPRODUCIR');
    });
  };
  audio.addEventListener('canplay', onCanPlay);
  audio.load();
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
  if (dragAngle >= ARM_START && activeId) {
    const pct = (dragAngle - ARM_START) / (ARM_END - ARM_START) * 100;
    const duration = audio.duration || 0;
    if (duration > 0) {
      audio.currentTime = (pct / 100) * duration;
    }
    audio.play().catch(() => {});
  } else {
    // Soltó fuera del disco
    if (isPlaying) {
      const c = audio.currentTime || 0;
      const d = audio.duration || 0;
      setArmProgress(d > 0 ? (c / d) * 100 : 0);
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

// ── Progreso (vía eventos nativos del <audio>) ────────────────
audio.addEventListener('timeupdate', () => {
  const c = audio.currentTime || 0;
  const d = audio.duration || 0;
  const pct = d > 0 ? (c / d) * 100 : 0;
  tCur.textContent     = fmt(c);
  tTot.textContent     = fmt(d);
  progFill.style.width = pct + '%';
  if (isPlaying) setArmProgress(pct);

  // Reportar posición al compact player de la pantalla de bloqueo
  if (d > 0 && 'mediaSession' in navigator) {
    try {
      navigator.mediaSession.setPositionState({
        duration: d,
        playbackRate: audio.playbackRate,
        position: Math.min(c, d)
      });
    } catch {}
  }
});

// ── MediaSession API (controles de segundo plano / pantalla bloqueo) ──
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
  navigator.mediaSession.setActionHandler('play', () => { audio.play().catch(() => {}); });
  navigator.mediaSession.setActionHandler('pause', () => { audio.pause(); });
  navigator.mediaSession.setActionHandler('previoustrack', () => { loadTrack(currentIndex - 1); });
  navigator.mediaSession.setActionHandler('nexttrack', () => { loadTrack(currentIndex + 1); });
  navigator.mediaSession.setActionHandler('stop', () => { audio.pause(); audio.currentTime = 0; doStop(); });

  // Seek desde pantalla de bloqueo / auriculares Bluetooth
  navigator.mediaSession.setActionHandler('seekbackward', (details) => {
    audio.currentTime = Math.max(0, audio.currentTime - (details.seekOffset || 10));
  });
  navigator.mediaSession.setActionHandler('seekforward', (details) => {
    audio.currentTime = Math.min(audio.duration || 0, audio.currentTime + (details.seekOffset || 10));
  });
  navigator.mediaSession.setActionHandler('seekto', (details) => {
    if (details.fastSeek && 'fastSeek' in audio) {
      audio.fastSeek(details.seekTime);
    } else {
      audio.currentTime = details.seekTime;
    }
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
  pipUpdateCover(videoId);
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
  startKeepAlive();
  vinyl.classList.add('animate-spin-vinyl');
  const c = audio.currentTime || 0;
  const d = audio.duration || 0;
  setArmProgress(d > 0 ? (c / d) * 100 : 0);
  animWf(true);
  updateDots('playing');
  playBtn.classList.add('active');
  pauseBtn.classList.remove('active');
  document.getElementById('playIco').innerHTML = '<polygon points="6,3 15,9 6,15" style="fill:var(--btn-hover-fill)"/>';
  setMsg('▶ REPRODUCIENDO');

  const track = trackList[currentIndex];
  if (track) {
    tiName.textContent = track.title.toUpperCase();
    tiSub.textContent = `TRACK ${String(currentIndex + 1).padStart(2, '0')} / ${trackList.length}`;
    labelText1.textContent = track.title.substring(0, 14).toUpperCase();
    updateCover(track.videoId);
  }

  if ('mediaSession' in navigator) {
    navigator.mediaSession.playbackState = 'playing';
  }
  updateMediaSession(track?.title || 'NEOVOX YT-V');
}

function doPause() {
  isPlaying = false;
  vinyl.classList.remove('animate-spin-vinyl');
  animWf(false);
  updateDots('paused');
  playBtn.classList.remove('active');
  pauseBtn.classList.add('active');
  document.getElementById('playIco').innerHTML = '<polygon points="6,3 15,9 6,15"/>';
  setMsg('❚❚ PAUSA');

  if ('mediaSession' in navigator) {
    navigator.mediaSession.playbackState = 'paused';
  }
}

function doStop() {
  isPlaying = false;
  stopKeepAlive();
  pipStop();
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
  setMsg('■ DETENIDO');

  if ('mediaSession' in navigator) {
    navigator.mediaSession.playbackState = 'none';
  }
}

// ── Eventos del <audio> nativo ─────────────────────────────────
audio.addEventListener('play', () => doPlay());
audio.addEventListener('pause', () => { if (!audio.ended) doPause(); });
audio.addEventListener('ended', () => loadTrack(currentIndex + 1));
audio.addEventListener('waiting', () => setMsg('BUFFERING...'));
audio.addEventListener('canplay', () => { if (isPlaying) setMsg('▶ REPRODUCIENDO'); });
audio.addEventListener('error', (e) => {
  const track = trackList[currentIndex];
  const errCode = audio.error?.code || '?';
  const errMsg = audio.error?.message || 'desconocido';
  console.error(`NEOVOX: Audio error track ${currentIndex} (${track?.videoId}): code=${errCode}, ${errMsg}`);
  setMsg(`ERROR ${errCode} · SALTANDO TRACK...`);
  skipCount++;
  setTimeout(() => loadTrack(currentIndex + 1), 2000);
});

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
    audio.playbackRate = speed;
    setMsg(`VELOCIDAD: ${speed}x`);
  });
});

// ── Listeners controles ────────────────────────────────────────
playBtn.addEventListener('click', () => {
  if (!activeId) { setMsg('SELECCIONA UNA PLAYLIST PRIMERO'); return; }
  if (isPlaying) {
    audio.pause();
  } else {
    audio.play().catch(() => {});
  }
});

pauseBtn.addEventListener('click', () => {
  if (isPlaying) audio.pause();
});

stopBtn.addEventListener('click', () => {
  audio.pause();
  audio.currentTime = 0;
  doStop();
});

prevBtn.addEventListener('click', () => {
  if (activeId && trackList.length) loadTrack(currentIndex - 1);
});

nextBtn.addEventListener('click', () => {
  if (activeId && trackList.length) loadTrack(currentIndex + 1);
});

document.getElementById('progBg').addEventListener('click', e => {
  if (!isPlaying) return;
  const r = e.currentTarget.getBoundingClientRect();
  const ratio = (e.clientX - r.left) / r.width;
  audio.currentTime = ratio * (audio.duration || 0);
});

volSl.addEventListener('input', () => {
  const v = volSl.value;
  volVal.textContent = v;
  volSl.style.background = `linear-gradient(to right, var(--vol-fill) ${v}%, var(--vol-track) ${v}%)`;
  audio.volume = parseInt(v) / 100;
});

// ── Stats / contador de visitas ────────────────────────────────
async function registerVisit() {
  try { await fetch('/api/visit', { method: 'POST' }); } catch {}
}

async function loadStats() {
  try {
    const res = await fetch('/api/stats');
    if (!res.ok) return;
    const s = await res.json();
    document.getElementById('statTotal').textContent = s.totalVisits.toLocaleString();
    document.getElementById('statUnique').textContent = s.uniqueUsers.toLocaleString();
    document.getElementById('statToday').textContent = s.todayVisits.toLocaleString();
    const d = new Date(s.launchedAt);
    document.getElementById('statSince').textContent = d.toLocaleDateString('es-ES', { day: '2-digit', month: 'short', year: 'numeric' }).toUpperCase();
  } catch {}
}

// ── PWA Install ───────────────────────────────────────────────
let deferredInstallPrompt = null;
const installBtn = document.getElementById('installBtn');

window.addEventListener('beforeinstallprompt', e => {
  e.preventDefault();
  deferredInstallPrompt = e;
  installBtn.style.display = 'flex';
});

// iOS: no dispara beforeinstallprompt, mostrar indicación manual
const isIos = /iphone|ipad|ipod/.test(navigator.userAgent.toLowerCase());
const isStandalone = window.matchMedia('(display-mode: standalone)').matches || navigator.standalone;

if (isIos && !isStandalone) {
  installBtn.style.display = 'flex';
}

installBtn.addEventListener('click', async () => {
  if (deferredInstallPrompt) {
    deferredInstallPrompt.prompt();
    const { outcome } = await deferredInstallPrompt.userChoice;
    if (outcome === 'accepted') {
      installBtn.style.display = 'none';
      setMsg('APP INSTALADA');
    }
    deferredInstallPrompt = null;
  } else if (isIos) {
    setMsg('PULSA COMPARTIR > AÑADIR A PANTALLA DE INICIO');
  }
});

// Ocultar si ya está instalada
window.addEventListener('appinstalled', () => {
  installBtn.style.display = 'none';
  deferredInstallPrompt = null;
  setMsg('NEOVOX INSTALADA CORRECTAMENTE');
});

// ── Init ───────────────────────────────────────────────────────
async function initApp() {
  addLogoutButton();
  // Solicitar almacenamiento persistente (evita que el navegador borre el cache)
  if (navigator.storage?.persist) {
    navigator.storage.persist().catch(() => {});
  }
  await registerVisit();
  await Promise.all([loadFromAPI(), loadStats()]);
  buildWf();
  setArmRest();
  updateDots('stopped');
  renderList();
  setMsg('SISTEMA LISTO · SELECCIONA UNA PLAYLIST');
  console.log('NEOVOX: Sistema listo (audio nativo)');
}

// Auto-login si ya tiene cuenta
if (currentAccount) {
  initApp();
}
