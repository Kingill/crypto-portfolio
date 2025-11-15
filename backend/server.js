require('dotenv').config();
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET;

console.log('🔧 Configuration:');
console.log('  - JWT_SECRET:', JWT_SECRET ? '✅ Configuré' : '❌ Manquant');
console.log('  - DB_HOST:', process.env.DB_HOST);
console.log('  - DB_NAME:', process.env.DB_NAME);

if (!JWT_SECRET) {
  console.error('❌ JWT_SECRET non défini');
  process.exit(1);
}

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

pool.connect((err, client, release) => {
  if (err) {
    console.error('❌ Erreur PostgreSQL:', err.stack);
    process.exit(1);
  }
  console.log('✅ Connecté à PostgreSQL');
  release();
});

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Middleware d'authentification
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Token manquant' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Token invalide' });
    }
    req.user = user;
    next();
  });
};

// Middleware pour Node-RED
const authenticateInternal = (req, res, next) => {
  const internalKey = req.headers['x-internal-key'];
  
  if (internalKey !== process.env.INTERNAL_API_KEY) {
    return res.status(403).json({ error: 'Accès interdit' });
  }
  next();
};

// ============================================
// HEALTH CHECK
// ============================================
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ 
      status: 'healthy', 
      database: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(503).json({ 
      status: 'unhealthy', 
      database: 'disconnected',
      error: err.message 
    });
  }
});

// ============================================
// AUTHENTIFICATION
// ============================================

// Inscription
app.post('/api/auth/register', async (req, res) => {
  try {
    console.log('📝 Tentative d\'inscription:', req.body.email);
    
    const { email, password, name } = req.body;

    if (!email || !password) {
      console.log('❌ Email ou mot de passe manquant');
      return res.status(400).json({ error: 'Email et mot de passe requis' });
    }

    if (password.length < 6) {
      console.log('❌ Mot de passe trop court');
      return res.status(400).json({ error: 'Le mot de passe doit contenir au moins 6 caractères' });
    }

    const existingUser = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [email.toLowerCase()]
    );

    if (existingUser.rows.length > 0) {
      console.log('❌ Email déjà utilisé');
      return res.status(409).json({ error: 'Cet email est déjà utilisé' });
    }

    console.log('🔐 Hachage du mot de passe...');
    const hashedPassword = await bcrypt.hash(password, 10);

    console.log('💾 Création de l\'utilisateur dans la DB...');
    const result = await pool.query(
      'INSERT INTO users (email, password_hash, name, created_at) VALUES ($1, $2, $3, NOW()) RETURNING user_id, email, name',
      [email.toLowerCase(), hashedPassword, name]
    );

    const user = result.rows[0];

    console.log('🎫 Génération du token JWT...');
    const token = jwt.sign(
      { user_id: user.user_id, email: user.email },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    console.log('✅ Utilisateur créé avec succès:', user.email);

    res.status(201).json({
      message: 'Utilisateur créé avec succès',
      token,
      user: {
        id: user.user_id,
        email: user.email,
        name: user.name
      }
    });
  } catch (error) {
    console.error('❌ Erreur inscription:', error);
    res.status(500).json({ error: 'Erreur serveur', details: error.message });
  }
});

// Connexion
app.post('/api/auth/login', async (req, res) => {
  try {
    console.log('🔑 Tentative de connexion:', req.body.email);
    
    const { email, password } = req.body;

    if (!email || !password) {
      console.log('❌ Email ou mot de passe manquant');
      return res.status(400).json({ error: 'Email et mot de passe requis' });
    }

    console.log('🔍 Recherche de l\'utilisateur...');
    const result = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [email.toLowerCase()]
    );

    if (result.rows.length === 0) {
      console.log('❌ Utilisateur non trouvé');
      return res.status(401).json({ error: 'Email ou mot de passe incorrect' });
    }

    const user = result.rows[0];

    console.log('🔐 Vérification du mot de passe...');
    const validPassword = await bcrypt.compare(password, user.password_hash);

    if (!validPassword) {
      console.log('❌ Mot de passe incorrect');
      return res.status(401).json({ error: 'Email ou mot de passe incorrect' });
    }

    await pool.query(
      'UPDATE users SET last_login = NOW() WHERE user_id = $1',
      [user.user_id]
    );

    console.log('🎫 Génération du token JWT...');
    const token = jwt.sign(
      { user_id: user.user_id, email: user.email },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    console.log('✅ Connexion réussie:', user.email);

    res.json({
      message: 'Connexion réussie',
      token,
      user: {
        id: user.user_id,
        email: user.email,
        name: user.name
      }
    });
  } catch (error) {
    console.error('❌ Erreur connexion:', error);
    res.status(500).json({ error: 'Erreur serveur', details: error.message });
  }
});

// Info utilisateur
app.get('/api/auth/me', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT user_id, email, name, created_at, last_login FROM users WHERE user_id = $1',
      [req.user.user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('❌ Erreur:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ============================================
// WALLETS
// ============================================

app.get('/api/wallets', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM wallets WHERE user_id = $1 ORDER BY created_at DESC',
      [req.user.user_id]
    );

    console.log(`✅ ${result.rows.length} wallets récupérés pour user ${req.user.email}`);
    res.json(result.rows);
  } catch (error) {
    console.error('❌ Erreur récupération wallets:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

app.post('/api/wallets', authenticateToken, async (req, res) => {
  try {
    const { name, type } = req.body;

    if (!name || !type) {
      return res.status(400).json({ error: 'Nom et type requis' });
    }

    const result = await pool.query(
      'INSERT INTO wallets (user_id, wallet_name, wallet_type, created_at) VALUES ($1, $2, $3, NOW()) RETURNING *',
      [req.user.user_id, name, type]
    );

    console.log(`✅ Wallet créé: ${name} (${type})`);
    res.status(201).json(result.rows[0]);
  } catch (error) {
    if (error.code === '23505') {
      return res.status(409).json({ error: 'Un wallet avec ce nom existe déjà' });
    }
    console.error('❌ Erreur création wallet:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

app.delete('/api/wallets/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const checkResult = await pool.query(
      'SELECT * FROM wallets WHERE wallet_id = $1 AND user_id = $2',
      [id, req.user.user_id]
    );

    if (checkResult.rows.length === 0) {
      return res.status(404).json({ error: 'Wallet non trouvé' });
    }

    await pool.query('DELETE FROM wallets WHERE wallet_id = $1', [id]);

    console.log(`✅ Wallet supprimé: ${id}`);
    res.json({ message: 'Wallet supprimé avec succès' });
  } catch (error) {
    console.error('❌ Erreur suppression wallet:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ============================================
// HOLDINGS
// ============================================

app.get('/api/wallets/:id/holdings', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const walletCheck = await pool.query(
      'SELECT * FROM wallets WHERE wallet_id = $1 AND user_id = $2',
      [id, req.user.user_id]
    );

    if (walletCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Wallet non trouvé' });
    }

    const result = await pool.query(
      `SELECT h.*, cp.price_usd, cp.price_eur,
              (h.amount * COALESCE(cp.price_usd, 0)) as value_usd,
              (h.amount * COALESCE(cp.price_eur, 0)) as value_eur
       FROM holdings h
       LEFT JOIN crypto_prices cp ON h.coin_symbol = cp.coin_symbol
       WHERE h.wallet_id = $1 
       ORDER BY h.coin_symbol`,
      [id]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('❌ Erreur récupération holdings:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

app.post('/api/wallets/:id/holdings', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { coin_symbol, amount, network } = req.body;

    if (!coin_symbol || amount === undefined) {
      return res.status(400).json({ error: 'Symbole et montant requis' });
    }

    if (amount < 0) {
      return res.status(400).json({ error: 'Le montant ne peut pas être négatif' });
    }

    const walletCheck = await pool.query(
      'SELECT * FROM wallets WHERE wallet_id = $1 AND user_id = $2',
      [id, req.user.user_id]
    );

    if (walletCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Wallet non trouvé' });
    }

    const existingHolding = await pool.query(
      'SELECT * FROM holdings WHERE wallet_id = $1 AND coin_symbol = $2 AND network = $3',
      [id, coin_symbol.toUpperCase(), network || 'default']
    );

    let result;
    if (existingHolding.rows.length > 0) {
      result = await pool.query(
        'UPDATE holdings SET amount = $1, last_updated = NOW() WHERE holding_id = $2 RETURNING *',
        [amount, existingHolding.rows[0].holding_id]
      );
      console.log(`✅ Holding mis à jour: ${coin_symbol} - ${amount}`);
    } else {
      result = await pool.query(
        'INSERT INTO holdings (wallet_id, coin_symbol, amount, network, last_updated) VALUES ($1, $2, $3, $4, NOW()) RETURNING *',
        [id, coin_symbol.toUpperCase(), amount, network || 'default']
      );
      console.log(`✅ Holding ajouté: ${coin_symbol} - ${amount}`);
    }

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('❌ Erreur ajout holding:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

app.delete('/api/wallets/:walletId/holdings/:holdingId', authenticateToken, async (req, res) => {
  try {
    const { walletId, holdingId } = req.params;

    const walletCheck = await pool.query(
      'SELECT * FROM wallets WHERE wallet_id = $1 AND user_id = $2',
      [walletId, req.user.user_id]
    );

    if (walletCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Wallet non trouvé' });
    }

    await pool.query(
      'DELETE FROM holdings WHERE holding_id = $1 AND wallet_id = $2',
      [holdingId, walletId]
    );

    console.log(`✅ Holding supprimé: ${holdingId}`);
    res.json({ message: 'Holding supprimé avec succès' });
  } catch (error) {
    console.error('❌ Erreur suppression holding:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ============================================
// PORTFOLIO & PRIX
// ============================================

app.get('/api/prices', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM crypto_prices ORDER BY coin_symbol'
    );
    res.json(result.rows);
  } catch (error) {
    console.error('❌ Erreur récupération prix:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

app.get('/api/portfolio', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT 
        w.wallet_id,
        w.wallet_name,
        w.wallet_type,
        h.holding_id,
        h.coin_symbol,
        h.amount,
        h.network,
        cp.price_usd,
        cp.price_eur,
        (h.amount * COALESCE(cp.price_usd, 0)) as value_usd,
        (h.amount * COALESCE(cp.price_eur, 0)) as value_eur
       FROM wallets w
       LEFT JOIN holdings h ON w.wallet_id = h.wallet_id
       LEFT JOIN crypto_prices cp ON h.coin_symbol = cp.coin_symbol
       WHERE w.user_id = $1
       ORDER BY w.wallet_name, h.coin_symbol`,
      [req.user.user_id]
    );

    let totalUSD = 0;
    let totalEUR = 0;
    result.rows.forEach(row => {
      if (row.value_usd) totalUSD += parseFloat(row.value_usd);
      if (row.value_eur) totalEUR += parseFloat(row.value_eur);
    });

    res.json({
      holdings: result.rows,
      totals: {
        usd: totalUSD.toFixed(2),
        eur: totalEUR.toFixed(2)
      }
    });
  } catch (error) {
    console.error('❌ Erreur récupération portfolio:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ============================================
// ROUTES INTERNES (Node-RED)
// ============================================

app.get('/api/internal/all-holdings', authenticateInternal, async (req, res) => {
  try {
    const result = await pool.query('SELECT DISTINCT coin_symbol FROM holdings');
    res.json(result.rows);
  } catch (error) {
    console.error('❌ Erreur:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

app.get('/api/internal/prices', authenticateInternal, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM crypto_prices ORDER BY last_updated DESC');
    res.json(result.rows);
  } catch (error) {
    console.error('❌ Erreur:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ============================================
// ERROR HANDLERS
// ============================================

app.use((req, res) => {
  res.status(404).json({ error: 'Route non trouvée' });
});

app.use((err, req, res, next) => {
  console.error('❌ Erreur serveur:', err);
  res.status(500).json({ error: 'Erreur serveur interne' });
});

// ============================================
// DÉMARRAGE
// ============================================

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log('='.repeat(60));
  console.log('🚀 SERVEUR API CRYPTO PORTFOLIO');
  console.log('='.repeat(60));
  console.log(`📍 Port: ${PORT}`);
  console.log(`🗄️  Database: ${process.env.DB_HOST}:${process.env.DB_PORT}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log('');
  console.log('📋 Routes disponibles:');
  console.log('  AUTH:');
  console.log('    POST /api/auth/register');
  console.log('    POST /api/auth/login');
  console.log('    GET  /api/auth/me');
  console.log('  WALLETS:');
  console.log('    GET    /api/wallets');
  console.log('    POST   /api/wallets');
  console.log('    DELETE /api/wallets/:id');
  console.log('  HOLDINGS:');
  console.log('    GET    /api/wallets/:id/holdings');
  console.log('    POST   /api/wallets/:id/holdings');
  console.log('    DELETE /api/wallets/:id/holdings/:id');
  console.log('  PORTFOLIO:');
  console.log('    GET /api/portfolio');
  console.log('    GET /api/prices');
  console.log('='.repeat(60));
});

process.on('SIGTERM', () => {
  console.log('📴 Signal SIGTERM reçu, arrêt gracieux...');
  server.close(() => {
    console.log('✅ Serveur HTTP fermé');
    pool.end(() => {
      console.log('✅ Pool PostgreSQL fermé');
      process.exit(0);
    });
  });
});

module.exports = app;
