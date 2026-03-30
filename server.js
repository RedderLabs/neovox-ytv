require('dotenv').config();
const express = require('express');
const path = require('path');
const { Pool } = require('pg');

const accountRoutes = require('./api/account');
const playlistRoutes = require('./api/playlists');
const statsRoutes = require('./api/stats');
const audioProxyRoutes = require('./api/audio-proxy');
const searchRoutes = require('./api/search');

const app = express();
const PORT = process.env.PORT || 3000;

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

// ── Rutas API ─────────────────────────────────────────────────
app.use('/api/account', accountRoutes(pool));
app.use('/api/playlists', playlistRoutes(pool));
app.use('/api', statsRoutes(pool));
app.use('/api', audioProxyRoutes());
app.use('/api', searchRoutes());

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
