const express = require('express');
const path = require('path');
const Database = require('better-sqlite3');

const app = express();
const PORT = process.env.PORT || 3000;
const MAX_PLAYLISTS = 20;

// ── Base de datos ──────────────────────────────────────────────
const db = new Database(path.join(__dirname, 'data', 'neovox.db'));
db.pragma('journal_mode = WAL');

db.exec(`
  CREATE TABLE IF NOT EXISTS playlists (
    id    TEXT PRIMARY KEY,
    name  TEXT NOT NULL,
    ytId  TEXT NOT NULL,
    added INTEGER NOT NULL
  )
`);

// ── Middleware ──────────────────────────────────────────────────
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// ── Helpers ────────────────────────────────────────────────────
function uid() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
}

// ── API Routes ─────────────────────────────────────────────────

// GET /api/playlists
app.get('/api/playlists', (req, res) => {
  try {
    const rows = db.prepare('SELECT * FROM playlists ORDER BY added DESC').all();
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /api/playlists
app.post('/api/playlists', (req, res) => {
  try {
    const { name, ytId } = req.body;

    if (!name || !ytId) {
      return res.status(400).json({ error: 'name y ytId son requeridos' });
    }

    const count = db.prepare('SELECT COUNT(*) AS c FROM playlists').get().c;
    if (count >= MAX_PLAYLISTS) {
      return res.status(409).json({ error: `Limite de ${MAX_PLAYLISTS} playlists alcanzado` });
    }

    const pl = {
      id: uid(),
      name: name.substring(0, 40),
      ytId,
      added: Date.now()
    };

    db.prepare('INSERT INTO playlists (id, name, ytId, added) VALUES (?, ?, ?, ?)')
      .run(pl.id, pl.name, pl.ytId, pl.added);

    res.status(201).json(pl);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// DELETE /api/playlists/:id
app.delete('/api/playlists/:id', (req, res) => {
  try {
    const result = db.prepare('DELETE FROM playlists WHERE id = ?').run(req.params.id);
    if (result.changes === 0) {
      return res.status(404).json({ error: 'Playlist no encontrada' });
    }
    res.status(204).end();
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Start ──────────────────────────────────────────────────────
const HOST = process.env.HOST || '0.0.0.0';

app.listen(PORT, HOST, () => {
  const displayHost = HOST === '0.0.0.0' ? 'localhost' : HOST;
  console.log(`NEOVOX YT-V servidor en http://${displayHost}:${PORT}`);
  console.log(`Escuchando en ${HOST}:${PORT} (accesible desde toda la red)`);
});
