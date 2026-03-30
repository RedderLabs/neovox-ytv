const { Router } = require('express');
const { generateAccountNumber } = require('./helpers');

module.exports = function accountRoutes(pool) {
  const router = Router();

  // POST /api/account/create — crear cuenta anonima
  router.post('/create', async (req, res) => {
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
  router.post('/login', async (req, res) => {
    try {
      const { accountNumber } = req.body;
      if (!accountNumber || !/^\d{16}$/.test(accountNumber)) {
        return res.status(400).json({ error: 'Numero de cuenta invalido (16 digitos)' });
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

  // DELETE /api/account — eliminar cuenta y sus playlists (cascade)
  router.delete('/', async (req, res) => {
    try {
      const account = req.headers['x-account-number'];
      if (!account || !/^\d{16}$/.test(account)) {
        return res.status(401).json({ error: 'Cuenta requerida' });
      }
      const result = await pool.query(
        'DELETE FROM accounts WHERE account_number = $1',
        [account]
      );
      if (result.rowCount === 0) {
        return res.status(404).json({ error: 'Cuenta no encontrada' });
      }
      res.status(204).end();
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  });

  return router;
};
