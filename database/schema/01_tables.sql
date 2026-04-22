-- STOCK EXCHANGE v2.0 — TABLES

CREATE TABLE sectors (
    sector_id   SERIAL PRIMARY KEY,
    sector_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE stocks (
    stock_id      SERIAL PRIMARY KEY,
    ticker        VARCHAR(10) UNIQUE NOT NULL,
    company_name  VARCHAR(100) NOT NULL,
    sector_id     INT REFERENCES sectors(sector_id) ON DELETE SET NULL,
    exchange      VARCHAR(10) DEFAULT 'NSE' CHECK (exchange IN ('NSE','BSE','NYSE','NASDAQ')),
    current_price NUMERIC(10,2) NOT NULL CHECK (current_price > 0),
    prev_close    NUMERIC(10,2),
    market_cap    NUMERIC(20,2),
    total_shares  BIGINT,
    is_active     BOOLEAN DEFAULT TRUE,
    listed_on     DATE DEFAULT CURRENT_DATE
);

CREATE TABLE users (
    user_id        SERIAL PRIMARY KEY,
    username       VARCHAR(50) UNIQUE NOT NULL,
    email          VARCHAR(100) UNIQUE NOT NULL,
    password_hash  VARCHAR(255) NOT NULL,
    wallet_balance NUMERIC(15,2) DEFAULT 100000.00 CHECK (wallet_balance >= 0),
    role           VARCHAR(10) DEFAULT 'trader' CHECK (role IN ('trader','broker','admin')),
    is_active      BOOLEAN DEFAULT TRUE,
    created_at     TIMESTAMP DEFAULT NOW()
);

CREATE TABLE price_history (
    history_id  SERIAL PRIMARY KEY,
    stock_id    INT REFERENCES stocks(stock_id) ON DELETE CASCADE,
    open_price  NUMERIC(10,2),
    high_price  NUMERIC(10,2),
    low_price   NUMERIC(10,2),
    close_price NUMERIC(10,2) NOT NULL,
    volume      BIGINT DEFAULT 0,
    recorded_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_price_history_stock_time
    ON price_history(stock_id, recorded_at DESC);

CREATE TABLE portfolio (
    holding_id    SERIAL PRIMARY KEY,
    user_id       INT REFERENCES users(user_id) ON DELETE CASCADE,
    stock_id      INT REFERENCES stocks(stock_id) ON DELETE CASCADE,
    quantity      INT NOT NULL CHECK (quantity >= 0),
    avg_buy_price NUMERIC(10,2) NOT NULL,
    UNIQUE (user_id, stock_id)
);

CREATE TABLE orders (
    order_id    SERIAL PRIMARY KEY,
    user_id     INT REFERENCES users(user_id) ON DELETE CASCADE,
    stock_id    INT REFERENCES stocks(stock_id) ON DELETE CASCADE,
    order_type  VARCHAR(4)  NOT NULL CHECK (order_type IN ('BUY','SELL')),
    order_mode  VARCHAR(10) NOT NULL DEFAULT 'MARKET'
                    CHECK (order_mode IN ('MARKET','LIMIT','STOP_LOSS')),
    quantity    INT NOT NULL CHECK (quantity > 0),
    limit_price NUMERIC(10,2),
    stop_price  NUMERIC(10,2),
    status      VARCHAR(10) DEFAULT 'PENDING'
                    CHECK (status IN ('PENDING','EXECUTED','CANCELLED','EXPIRED')),
    placed_at   TIMESTAMP DEFAULT NOW(),
    executed_at TIMESTAMP
);

CREATE TABLE transactions (
    txn_id         SERIAL PRIMARY KEY,
    order_id       INT REFERENCES orders(order_id),
    user_id        INT REFERENCES users(user_id),
    stock_id       INT REFERENCES stocks(stock_id),
    txn_type       VARCHAR(4) NOT NULL CHECK (txn_type IN ('BUY','SELL')),
    quantity       INT NOT NULL CHECK (quantity > 0),
    price_per_unit NUMERIC(10,2) NOT NULL,
    total_amount   NUMERIC(15,2) GENERATED ALWAYS AS (quantity * price_per_unit) STORED,
    brokerage_fee  NUMERIC(8,2) DEFAULT 0.00,
    net_amount     NUMERIC(15,2) NOT NULL,
    executed_at    TIMESTAMP DEFAULT NOW()
);

CREATE TABLE watchlist (
    watchlist_id SERIAL PRIMARY KEY,
    user_id      INT REFERENCES users(user_id) ON DELETE CASCADE,
    stock_id     INT REFERENCES stocks(stock_id) ON DELETE CASCADE,
    alert_price  NUMERIC(10,2),
    added_at     TIMESTAMP DEFAULT NOW(),
    UNIQUE (user_id, stock_id)
);

CREATE TABLE instruments (
    instrument_id SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    type          VARCHAR(20) NOT NULL
                      CHECK (type IN ('MUTUAL_FUND','BOND','COMMODITY','ETF')),
    current_nav   NUMERIC(10,2),
    risk_level    VARCHAR(10) CHECK (risk_level IN ('LOW','MEDIUM','HIGH')),
    description   TEXT
);

CREATE TABLE instrument_holdings (
    holding_id    SERIAL PRIMARY KEY,
    user_id       INT REFERENCES users(user_id) ON DELETE CASCADE,
    instrument_id INT REFERENCES instruments(instrument_id) ON DELETE CASCADE,
    units         NUMERIC(10,4),
    avg_nav       NUMERIC(10,2),
    UNIQUE (user_id, instrument_id)
);

CREATE TABLE audit_log (
    log_id     SERIAL PRIMARY KEY,
    user_id    INT REFERENCES users(user_id) ON DELETE SET NULL,
    action     VARCHAR(50) NOT NULL,
    table_name VARCHAR(50),
    record_id  INT,
    old_value  TEXT,
    new_value  TEXT,
    logged_at  TIMESTAMP DEFAULT NOW()
);

CREATE TABLE leaderboard_snapshots (
    snap_id               SERIAL PRIMARY KEY,
    user_id               INT REFERENCES users(user_id) ON DELETE CASCADE,
    total_portfolio_value NUMERIC(15,2),
    total_profit_loss     NUMERIC(15,2),
    rank                  INT,
    snapped_at            TIMESTAMP DEFAULT NOW()
);
