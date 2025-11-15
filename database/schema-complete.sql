-- ==============================================
-- SCHÉMA COMPLET - Crypto Portfolio Multi-Users
-- ==============================================

-- Table des utilisateurs (déjà existante, on la garde)
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Table des wallets
CREATE TABLE IF NOT EXISTS wallets (
    wallet_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    wallet_name VARCHAR(255) NOT NULL,
    wallet_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_wallet_per_user UNIQUE(user_id, wallet_name)
);

-- Table des holdings (coins dans les wallets)
CREATE TABLE IF NOT EXISTS holdings (
    holding_id SERIAL PRIMARY KEY,
    wallet_id INTEGER NOT NULL REFERENCES wallets(wallet_id) ON DELETE CASCADE,
    coin_symbol VARCHAR(20) NOT NULL,
    amount DECIMAL(30, 18) NOT NULL,
    network VARCHAR(50) DEFAULT 'default',
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_coin_per_wallet UNIQUE(wallet_id, coin_symbol, network)
);

-- Table des prix crypto (cache)
CREATE TABLE IF NOT EXISTS crypto_prices (
    price_id SERIAL PRIMARY KEY,
    coin_symbol VARCHAR(20) UNIQUE NOT NULL,
    price_usd DECIMAL(20, 8) NOT NULL,
    price_eur DECIMAL(20, 8),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source VARCHAR(50)
);

-- Table des transactions (historique optionnel)
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id SERIAL PRIMARY KEY,
    wallet_id INTEGER NOT NULL REFERENCES wallets(wallet_id) ON DELETE CASCADE,
    coin_symbol VARCHAR(20) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    amount DECIMAL(30, 18) NOT NULL,
    price_at_time DECIMAL(20, 8),
    network VARCHAR(50),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Index pour les performances
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_holdings_wallet_id ON holdings(wallet_id);
CREATE INDEX IF NOT EXISTS idx_holdings_coin_symbol ON holdings(coin_symbol);
CREATE INDEX IF NOT EXISTS idx_transactions_wallet_id ON transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_crypto_prices_symbol ON crypto_prices(coin_symbol);

-- Vue pour le portfolio complet d'un utilisateur
CREATE OR REPLACE VIEW user_portfolio_summary AS
SELECT 
    u.user_id,
    u.email,
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
    (h.amount * COALESCE(cp.price_eur, 0)) as value_eur,
    h.last_updated
FROM users u
LEFT JOIN wallets w ON u.user_id = w.user_id
LEFT JOIN holdings h ON w.wallet_id = h.wallet_id
LEFT JOIN crypto_prices cp ON h.coin_symbol = cp.coin_symbol;

-- Vue pour les totaux par utilisateur
CREATE OR REPLACE VIEW user_total_value AS
SELECT 
    user_id,
    email,
    COUNT(DISTINCT wallet_id) as wallet_count,
    COUNT(DISTINCT coin_symbol) as coin_count,
    SUM(value_usd) as total_usd,
    SUM(value_eur) as total_eur
FROM user_portfolio_summary
WHERE wallet_id IS NOT NULL
GROUP BY user_id, email;

-- Fonction pour mettre à jour automatiquement last_updated
CREATE OR REPLACE FUNCTION update_last_updated()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers pour last_updated
DROP TRIGGER IF EXISTS holdings_update_timestamp ON holdings;
CREATE TRIGGER holdings_update_timestamp
    BEFORE UPDATE ON holdings
    FOR EACH ROW
    EXECUTE FUNCTION update_last_updated();

DROP TRIGGER IF EXISTS prices_update_timestamp ON crypto_prices;
CREATE TRIGGER prices_update_timestamp
    BEFORE UPDATE ON crypto_prices
    FOR EACH ROW
    EXECUTE FUNCTION update_last_updated();

-- Données de test pour les prix (optionnel)
INSERT INTO crypto_prices (coin_symbol, price_usd, price_eur, source) VALUES
    ('BTC', 110965.07, 101800.00, 'manual'),
    ('ETH', 3881.33, 3560.00, 'manual'),
    ('USDC', 1.00, 0.92, 'manual'),
    ('PAXG', 4000.35, 3670.00, 'manual'),
    ('POL', 0.50, 0.46, 'manual')
ON CONFLICT (coin_symbol) DO NOTHING;

-- Afficher un récapitulatif
SELECT 'Tables créées avec succès' as status;
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
