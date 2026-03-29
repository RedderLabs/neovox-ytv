require('dotenv').config();
const express = require('express');
const path = require('path');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 3000;
const MAX_PLAYLISTS = 20;

// ── Base de datos PostgreSQL (Neon) ───────────────────────────
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function initDB() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS accounts (
      account_number TEXT PRIMARY KEY,
      created_at     BIGINT NOT NULL
    )
  `);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS playlists (
      id              TEXT PRIMARY KEY,
      account_number  TEXT NOT NULL REFERENCES accounts(account_number) ON DELETE CASCADE,
      name            TEXT NOT NULL,
      yt_id           TEXT NOT NULL,
      added           BIGINT NOT NULL
    )
  `);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS visits (
      id         SERIAL PRIMARY KEY,
      ip         TEXT NOT NULL,
      user_agent TEXT,
      visited    BIGINT NOT NULL
    )
  `);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS stats (
      key   TEXT PRIMARY KEY,
      value BIGINT NOT NULL DEFAULT 0
    )
  `);
  await pool.query(`
    INSERT INTO stats (key, value) VALUES ('total_visits', 0)
    ON CONFLICT (key) DO NOTHING
  `);
  await pool.query(`
    INSERT INTO stats (key, value) VALUES ('launched', $1)
    ON CONFLICT (key) DO NOTHING
  `, [Date.now()]);
}

// ── Middleware ──────────────────────────────────────────────────
// CORS: permitir peticiones desde Flutter web y otros orígenes
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Account-Number');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// ── Helpers ────────────────────────────────────────────────────
function uid() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
}

function generateAccountNumber() {
  let num = '';
  for (let i = 0; i < 16; i++) num += Math.floor(Math.random() * 10);
  return num;
}

// ── Auth middleware ────────────────────────────────────────────
function requireAccount(req, res, next) {
  const account = req.headers['x-account-number'];
  if (!account || !/^\d{16}$/.test(account)) {
    return res.status(401).json({ error: 'Cuenta requerida' });
  }
  req.accountNumber = account;
  next();
}

// ── Account Routes ────────────────────────────────────────────

// POST /api/account/create — crear cuenta anónima
app.post('/api/account/create', async (req, res) => {
  try {
    const accountNumber = generateAccountNumber();
    await pool.query(
      'INSERT INTO accounts (account_number, created_at) VALUES ($1, $2)',
      [accountNumber, Date.now()]
    );
    res.status(201).json({ accountNumber });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /api/account/login — verificar que la cuenta existe
app.post('/api/account/login', async (req, res) => {
  try {
    const { accountNumber } = req.body;
    if (!accountNumber || !/^\d{16}$/.test(accountNumber)) {
      return res.status(400).json({ error: 'Número de cuenta inválido (16 dígitos)' });
    }
    const result = await pool.query(
      'SELECT account_number, created_at FROM accounts WHERE account_number = $1',
      [accountNumber]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Cuenta no encontrada' });
    }
    res.json({ accountNumber: result.rows[0].account_number });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Playlist Routes (requieren cuenta) ────────────────────────

// GET /api/playlists
app.get('/api/playlists', requireAccount, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, name, yt_id AS "ytId", added FROM playlists WHERE account_number = $1 ORDER BY added DESC',
      [req.accountNumber]
    );
    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /api/playlists
app.post('/api/playlists', requireAccount, async (req, res) => {
  try {
    const { name, ytId } = req.body;
    if (!name || !ytId) {
      return res.status(400).json({ error: 'name y ytId son requeridos' });
    }
    const countResult = await pool.query(
      'SELECT COUNT(*) AS c FROM playlists WHERE account_number = $1',
      [req.accountNumber]
    );
    if (parseInt(countResult.rows[0].c) >= MAX_PLAYLISTS) {
      return res.status(409).json({ error: `Limite de ${MAX_PLAYLISTS} playlists alcanzado` });
    }
    const pl = {
      id: uid(),
      name: name.substring(0, 40),
      ytId,
      added: Date.now()
    };
    await pool.query(
      'INSERT INTO playlists (id, account_number, name, yt_id, added) VALUES ($1, $2, $3, $4, $5)',
      [pl.id, req.accountNumber, pl.name, pl.ytId, pl.added]
    );
    res.status(201).json(pl);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// DELETE /api/playlists/:id
app.delete('/api/playlists/:id', requireAccount, async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM playlists WHERE id = $1 AND account_number = $2',
      [req.params.id, req.accountNumber]
    );
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Playlist no encontrada' });
    }
    res.status(204).end();
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Stats Routes ──────────────────────────────────────────────

// POST /api/visit
app.post('/api/visit', async (req, res) => {
  try {
    const ip = req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.socket.remoteAddress || 'unknown';
    const userAgent = req.headers['user-agent'] || '';
    await pool.query('UPDATE stats SET value = value + 1 WHERE key = $1', ['total_visits']);
    await pool.query(
      'INSERT INTO visits (ip, user_agent, visited) VALUES ($1, $2, $3)',
      [ip, userAgent, Date.now()]
    );
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/stats
app.get('/api/stats', async (req, res) => {
  try {
    const totalRes = await pool.query("SELECT value FROM stats WHERE key = 'total_visits'");
    const launchedRes = await pool.query("SELECT value FROM stats WHERE key = 'launched'");
    const uniqueRes = await pool.query('SELECT COUNT(DISTINCT ip) AS c FROM visits');
    const today = new Date(); today.setHours(0, 0, 0, 0);
    const todayRes = await pool.query('SELECT COUNT(*) AS c FROM visits WHERE visited >= $1', [today.getTime()]);

    res.json({
      totalVisits: parseInt(totalRes.rows[0]?.value || 0),
      uniqueUsers: parseInt(uniqueRes.rows[0]?.c || 0),
      todayVisits: parseInt(todayRes.rows[0]?.c || 0),
      launchedAt: parseInt(launchedRes.rows[0]?.value || Date.now())
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Start ──────────────────────────────────────────────────────
const HOST = process.env.HOST || '0.0.0.0';

initDB()
  .then(() => {
    app.listen(PORT, HOST, () => {
      const displayHost = HOST === '0.0.0.0' ? 'localhost' : HOST;
      console.log(`NEOVOX YT-V servidor en http://${displayHost}:${PORT}`);
      console.log(`PostgreSQL conectado · Escuchando en ${HOST}:${PORT}`);
    });
  })
  .catch(err => {
    console.error('Error inicializando DB:', err);
    process.exit(1);
  });
