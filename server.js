// server.js
const express = require('express');
const fs = require('fs');
const path = require('path');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const bcrypt = require('bcryptjs'); // supporte comparaison si hashes bcrypt

const app = express();
app.use(helmet());
app.use(express.json());

// rate limiter: 5 tentatives par IP toutes les 15 minutes
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { status: 'error', message: 'Trop de tentatives, réessayez plus tard.' }
});

// helper to load users.json (synchronously - ok pour petit test local)
function loadUsers() {
  const file = path.join(__dirname, 'users.json');
  if (!fs.existsSync(file)) return [];
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch (err) {
    console.error('Erreur lecture users.json:', err);
    return [];
  }
}

// POST /api/login
app.post('/api/login', loginLimiter, (req, res) => {
  const { username, password } = req.body || {};
  if (!username || !password) {
    return res.status(400).json({ status: 'error', message: 'username and password required' });
  }

  const users = loadUsers();
  // find user by username
  const user = users.find(u => u.username === username);
  if (!user) {
    // do not reveal which one doesn't exist
    return res.status(401).json({ status: 'error', message: 'Invalid credentials' });
  }

  const stored = user.password ?? '';

  // If stored looks like bcrypt (starts with $2), compare with bcrypt
  if (stored.startsWith('$2')) {
    if (bcrypt.compareSync(password, stored)) {
      return res.json({ status: 'ok', user: username });
    } else {
      return res.status(401).json({ status: 'error', message: 'Invalid credentials' });
    }
  }

  // Otherwise plain-text comparison (only for local/testing)
  if (password === stored) {
    return res.json({ status: 'ok', user: username });
  } else {
    return res.status(401).json({ status: 'error', message: 'Invalid credentials' });
  }
});

// optional: serve static files (index.html, users.json served static) — useful for your frontend
app.use(express.static(path.join(__dirname)));

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => console.log(`Server listening on http://127.0.0.1:${PORT}`));
