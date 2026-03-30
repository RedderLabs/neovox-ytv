function uid() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
}

function generateAccountNumber() {
  let num = '';
  for (let i = 0; i < 16; i++) num += Math.floor(Math.random() * 10);
  return num;
}

function requireAccount(req, res, next) {
  const account = req.headers['x-account-number'];
  if (!account || !/^\d{16}$/.test(account)) {
    return res.status(401).json({ error: 'Cuenta requerida' });
  }
  req.accountNumber = account;
  next();
}

module.exports = { uid, generateAccountNumber, requireAccount };
