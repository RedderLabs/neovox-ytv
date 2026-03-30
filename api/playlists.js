const { Router } = require('express');
const { uid, requireAccount } = require('./helpers');

const MAX_PLAYLISTS = 20;

module.exports = function playlistRoutes(pool) {
  const router = Router();

  // GET /api/playlists
  router.get('/', requireAccount, async (req, res) => {
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
  router.post('/', requireAccount, async (req, res) => {
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
  router.delete('/:id', requireAccount, async (req, res) => {
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

  return router;
};
