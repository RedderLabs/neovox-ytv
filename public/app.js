// ═══════════════════════════════════════════════════════════════
// NEOVOX Music — Modern Music App (RiMusic-style)
// ═══════════════════════════════════════════════════════════════

const API = window.location.origin;

// ── State ──────────────────────────────────────────────────────
let currentAccount = localStorage.getItem('neovox_account');
let playlists = [];
let queue = [];
let queueIndex = -1;
let isPlaying = false;
let shuffleOn = false;
let repeatMode = 0; // 0=off, 1=all, 2=one
let currentTrack = null;
let seekDragging = false;

// ── Audio Element ──────────────────────────────────────────────
const audio = document.getElementById('audioEl');
audio.volume = 0.8;

// ── DOM Refs ───────────────────────────────────────────────────
const $ = id => document.getElementById(id);

// Auth
const authScreen = $('authScreen');
const authCreate = $('authCreate');
const authShow = $('authShow');
const authLogin = $('authLogin');

// App
const app = $('app');

// Pages
const pages = {
  home: $('page-home'),
  search: $('page-search'),
  library: $('page-library'),
  settings: $('page-settings'),
  playlist: $('page-playlist'),
};
let currentPage = 'home';
let previousPage = 'library';

// Mini player
const miniPlayer = $('miniPlayer');
const miniProgress = $('miniProgress');
const miniThumb = $('miniThumb');
const miniTitle = $('miniTitle');
const miniArtist = $('miniArtist');
const miniPlayIcon = $('miniPlayIcon');

// Full player
const fullPlayer = $('fullPlayer');
const fullPlayerBg = $('fullPlayerBg');
const fullArt = $('fullArt');
const fullTitle = $('fullTitle');
const fullArtist = $('fullArtist');
const fullPlayIcon = $('fullPlayIcon');
const fullProgressSlider = $('fullProgressSlider');
const fullTimeCur = $('fullTimeCur');
const fullTimeTotal = $('fullTimeTotal');
const fullVolumeSlider = $('fullVolumeSlider');

// ═══════════════════════════════════════════════════════════════
// AUTH
// ═══════════════════════════════════════════════════════════════

function showAuthView(view) {
  [authCreate, authShow, authLogin].forEach(v => v.classList.add('hidden'));
  view.classList.remove('hidden');
}

$('showLoginBtn').onclick = () => showAuthView(authLogin);
$('showCreateBtn').onclick = () => showAuthView(authCreate);

$('createAccBtn').onclick = async () => {
  try {
    const res = await fetch(`${API}/api/account/create`, { method: 'POST' });
    const data = await res.json();
    const num = data.accountNumber;
    $('authNumberDisplay').textContent = num.replace(/(.{4})/g, '$1 ').trim();
    $('authNumberDisplay').dataset.raw = num;
    showAuthView(authShow);
  } catch (e) {
    toast('Error al crear cuenta');
  }
};

$('copyAccBtn').onclick = () => {
  navigator.clipboard.writeText($('authNumberDisplay').dataset.raw);
  toast('Copiado al portapapeles');
};

$('downloadAccBtn').onclick = () => {
  const num = $('authNumberDisplay').dataset.raw;
  const blob = new Blob([`NEOVOX Music\nNumero de cuenta: ${num}\nGuarda este archivo en un lugar seguro.`], { type: 'text/plain' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = `neovox-account-${num.slice(0, 4)}.txt`;
  a.click();
};

$('confirmCheck').onchange = (e) => {
  $('enterBtn').disabled = !e.target.checked;
};

$('enterBtn').onclick = () => {
  const num = $('authNumberDisplay').dataset.raw;
  localStorage.setItem('neovox_account', num);
  currentAccount = num;
  enterApp();
};

$('loginBtn').onclick = async () => {
  const raw = $('loginInput').value.replace(/\s/g, '');
  if (!/^\d{16}$/.test(raw)) {
    showError('Debe ser un numero de 16 digitos');
    return;
  }
  try {
    const res = await fetch(`${API}/api/account/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ accountNumber: raw }),
    });
    if (!res.ok) {
      showError('Cuenta no encontrada');
      return;
    }
    localStorage.setItem('neovox_account', raw);
    currentAccount = raw;
    enterApp();
  } catch (e) {
    showError('Error de conexion');
  }
};

$('loginInput').addEventListener('input', (e) => {
  let v = e.target.value.replace(/\D/g, '').slice(0, 16);
  v = v.replace(/(.{4})/g, '$1 ').trim();
  e.target.value = v;
});

function showError(msg) {
  const el = $('loginError');
  el.textContent = msg;
  el.classList.remove('hidden');
  setTimeout(() => el.classList.add('hidden'), 3000);
}

function enterApp() {
  authScreen.classList.add('hidden');
  app.classList.remove('hidden');
  loadPlaylists();
  loadTrending();
  loadStats();
  // Register visit
  fetch(`${API}/api/visit`, { method: 'POST' }).catch(() => {});
  // Settings account number
  $('settingsAccNum').textContent = currentAccount.replace(/(.{4})/g, '$1 ').trim();
}

// Auto-login
if (currentAccount) {
  enterApp();
}

// ═══════════════════════════════════════════════════════════════
// NAVIGATION
// ═══════════════════════════════════════════════════════════════

function showPage(name) {
  if (name === currentPage) return;
  previousPage = currentPage;

  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  pages[name].classList.add('active');

  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  const navBtn = document.querySelector(`.nav-item[data-page="${name}"]`);
  if (navBtn) navBtn.classList.add('active');

  currentPage = name;

  if (name === 'search') {
    setTimeout(() => $('searchInput').focus(), 300);
  }
}

document.querySelectorAll('.nav-item').forEach(btn => {
  btn.onclick = () => showPage(btn.dataset.page);
});

// Playlist detail back
$('playlistBack').onclick = () => {
  pages.playlist.classList.remove('active');
  pages[previousPage].classList.add('active');
  currentPage = previousPage;
};

// ═══════════════════════════════════════════════════════════════
// PLAYLISTS (API)
// ═══════════════════════════════════════════════════════════════

async function loadPlaylists() {
  try {
    const res = await fetch(`${API}/api/playlists`, {
      headers: { 'X-Account-Number': currentAccount },
    });
    playlists = await res.json();
    renderPlaylists();
    renderQuickPicks();
  } catch (e) {
    console.error('Failed to load playlists:', e);
  }
}

function renderPlaylists() {
  const grid = $('playlistGrid');
  if (playlists.length === 0) {
    grid.innerHTML = `
      <div class="empty-state">
        <span class="material-symbols-rounded">queue_music</span>
        <p>Aun no tienes playlists</p>
        <button class="btn-primary btn-sm" onclick="openAddModal()">Agregar playlist</button>
      </div>`;
    return;
  }

  grid.innerHTML = playlists.map(pl => `
    <div class="playlist-card" data-id="${pl.id}" data-ytid="${pl.ytId}" onclick="openPlaylistDetail('${pl.id}')">
      <div class="playlist-card-art">
        <span class="material-symbols-rounded">queue_music</span>
      </div>
      <div class="playlist-card-info">
        <div class="playlist-card-name">${esc(pl.name)}</div>
        <div class="playlist-card-sub">YouTube Playlist</div>
      </div>
      <button class="playlist-card-play" onclick="event.stopPropagation(); quickPlayPlaylist('${pl.ytId}', '${esc(pl.name)}')">
        <span class="material-symbols-rounded">play_arrow</span>
      </button>
    </div>
  `).join('');
}

function renderQuickPicks() {
  const el = $('quickPicks');
  if (playlists.length === 0) {
    el.innerHTML = `
      <div class="empty-state" style="padding:24px">
        <span class="material-symbols-rounded">library_music</span>
        <p>Agrega playlists desde la biblioteca</p>
      </div>`;
    return;
  }
  el.innerHTML = playlists.slice(0, 6).map(pl => `
    <div class="quick-pick" onclick="quickPlayPlaylist('${pl.ytId}', '${esc(pl.name)}')">
      <div class="quick-pick-art">
        <span class="material-symbols-rounded" style="font-size:16px;color:var(--text-muted);display:flex;align-items:center;justify-content:center;width:100%;height:100%">music_note</span>
      </div>
      <span>${esc(pl.name)}</span>
    </div>
  `).join('');
}

// ── Add Playlist Modal ─────────────────────────────────────────

function openAddModal() {
  $('addModal').classList.remove('hidden');
  $('modalPlName').value = '';
  $('modalPlUrl').value = '';
  $('modalPlName').focus();
}

$('addPlaylistBtn').onclick = openAddModal;
$('addFirstPlaylist')?.addEventListener('click', openAddModal);
$('modalCancel').onclick = () => $('addModal').classList.add('hidden');

$('modalAdd').onclick = async () => {
  const name = $('modalPlName').value.trim();
  const url = $('modalPlUrl').value.trim();
  if (!name || !url) { toast('Completa todos los campos'); return; }

  const match = url.match(/[?&]list=([a-zA-Z0-9_-]+)/);
  if (!match) { toast('URL de playlist invalida'); return; }

  try {
    const res = await fetch(`${API}/api/playlists`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Account-Number': currentAccount,
      },
      body: JSON.stringify({ name, ytId: match[1] }),
    });
    if (!res.ok) {
      const err = await res.json();
      toast(err.error || 'Error al agregar');
      return;
    }
    $('addModal').classList.add('hidden');
    toast('Playlist agregada');
    loadPlaylists();
  } catch (e) {
    toast('Error de conexion');
  }
};

// ── Playlist Detail ────────────────────────────────────────────

let currentPlaylistDetail = null;

async function openPlaylistDetail(id) {
  const pl = playlists.find(p => p.id === id);
  if (!pl) return;

  currentPlaylistDetail = pl;
  $('playlistDetailTitle').textContent = pl.name;
  $('playlistHeroTitle').textContent = pl.name;
  $('playlistHeroSub').textContent = 'Cargando...';
  $('playlistHeroArt').innerHTML = '';
  $('playlistTracks').innerHTML = '<div class="loading-spinner"><div class="spinner"></div></div>';

  previousPage = currentPage;
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  pages.playlist.classList.add('active');
  currentPage = 'playlist';

  try {
    const res = await fetch(`${API}/api/playlist-items/${pl.ytId}`);
    const data = await res.json();

    if (data.thumbnail) {
      $('playlistHeroArt').innerHTML = `<img src="${data.thumbnail}" alt="" />`;
    }
    $('playlistHeroSub').textContent = `${data.items.length} canciones`;

    renderTrackList($('playlistTracks'), data.items);

    // Update quick pick art
    updatePlaylistArt(pl.id, data.thumbnail);
  } catch (e) {
    $('playlistTracks').innerHTML = '<div class="empty-state"><p>Error al cargar playlist</p></div>';
  }
}

$('playAllBtn').onclick = () => {
  const tracks = $('playlistTracks').querySelectorAll('.track-item');
  if (tracks.length === 0) return;
  const items = Array.from(tracks).map(t => JSON.parse(t.dataset.track));
  playQueue(items, 0);
};

$('shuffleBtn').onclick = () => {
  const tracks = $('playlistTracks').querySelectorAll('.track-item');
  if (tracks.length === 0) return;
  const items = Array.from(tracks).map(t => JSON.parse(t.dataset.track));
  const shuffled = [...items].sort(() => Math.random() - 0.5);
  playQueue(shuffled, 0);
};

$('playlistDelete').onclick = async () => {
  if (!currentPlaylistDetail) return;
  if (!confirm('Eliminar esta playlist?')) return;

  try {
    await fetch(`${API}/api/playlists/${currentPlaylistDetail.id}`, {
      method: 'DELETE',
      headers: { 'X-Account-Number': currentAccount },
    });
    toast('Playlist eliminada');
    $('playlistBack').click();
    loadPlaylists();
  } catch (e) {
    toast('Error al eliminar');
  }
};

async function quickPlayPlaylist(ytId, name) {
  try {
    toast(`Cargando ${name}...`);
    const res = await fetch(`${API}/api/playlist-items/${ytId}`);
    const data = await res.json();
    if (data.items.length > 0) {
      playQueue(data.items, 0);
    } else {
      toast('Playlist vacia');
    }
  } catch (e) {
    toast('Error al cargar playlist');
  }
}

function updatePlaylistArt(plId, thumbUrl) {
  if (!thumbUrl) return;
  const card = document.querySelector(`.playlist-card[data-id="${plId}"] .playlist-card-art`);
  if (card) card.innerHTML = `<img src="${thumbUrl}" alt="" />`;
}

// ═══════════════════════════════════════════════════════════════
// SEARCH
// ═══════════════════════════════════════════════════════════════

let searchTimer = null;

$('searchInput').addEventListener('input', (e) => {
  const q = e.target.value.trim();
  $('searchClear').classList.toggle('hidden', !q);
  clearTimeout(searchTimer);
  if (!q) {
    $('searchResults').innerHTML = `
      <div class="empty-state">
        <span class="material-symbols-rounded">travel_explore</span>
        <p>Busca tu musica favorita</p>
      </div>`;
    return;
  }
  searchTimer = setTimeout(() => doSearch(q), 500);
});

$('searchClear').onclick = () => {
  $('searchInput').value = '';
  $('searchClear').classList.add('hidden');
  $('searchResults').innerHTML = `
    <div class="empty-state">
      <span class="material-symbols-rounded">travel_explore</span>
      <p>Busca tu musica favorita</p>
    </div>`;
  $('searchInput').focus();
};

async function doSearch(q) {
  $('searchResults').innerHTML = '<div class="loading-spinner"><div class="spinner"></div></div>';
  try {
    const res = await fetch(`${API}/api/search?q=${encodeURIComponent(q)}&limit=25`);
    const items = await res.json();
    if (items.length === 0) {
      $('searchResults').innerHTML = '<div class="empty-state"><p>Sin resultados</p></div>';
      return;
    }
    renderTrackList($('searchResults'), items);
  } catch (e) {
    $('searchResults').innerHTML = '<div class="empty-state"><p>Error en la busqueda</p></div>';
  }
}

// ═══════════════════════════════════════════════════════════════
// TRENDING
// ═══════════════════════════════════════════════════════════════

async function loadTrending() {
  try {
    const res = await fetch(`${API}/api/trending`);
    const items = await res.json();
    if (items.length > 0) {
      renderTrackList($('trendingList'), items);
    } else {
      $('trendingList').innerHTML = '<div class="empty-state"><p>No se pudieron cargar tendencias</p></div>';
    }
  } catch (e) {
    $('trendingList').innerHTML = '<div class="empty-state"><p>Error al cargar tendencias</p></div>';
  }
}

// ═══════════════════════════════════════════════════════════════
// TRACK RENDERING
// ═══════════════════════════════════════════════════════════════

function renderTrackList(container, items) {
  container.innerHTML = items.map((track, i) => `
    <div class="track-item ${currentTrack?.videoId === track.videoId ? 'playing' : ''}"
         data-track='${JSON.stringify(track).replace(/'/g, "&#39;")}'
         data-index="${i}"
         onclick="playFromList(this)">
      <div class="track-thumb">
        ${track.thumbnail ? `<img src="${track.thumbnail}" alt="" loading="lazy" />` : ''}
        ${currentTrack?.videoId === track.videoId ? `
          <div class="playing-indicator">
            <span class="material-symbols-rounded">${isPlaying ? 'equalizer' : 'pause'}</span>
          </div>` : ''}
      </div>
      <div class="track-info">
        <div class="track-title">${esc(track.title)}</div>
        <div class="track-artist">${esc(track.artist)}</div>
      </div>
      <span class="track-duration">${track.duration || ''}</span>
    </div>
  `).join('');
}

function playFromList(el) {
  const track = JSON.parse(el.dataset.track);
  // Build queue from siblings
  const siblings = el.parentElement.querySelectorAll('.track-item');
  const items = Array.from(siblings).map(s => JSON.parse(s.dataset.track));
  const idx = parseInt(el.dataset.index);
  playQueue(items, idx);
}

// ═══════════════════════════════════════════════════════════════
// PLAYER / QUEUE
// ═══════════════════════════════════════════════════════════════

function playQueue(items, startIndex) {
  queue = items;
  queueIndex = startIndex;
  playTrack(queue[queueIndex]);
}

async function playTrack(track) {
  if (!track) return;
  currentTrack = track;
  isPlaying = false;
  updatePlayerUI();
  updatePlayingHighlight();

  try {
    const res = await fetch(`${API}/api/stream-url/${track.videoId}`);
    if (!res.ok) throw new Error('Stream failed');
    const data = await res.json();

    // Use proxy to avoid CORS
    const proxyUrl = `${API}/api/audio-proxy?url=${encodeURIComponent(data.url)}`;
    audio.src = proxyUrl;
    audio.play();
    isPlaying = true;
    updatePlayerUI();
    showMiniPlayer();
  } catch (e) {
    console.error('Play error:', e);
    toast('Error al reproducir');
    // Try next track
    setTimeout(() => playNext(), 1500);
  }
}

function playNext() {
  if (repeatMode === 2) {
    audio.currentTime = 0;
    audio.play();
    return;
  }
  if (queueIndex < queue.length - 1) {
    queueIndex++;
    playTrack(queue[queueIndex]);
  } else if (repeatMode === 1) {
    queueIndex = 0;
    playTrack(queue[queueIndex]);
  }
}

function playPrev() {
  if (audio.currentTime > 3) {
    audio.currentTime = 0;
    return;
  }
  if (queueIndex > 0) {
    queueIndex--;
    playTrack(queue[queueIndex]);
  }
}

function togglePlay() {
  if (!currentTrack) return;
  if (isPlaying) {
    audio.pause();
    isPlaying = false;
  } else {
    audio.play();
    isPlaying = true;
  }
  updatePlayerUI();
}

// Audio events
audio.addEventListener('ended', () => {
  isPlaying = false;
  updatePlayerUI();
  playNext();
});

audio.addEventListener('error', () => {
  console.error('Audio error');
  isPlaying = false;
  updatePlayerUI();
});

// ═══════════════════════════════════════════════════════════════
// UI UPDATES
// ═══════════════════════════════════════════════════════════════

function updatePlayerUI() {
  const icon = isPlaying ? 'pause' : 'play_arrow';
  miniPlayIcon.textContent = icon;
  fullPlayIcon.textContent = icon;

  if (currentTrack) {
    miniTitle.textContent = currentTrack.title;
    miniArtist.textContent = currentTrack.artist;
    fullTitle.textContent = currentTrack.title;
    fullArtist.textContent = currentTrack.artist;

    if (currentTrack.thumbnail) {
      miniThumb.innerHTML = `<img src="${currentTrack.thumbnail}" alt="" />`;
      fullArt.innerHTML = `<img src="${currentTrack.thumbnail}" alt="" />`;
      fullPlayerBg.style.backgroundImage = `url(${currentTrack.thumbnail})`;
    }

    // Update media session
    if ('mediaSession' in navigator) {
      navigator.mediaSession.metadata = new MediaMetadata({
        title: currentTrack.title,
        artist: currentTrack.artist,
        artwork: currentTrack.thumbnail ? [{ src: currentTrack.thumbnail }] : [],
      });
    }
  }
}

function showMiniPlayer() {
  miniPlayer.classList.remove('hidden');
}

function updatePlayingHighlight() {
  document.querySelectorAll('.track-item').forEach(el => {
    const track = JSON.parse(el.dataset.track);
    const isThis = currentTrack?.videoId === track.videoId;
    el.classList.toggle('playing', isThis);

    const thumb = el.querySelector('.track-thumb');
    const existing = thumb.querySelector('.playing-indicator');
    if (isThis && !existing) {
      const div = document.createElement('div');
      div.className = 'playing-indicator';
      div.innerHTML = `<span class="material-symbols-rounded">${isPlaying ? 'equalizer' : 'pause'}</span>`;
      thumb.appendChild(div);
    } else if (!isThis && existing) {
      existing.remove();
    } else if (isThis && existing) {
      existing.querySelector('.material-symbols-rounded').textContent = isPlaying ? 'equalizer' : 'pause';
    }
  });
}

// Progress update
setInterval(() => {
  if (!audio.duration || seekDragging) return;
  const pct = (audio.currentTime / audio.duration) * 100;
  miniProgress.style.width = pct + '%';
  fullProgressSlider.value = pct;
  fullTimeCur.textContent = fmtTime(audio.currentTime);
  fullTimeTotal.textContent = fmtTime(audio.duration);
}, 500);

function fmtTime(s) {
  if (!s || isNaN(s)) return '0:00';
  const m = Math.floor(s / 60);
  const sec = Math.floor(s % 60);
  return `${m}:${sec.toString().padStart(2, '0')}`;
}

// ═══════════════════════════════════════════════════════════════
// MINI PLAYER CONTROLS
// ═══════════════════════════════════════════════════════════════

$('miniPlayBtn').onclick = (e) => { e.stopPropagation(); togglePlay(); };
$('miniPrev').onclick = (e) => { e.stopPropagation(); playPrev(); };
$('miniNext').onclick = (e) => { e.stopPropagation(); playNext(); };

// Tap mini player to open full player
$('miniPlayerTap').onclick = (e) => {
  if (e.target.closest('.mini-controls')) return;
  openFullPlayer();
};

// ═══════════════════════════════════════════════════════════════
// FULL PLAYER
// ═══════════════════════════════════════════════════════════════

function openFullPlayer() {
  fullPlayer.classList.add('open');
}

function closeFullPlayer() {
  fullPlayer.classList.remove('open');
}

$('fullPlayerClose').onclick = closeFullPlayer;
$('fullPlayBtn').onclick = togglePlay;
$('fullPrev').onclick = playPrev;
$('fullNext').onclick = playNext;

// Shuffle
$('fullShuffle').onclick = () => {
  shuffleOn = !shuffleOn;
  $('fullShuffle').classList.toggle('active', shuffleOn);
  if (shuffleOn && queue.length > 1) {
    const current = queue[queueIndex];
    const rest = queue.filter((_, i) => i !== queueIndex);
    rest.sort(() => Math.random() - 0.5);
    queue = [current, ...rest];
    queueIndex = 0;
  }
};

// Repeat
$('fullRepeat').onclick = () => {
  repeatMode = (repeatMode + 1) % 3;
  const icon = $('fullRepeat').querySelector('.material-symbols-rounded');
  $('fullRepeat').classList.toggle('active', repeatMode > 0);
  icon.textContent = repeatMode === 2 ? 'repeat_one' : 'repeat';
};

// Progress seeking
fullProgressSlider.addEventListener('mousedown', () => seekDragging = true);
fullProgressSlider.addEventListener('touchstart', () => seekDragging = true);
fullProgressSlider.addEventListener('input', () => {
  const pct = fullProgressSlider.value;
  fullTimeCur.textContent = fmtTime((pct / 100) * audio.duration);
});
fullProgressSlider.addEventListener('change', () => {
  seekDragging = false;
  if (audio.duration) {
    audio.currentTime = (fullProgressSlider.value / 100) * audio.duration;
  }
});

// Volume
fullVolumeSlider.addEventListener('input', () => {
  audio.volume = fullVolumeSlider.value / 100;
});

// ═══════════════════════════════════════════════════════════════
// QUEUE PANEL
// ═══════════════════════════════════════════════════════════════

$('fullPlayerQueue').onclick = () => {
  renderQueue();
  $('queuePanel').classList.add('open');
};
$('queueClose').onclick = () => $('queuePanel').classList.remove('open');

$('queueClear').onclick = () => {
  queue = currentTrack ? [currentTrack] : [];
  queueIndex = 0;
  renderQueue();
  toast('Cola limpiada');
};

function renderQueue() {
  const list = $('queueList');
  if (queue.length === 0) {
    list.innerHTML = '<div class="empty-state"><p>La cola esta vacia</p></div>';
    return;
  }
  list.innerHTML = queue.map((track, i) => `
    <div class="track-item ${i === queueIndex ? 'playing' : ''}"
         data-track='${JSON.stringify(track).replace(/'/g, "&#39;")}'
         data-index="${i}"
         onclick="queueIndex=${i}; playTrack(queue[${i}]); renderQueue();">
      <div class="track-thumb">
        ${track.thumbnail ? `<img src="${track.thumbnail}" alt="" loading="lazy" />` : ''}
      </div>
      <div class="track-info">
        <div class="track-title">${esc(track.title)}</div>
        <div class="track-artist">${esc(track.artist)}</div>
      </div>
      <span class="track-duration">${track.duration || ''}</span>
    </div>
  `).join('');
}

// ═══════════════════════════════════════════════════════════════
// SETTINGS
// ═══════════════════════════════════════════════════════════════

// Theme
let theme = localStorage.getItem('neovox_theme') || 'dark';
if (theme === 'light') {
  document.documentElement.dataset.theme = 'light';
  $('themeSwitch').classList.remove('on');
} else {
  $('themeSwitch').classList.add('on');
}

$('themeToggle').onclick = () => {
  theme = theme === 'dark' ? 'light' : 'dark';
  document.documentElement.dataset.theme = theme === 'light' ? 'light' : '';
  $('themeSwitch').classList.toggle('on', theme === 'dark');
  localStorage.setItem('neovox_theme', theme);
};

// Copy account in settings
$('copyAccSettings').onclick = (e) => {
  e.stopPropagation();
  navigator.clipboard.writeText(currentAccount);
  toast('Copiado');
};

// Logout
$('logoutBtn').onclick = () => {
  if (!confirm('Cerrar sesion?')) return;
  localStorage.removeItem('neovox_account');
  currentAccount = null;
  audio.pause();
  audio.src = '';
  location.reload();
};

// Stats
async function loadStats() {
  try {
    const res = await fetch(`${API}/api/stats`);
    const s = await res.json();
    $('statTotal').textContent = s.totalVisits.toLocaleString();
    $('statUnique').textContent = s.uniqueUsers.toLocaleString();
    $('statToday').textContent = s.todayVisits.toLocaleString();
    const d = new Date(s.launchedAt);
    $('statSince').textContent = d.toLocaleDateString('es', { day: 'numeric', month: 'short', year: 'numeric' });
  } catch (e) {
    console.error('Stats error:', e);
  }
}

// ═══════════════════════════════════════════════════════════════
// MEDIA SESSION (background playback controls)
// ═══════════════════════════════════════════════════════════════

if ('mediaSession' in navigator) {
  navigator.mediaSession.setActionHandler('play', () => { audio.play(); isPlaying = true; updatePlayerUI(); });
  navigator.mediaSession.setActionHandler('pause', () => { audio.pause(); isPlaying = false; updatePlayerUI(); });
  navigator.mediaSession.setActionHandler('previoustrack', playPrev);
  navigator.mediaSession.setActionHandler('nexttrack', playNext);
}

// ═══════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════

function esc(str) {
  if (!str) return '';
  const d = document.createElement('div');
  d.textContent = str;
  return d.innerHTML;
}

let toastTimer = null;
function toast(msg) {
  let el = document.querySelector('.toast');
  if (!el) {
    el = document.createElement('div');
    el.className = 'toast';
    document.body.appendChild(el);
  }
  el.textContent = msg;
  el.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.remove('show'), 2500);
}

// Expose for inline onclick
window.showPage = showPage;
window.openAddModal = openAddModal;
window.openPlaylistDetail = openPlaylistDetail;
window.quickPlayPlaylist = quickPlayPlaylist;
window.playFromList = playFromList;
