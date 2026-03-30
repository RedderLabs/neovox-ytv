const { Router } = require('express');

module.exports = function statsRoutes(pool) {
  const router = Router();

  // POST /api/visit
  router.post('/visit', async (req, res) => {
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
  router.get('/stats', async (req, res) => {
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

  return router;
};
