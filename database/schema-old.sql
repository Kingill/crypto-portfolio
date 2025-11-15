cat > database/schema.sql << 'EOF'
-- Table users seulement pour le test
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Index
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
EOF
