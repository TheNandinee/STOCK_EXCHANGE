-- STOCK EXCHANGE v2.0 — SEED DATA

-- Sectors
INSERT INTO sectors (sector_name) VALUES
('Technology'), ('Banking'), ('FMCG'), ('Pharmaceuticals'),
('Energy'), ('Automobiles'), ('Telecommunications'), ('Infrastructure');

-- Stocks (NSE-inspired)
INSERT INTO stocks (ticker, company_name, sector_id, exchange, current_price, prev_close, market_cap, total_shares) VALUES
('RELIANCE',   'Reliance Industries Ltd',          5, 'NSE',  2850.50,  2820.00, 19300000000000, 6765000000),
('TCS',        'Tata Consultancy Services',         1, 'NSE',  3750.25,  3700.00,  1360000000000, 3630000000),
('HDFCBANK',   'HDFC Bank Ltd',                    2, 'NSE',  1620.80,  1600.00,  1230000000000, 7590000000),
('INFY',       'Infosys Ltd',                      1, 'NSE',  1455.60,  1440.00,   604000000000, 4150000000),
('HINDUNILVR', 'Hindustan Unilever Ltd',            3, 'NSE',  2510.40,  2490.00,   590000000000,  234000000),
('SUNPHARMA',  'Sun Pharmaceutical Industries',     4, 'NSE',  1290.75,  1270.00,   309000000000,  240000000),
('ONGC',       'Oil and Natural Gas Corp',          5, 'NSE',   280.50,   275.00,   352000000000, 1258000000),
('MARUTI',     'Maruti Suzuki India Ltd',           6, 'NSE', 10250.00, 10100.00,   309000000000,  302000000),
('AIRTEL',     'Bharti Airtel Ltd',                 7, 'NSE',  1180.30,  1160.00,   647000000000,  548000000),
('AXISBANK',   'Axis Bank Ltd',                    2, 'NSE',  1090.50,  1075.00,   335000000000, 3080000000),
('WIPRO',      'Wipro Ltd',                         1, 'NSE',   460.25,   455.00,   239000000000, 5200000000),
('TATASTEEL',  'Tata Steel Ltd',                    8, 'NSE',   155.40,   152.00,   194000000000,12470000000),
('BAJFINANCE', 'Bajaj Finance Ltd',                 2, 'NSE',  7200.00,  7100.00,   432000000000,  600000000),
('COALINDIA',  'Coal India Ltd',                    5, 'NSE',   470.80,   465.00,   290000000000, 6162000000),
('LTIM',       'LTIMindtree Ltd',                   1, 'NSE',  5200.00,  5100.00,   154000000000,  296000000);

-- Users (password_hash is placeholder — backend will use bcrypt)
INSERT INTO users (username, email, password_hash, wallet_balance, role) VALUES
('alice_trader',  'alice@demo.com',   'hash_alice',   100000.00, 'trader'),
('bob_investor',  'bob@demo.com',     'hash_bob',     100000.00, 'trader'),
('charlie_bull',  'charlie@demo.com', 'hash_charlie', 100000.00, 'trader'),
('diana_quant',   'diana@demo.com',   'hash_diana',   100000.00, 'trader'),
('eve_scalper',   'eve@demo.com',     'hash_eve',     100000.00, 'trader'),
('admin_user',    'admin@demo.com',   'hash_admin',   999999.00, 'admin');

-- Instruments
INSERT INTO instruments (name, type, current_nav, risk_level, description) VALUES
('Nifty 50 Index Fund',      'MUTUAL_FUND',  245.30, 'MEDIUM', 'Tracks Nifty 50 index'),
('SBI Bluechip Fund',        'MUTUAL_FUND',   68.45, 'LOW',    'Large-cap equity fund'),
('HDFC Corporate Bond Fund', 'BOND',          15.20, 'LOW',    'Investment-grade bonds'),
('Gold ETF',                 'ETF',         6250.00, 'MEDIUM', 'Tracks domestic gold price'),
('Crude Oil Mini',           'COMMODITY',   7100.00, 'HIGH',   'WTI crude futures mini lot'),
('Silver ETF',               'ETF',           78.50, 'MEDIUM', 'Tracks silver spot price');

-- Price history (5 ticks each for RELIANCE=1 and TCS=2)
INSERT INTO price_history (stock_id, open_price, high_price, low_price, close_price, volume, recorded_at) VALUES
(1, 2800.00, 2860.00, 2795.00, 2820.00, 2100000, NOW() - INTERVAL '5 minutes'),
(1, 2820.00, 2855.00, 2810.00, 2835.00, 1900000, NOW() - INTERVAL '4 minutes'),
(1, 2830.00, 2865.00, 2820.00, 2840.00, 1750000, NOW() - INTERVAL '3 minutes'),
(1, 2835.00, 2870.00, 2825.00, 2845.00, 2050000, NOW() - INTERVAL '2 minutes'),
(1, 2840.00, 2860.00, 2830.00, 2850.50, 1680000, NOW() - INTERVAL '1 minute'),
(2, 3690.00, 3760.00, 3685.00, 3700.00, 1200000, NOW() - INTERVAL '5 minutes'),
(2, 3700.00, 3755.00, 3695.00, 3720.00, 1100000, NOW() - INTERVAL '4 minutes'),
(2, 3715.00, 3758.00, 3710.00, 3735.00, 1050000, NOW() - INTERVAL '3 minutes'),
(2, 3725.00, 3762.00, 3718.00, 3742.00, 1080000, NOW() - INTERVAL '2 minutes'),
(2, 3738.00, 3755.00, 3730.00, 3750.25,  980000, NOW() - INTERVAL '1 minute');

-- Watchlist
INSERT INTO watchlist (user_id, stock_id, alert_price) VALUES
(1, 3,  1550.00),
(1, 6,  1200.00),
(2, 1,  3000.00),
(3, 8,  9800.00),
(4, 13, 7500.00);
