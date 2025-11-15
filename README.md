# 📚 Documentation Complète - Crypto Portfolio Multi-Users

**Version :** 1.0  
**Date :** Novembre 2025  
**Auteur :** Gilles

## 📋 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture](#architecture)
3. [Prérequis](#prérequis)
4. [Installation complète](#installation-complète)
5. [Configuration](#configuration)
6. [Utilisation](#utilisation)
7. [Maintenance](#maintenance)
8. [Dépannage](#dépannage)
9. [Sauvegarde et restauration](#sauvegarde-et-restauration)

---

## 🎯 Vue d'ensemble

Application web multi-utilisateurs pour gérer des portefeuilles de cryptomonnaies avec :
- Authentification JWT sécurisée
- Gestion de wallets et holdings multiples
- Mise à jour automatique des prix via CoinGecko API
- Dashboard temps réel
- Architecture Docker complète

### Technologies utilisées
- **Backend :** Node.js + Express
- **Base de données :** PostgreSQL 16
- **Orchestration :** Node-RED
- **Frontend :** HTML/CSS/JavaScript vanilla
- **Infrastructure :** Docker + Docker Compose

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│              Frontend (Dashboard)               │
│           http://localhost:3000                 │
└───────────────────┬─────────────────────────────┘
                    │ API REST (JWT)
┌───────────────────▼─────────────────────────────┐
│          Express API Backend                    │
│           Port 3000                             │
│  Routes: /api/auth, /api/wallets,              │
│          /api/holdings, /api/portfolio          │
└───────────────────┬─────────────────────────────┘
                    │ SQL Queries
┌───────────────────▼─────────────────────────────┐
│          PostgreSQL Database                    │
│           Port 5432                             │
│  Tables: users, wallets, holdings,              │
│          crypto_prices, transactions            │
└───────────────────▲─────────────────────────────┘
                    │ Price Updates
┌───────────────────┴─────────────────────────────┐
│            Node-RED Orchestrator                │
│           http://localhost:1880                 │
│  Job: Fetch prices every 5 min from CoinGecko  │
└─────────────────────────────────────────────────┘
```

---

## 💻 Prérequis

- **OS :** Linux (Ubuntu 20.04+, Debian 11+) ou macOS
- **Docker :** 20.10+
- **Docker Compose :** 2.0+
- **Mémoire :** 2GB RAM minimum
- **Disque :** 5GB disponible

### Installation des prérequis

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose git curl -y
sudo usermod -aG docker $USER
# Se déconnecter/reconnecter pour que le groupe prenne effet

# Vérification
docker --version
docker-compose --version
```

---

## 🚀 Installation complète

### Étape 1 : Créer la structure du projet

```bash
# Créer le répertoire principal
mkdir -p ~/crypto-portfolio
cd ~/crypto-portfolio

# Créer la structure
mkdir -p backend/public database nodered
```

### Étape 2 : Créer docker-compose.yml

```yaml
services:
  postgres:
    image: postgres:16-alpine
    container_name: crypto-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: crypto_portfolio
      POSTGRES_USER: crypto_user
      POSTGRES_PASSWORD: ${DB_PASSWORD:-changeme}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/schema.sql:/docker-entrypoint-initdb.d/01-schema.sql
    ports:
      - "5432:5432"
    networks:
      - crypto-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U crypto_user -d crypto_portfolio"]
      interval: 5s
      timeout: 3s
      retries: 5

  api:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: crypto-api
    restart: unless-stopped
    environment:
      NODE_ENV: production
      PORT: 3000
      JWT_SECRET: ${JWT_SECRET:-changeme}
      DB_USER: crypto_user
      DB_HOST: postgres
      DB_NAME: crypto_portfolio
      DB_PASSWORD: ${DB_PASSWORD:-changeme}
      DB_PORT: 5432
      INTERNAL_API_KEY: ${INTERNAL_API_KEY:-changeme}
    ports:
      - "3000:3000"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - crypto-network
    volumes:
      - ./backend:/app
      - /app/node_modules

  nodered:
    image: nodered/node-red:latest
    container_name: crypto-nodered
    restart: unless-stopped
    environment:
      - TZ=Europe/Paris
      - DB_USER=crypto_user
      - DB_HOST=postgres
      - DB_NAME=crypto_portfolio
      - DB_PASSWORD=${DB_PASSWORD:-changeme}
      - DB_PORT=5432
    ports:
      - "1880:1880"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - crypto-network
    volumes:
      - nodered_data:/data

networks:
  crypto-network:
    driver: bridge

volumes:
  postgres_data:
    driver: local
  nodered_data:
    driver: local
```

### Étape 3 : Créer le fichier .env

```bash
cat > .env << 'EOF'
# SÉCURITÉ - CHANGER EN PRODUCTION !
JWT_SECRET=votre_secret_jwt_a_generer_avec_32_caracteres_minimum
DB_PASSWORD=votre_mot_de_passe_postgres_securise
INTERNAL_API_KEY=cle_interne_pour_nodered
EOF

# Générer un secret JWT fort
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
# Copier le résultat dans JWT_SECRET
```

### Étape 4 : Créer le schéma de base de données

Créer `database/schema.sql` :

```sql
-- Table users
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Table wallets
CREATE TABLE IF NOT EXISTS wallets (
    wallet_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    wallet_name VARCHAR(255) NOT NULL,
    wallet_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_wallet_per_user UNIQUE(user_id, wallet_name)
);

-- Table holdings
CREATE TABLE IF NOT EXISTS holdings (
    holding_id SERIAL PRIMARY KEY,
    wallet_id INTEGER NOT NULL REFERENCES wallets(wallet_id) ON DELETE CASCADE,
    coin_symbol VARCHAR(20) NOT NULL,
    amount DECIMAL(30, 18) NOT NULL,
    network VARCHAR(50) DEFAULT 'default',
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_coin_per_wallet UNIQUE(wallet_id, coin_symbol, network)
);

-- Table crypto_prices
CREATE TABLE IF NOT EXISTS crypto_prices (
    price_id SERIAL PRIMARY KEY,
    coin_symbol VARCHAR(20) UNIQUE NOT NULL,
    price_usd DECIMAL(20, 8) NOT NULL,
    price_eur DECIMAL(20, 8),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source VARCHAR(50)
);

-- Table transactions (historique optionnel)
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

-- Index
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_holdings_wallet_id ON holdings(wallet_id);
CREATE INDEX IF NOT EXISTS idx_holdings_coin_symbol ON holdings(coin_symbol);
CREATE INDEX IF NOT EXISTS idx_transactions_wallet_id ON transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_crypto_prices_symbol ON crypto_prices(coin_symbol);

-- Trigger pour auto-update
CREATE OR REPLACE FUNCTION update_last_updated()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER holdings_update_timestamp
    BEFORE UPDATE ON holdings
    FOR EACH ROW
    EXECUTE FUNCTION update_last_updated();

CREATE TRIGGER prices_update_timestamp
    BEFORE UPDATE ON crypto_prices
    FOR EACH ROW
    EXECUTE FUNCTION update_last_updated();

-- Prix initiaux (optionnel)
INSERT INTO crypto_prices (coin_symbol, price_usd, price_eur, source) VALUES
    ('BTC', 67000.00, 61500.00, 'manual'),
    ('ETH', 3800.00, 3490.00, 'manual'),
    ('USDC', 1.00, 0.92, 'manual')
ON CONFLICT (coin_symbol) DO NOTHING;
```

### Étape 5 : Backend - Dockerfile

Créer `backend/Dockerfile` :

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### Étape 6 : Backend - package.json

Créer `backend/package.json` :

```json
{
  "name": "crypto-portfolio-api",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "jsonwebtoken": "^9.0.2",
    "bcrypt": "^5.1.1",
    "pg": "^8.11.3",
    "dotenv": "^16.3.1"
  }
}
```

### Étape 7 : Backend - server.js

**📌 IMPORTANT :** Le fichier server.js complet est trop long pour ce document.

Récupérez-le depuis l'artifact **"server_updated"** que j'ai créé plus tôt dans cette conversation.

Il doit contenir TOUTES les routes :
- POST `/api/auth/register`
- POST `/api/auth/login`
- GET `/api/auth/me`
- GET/POST/DELETE `/api/wallets`
- GET/POST/DELETE `/api/wallets/:id/holdings`
- GET `/api/portfolio`
- GET `/api/prices`

### Étape 8 : Frontend - index.html (page de login)

Créer `backend/public/index.html` avec redirection vers dashboard après login.

**📌 Récupérez le contenu** depuis l'artifact **"frontend_html"** (modifié avec redirection).

### Étape 9 : Frontend - dashboard.html

Créer `backend/public/dashboard.html`

**📌 Récupérez le contenu** depuis l'artifact **"dashboard_fixed"** (sans auto-refresh).

### Étape 10 : Démarrer l'application

```bash
cd ~/crypto-portfolio

# Build et démarrage
docker-compose up -d

# Vérifier les logs
docker-compose logs -f

# Vérifier les containers
docker-compose ps
```

Vous devriez voir :
```
NAME              STATUS
crypto-postgres   Up (healthy)
crypto-api        Up
crypto-nodered    Up
```

### Étape 11 : Configurer Node-RED pour les prix

1. Ouvrir **http://localhost:1880**
2. Menu (☰) → **"Manage palette"** → **"Install"**
3. Rechercher et installer : **`node-red-contrib-postgresql`**
4. Menu → **"Import"** → Coller le JSON du flow (voir section Node-RED ci-dessous)
5. Double-cliquer sur node **"Get Coins from DB"**
6. Éditer la config PostgreSQL :
   - Host: `postgres`
   - Port: `5432`
   - Database: `crypto_portfolio`
   - User: `crypto_user`
   - Password: (celui dans `.env`)
7. **Deploy**

### Flow Node-RED complet

**📌 IMPORTANT :** Conservez ce JSON pour réimporter le flow :

```json
[Voir l'artifact "nodered_flows_complete" pour le JSON complet]
```

**Mapping CoinGecko dans le node "Prepare CoinGecko URL" :**

```javascript
const coinMapping = {
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'USDC': 'usd-coin',
    'USDT': 'tether',
    'PAXG': 'pax-gold',
    'POL': 'polygon-ecosystem-token',
    'MATIC': 'matic-network',
    'DOGE': 'dogecoin',
    'KASPA': 'kaspa',
    'SOL': 'solana',
    'ONDO': 'ondo-finance',
    'ARBITRUM': 'arbitrum',
    'BNB': 'binancecoin',
    'XRP': 'ripple',
    'ADA': 'cardano',
    'AVAX': 'avalanche-2',
    'DOT': 'polkadot',
    'LINK': 'chainlink',
    'UNI': 'uniswap',
    'ATOM': 'cosmos',
    'LTC': 'litecoin',
    'DAI': 'dai',
    'SHIB': 'shiba-inu',
    'TRX': 'tron',
    'WBTC': 'wrapped-bitcoin'
};
```

---

## ⚙️ Configuration

### Ports utilisés

| Service | Port | URL |
|---------|------|-----|
| Frontend/API | 3000 | http://localhost:3000 |
| PostgreSQL | 5432 | localhost:5432 |
| Node-RED | 1880 | http://localhost:1880 |

### Variables d'environnement (.env)

```bash
JWT_SECRET=            # Secret pour JWT (32+ chars)
DB_PASSWORD=           # Mot de passe PostgreSQL
INTERNAL_API_KEY=      # Clé pour Node-RED
```

---

## 📖 Utilisation

### Première connexion

1. Ouvrir **http://localhost:3000**
2. Créer un compte (inscription)
3. Se connecter → Redirection automatique vers dashboard

### Créer un wallet

1. Dans le dashboard, section "Ajouter un Wallet"
2. Nom : `Mon Wallet`
3. Type : `MetaMask`, `TG`, `BR`, etc.
4. Cliquer "Créer"

### Ajouter des coins

1. Dans un wallet, formulaire en bas
2. Symbole : `BTC`, `ETH`, etc. (majuscules)
3. Montant : `0.5`
4. Network : `Ethereum`, `Polygon`, etc. (optionnel)
5. Cliquer "Ajouter coin"

### Mise à jour des prix

- **Automatique :** Toutes les 5 minutes via Node-RED
- **Manuel :** Cliquer sur "🔄 Actualiser" dans le dashboard
- **Node-RED :** Trigger manuel dans l'interface

---

## 🔧 Maintenance

### Commandes Docker utiles

```bash
# Voir les logs
docker-compose logs -f
docker-compose logs -f api
docker-compose logs -f nodered

# Redémarrer un service
docker-compose restart api
docker-compose restart nodered

# Arrêter tout
docker-compose down

# Redémarrer tout
docker-compose up -d

# Voir l'état
docker-compose ps
```

### Base de données

```bash
# Se connecter à PostgreSQL
docker exec -it crypto-postgres psql -U crypto_user crypto_portfolio

# Commandes SQL utiles
\dt                          # Liste des tables
\d users                     # Structure d'une table
SELECT * FROM users;         # Voir les utilisateurs
SELECT * FROM crypto_prices; # Voir les prix

# Quitter
\q
```

### Sauvegarder la base de données

```bash
# Backup complet
docker exec crypto-postgres pg_dump -U crypto_user crypto_portfolio > backup_$(date +%Y%m%d).sql

# Backup avec compression
docker exec crypto-postgres pg_dump -U crypto_user crypto_portfolio | gzip > backup_$(date +%Y%m%d).sql.gz
```

### Restaurer une sauvegarde

```bash
# Restaurer depuis un backup
cat backup_20251102.sql | docker exec -i crypto-postgres psql -U crypto_user crypto_portfolio

# Ou depuis backup compressé
gunzip -c backup_20251102.sql.gz | docker exec -i crypto-postgres psql -U crypto_user crypto_portfolio
```

---

## 🐛 Dépannage

### L'API ne démarre pas

```bash
# Vérifier les logs
docker-compose logs api

# Problème JWT_SECRET manquant
# → Vérifier le .env

# Erreur de connexion DB
# → Attendre que postgres soit "healthy"
docker-compose ps
```

### Node-RED ne met pas à jour les prix

```bash
# Vérifier les logs
docker-compose logs nodered

# Tester manuellement dans Node-RED
# → http://localhost:1880
# → Cliquer sur le trigger manuel
# → Regarder le panneau Debug

# Problème de connexion PostgreSQL
# → Vérifier la config du node PostgreSQL
# → Host=postgres, User=crypto_user, etc.
```

### Dashboard ne charge pas

```bash
# Vérifier que l'API tourne
curl http://localhost:3000/health

# Vérifier le token dans localStorage
# → F12 → Console → localStorage.getItem('token')

# Problème de CORS
# → Vérifier que cors() est activé dans server.js
```

### Problème de ports déjà utilisés

```bash
# Trouver ce qui utilise un port
sudo lsof -i :3000
sudo lsof -i :1880

# Tuer le processus
sudo kill <PID>

# Ou changer le port dans docker-compose.yml
```

---

## 💾 Sauvegarde et restauration

### Sauvegarde complète du projet

```bash
#!/bin/bash
# Script: backup-all.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups/$DATE"

mkdir -p $BACKUP_DIR

# 1. Backup de la base de données
docker exec crypto-postgres pg_dump -U crypto_user crypto_portfolio | gzip > $BACKUP_DIR/database.sql.gz

# 2. Backup des volumes Docker
docker run --rm -v crypto-portfolio_postgres_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/postgres_volume.tar.gz -C /data .
docker run --rm -v crypto-portfolio_nodered_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/nodered_volume.tar.gz -C /data .

# 3. Backup des fichiers de config
tar czf $BACKUP_DIR/config.tar.gz docker-compose.yml .env backend/ database/ nodered/

echo "✅ Backup complet dans: $BACKUP_DIR"
ls -lh $BACKUP_DIR
```

### Restauration complète

```bash
#!/bin/bash
# Script: restore-all.sh

BACKUP_DIR=$1

if [ -z "$BACKUP_DIR" ]; then
    echo "Usage: ./restore-all.sh ./backups/20251102_143000"
    exit 1
fi

# 1. Arrêter les services
docker-compose down -v

# 2. Restaurer les fichiers
tar xzf $BACKUP_DIR/config.tar.gz

# 3. Recréer les services
docker-compose up -d postgres
sleep 10

# 4. Restaurer la base de données
gunzip -c $BACKUP_DIR/database.sql.gz | docker exec -i crypto-postgres psql -U crypto_user crypto_portfolio

# 5. Redémarrer tout
docker-compose up -d

echo "✅ Restauration terminée"
```

---

## 📁 Structure finale du projet

```
crypto-portfolio/
├── docker-compose.yml
├── .env
├── .env.example
├── .gitignore
├── README.md
├── LICENSE
├── CONTRIBUTING.md
├── backup-all.sh
├── restore-all.sh
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   ├── server.js
│   └── public/              # Frontend statique servi par Express
│       ├── index.html
│       └── dashboard.html
├── frontend/                # Frontend (optionnel - si séparé)
│   ├── index.html
│   └── dashboard.html
├── database/
│   ├── schema.sql
│   └── backup_*.sql
├── nodered/
│   └── flows.json (exporté depuis Node-RED)
└── backups/
    └── [dates]/
```

**Note importante :** Dans votre cas, le frontend peut être :
- **Option 1 (recommandée) :** Dans `backend/public/` - servi directement par Express via `app.use(express.static('public'))`
- **Option 2 :** Dans un dossier `frontend/` séparé - nécessite un serveur web dédié (Nginx, etc.)

Pour cette installation, nous utilisons l'**Option 1** avec le frontend dans `backend/public/`.

---

## 🔐 Sécurité en production

### Checklist de sécurité

- [ ] Changer tous les secrets dans `.env`
- [ ] Utiliser des mots de passe forts (16+ caractères)
- [ ] Activer HTTPS avec Let's Encrypt
- [ ] Configurer un firewall (UFW)
- [ ] Limiter les tentatives de connexion
- [ ] Sauvegardes automatiques quotidiennes
- [ ] Monitoring et alertes
- [ ] Mettre à jour régulièrement les images Docker

### Générer des secrets forts

```bash
# JWT Secret
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Password DB
openssl rand -base64 32

# Internal API Key
openssl rand -base64 24
```

---

## 📞 Support et ressources

### Documentation externe

- **Docker :** https://docs.docker.com
- **PostgreSQL :** https://www.postgresql.org/docs/
- **Node-RED :** https://nodered.org/docs/
- **CoinGecko API :** https://www.coingecko.com/api/documentation

### Commandes de diagnostic

```bash
# Vérifier les containers
docker-compose ps
docker-compose logs -f

# Vérifier la santé
curl http://localhost:3000/health

# Vérifier PostgreSQL
docker exec -it crypto-postgres psql -U crypto_user -c "SELECT version();"

# Vérifier l'espace disque
df -h
docker system df
```

---

## ✅ Checklist d'installation

- [ ] Docker et Docker Compose installés
- [ ] Structure de projet créée
- [ ] Fichiers copiés (docker-compose.yml, .env, etc.)
- [ ] Secrets générés et configurés dans .env
- [ ] `docker-compose up -d` exécuté avec succès
- [ ] 3 containers en état "Up"
- [ ] Base de données accessible
- [ ] Node-RED accessible et node PostgreSQL installé
- [ ] Flow importé et déployé dans Node-RED
- [ ] Page de login accessible (http://localhost:3000)
- [ ] Inscription testée
- [ ] Dashboard fonctionnel
- [ ] Wallet créé avec succès
- [ ] Coin ajouté avec succès
- [ ] Prix mis à jour automatiquement
- [ ] Sauvegarde testée

---

**🎉 Félicitations ! Votre système est opérationnel !**

Pour toute question ou amélioration, consultez les logs et la section dépannage.
