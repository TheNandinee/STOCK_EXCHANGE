-- STOCK EXCHANGE v2.0 — BULK DATA GENERATOR
-- Generates 5000+ entries across price_history, transactions, orders, portfolio

DO $$
DECLARE
    v_stock_id   INT;
    v_user_id    INT;
    v_price      NUMERIC;
    v_new_price  NUMERIC;
    v_qty        INT;
    v_fee        NUMERIC;
    v_net        NUMERIC;
    v_order_id   INT;
    i            INT;
    v_offset     INTERVAL;
    v_type       VARCHAR(4);
BEGIN

-- ─────────────────────────────────────────────────────────────
-- 1. PRICE HISTORY: 300 ticks per stock × 15 stocks = 4500 rows
-- ─────────────────────────────────────────────────────────────
FOR v_stock_id IN 1..15 LOOP
    SELECT current_price INTO v_price FROM stocks WHERE stock_id = v_stock_id;
    FOR i IN 1..300 LOOP
        v_offset    := (300 - i) * INTERVAL '5 minutes';
        v_new_price := ROUND(v_price * (1 + (RANDOM()*2-1)*0.015), 2);
        IF v_new_price < 1 THEN v_new_price := 1; END IF;

        INSERT INTO price_history(stock_id, open_price, high_price, low_price, close_price, volume, recorded_at)
        VALUES (
            v_stock_id,
            ROUND(v_price * (1 + (RANDOM()*0.005)), 2),
            ROUND(v_price * (1 + RANDOM()*0.012), 2),
            ROUND(v_price * (1 - RANDOM()*0.012), 2),
            v_new_price,
            (RANDOM()*3000000 + 500000)::BIGINT,
            NOW() - v_offset
        );
        v_price := v_new_price;
    END LOOP;
END LOOP;

RAISE NOTICE 'Price history done: 4500 rows';

-- ─────────────────────────────────────────────────────────────
-- 2. TRADES: ~50 trades per user × 5 users = 250 transactions
--    (each via direct insert to bypass trigger wallet issues)
-- ─────────────────────────────────────────────────────────────
FOR v_user_id IN 1..5 LOOP
    FOR i IN 1..50 LOOP
        v_stock_id := (RANDOM()*14 + 1)::INT;
        SELECT current_price INTO v_price FROM stocks WHERE stock_id = v_stock_id;
        v_qty   := (RANDOM()*9 + 1)::INT;
        v_type  := CASE WHEN RANDOM() > 0.45 THEN 'BUY' ELSE 'SELL' END;
        v_fee   := ROUND(v_price * v_qty * 0.001, 2);
        v_net   := CASE v_type WHEN 'BUY' THEN (v_price*v_qty)+v_fee ELSE (v_price*v_qty)-v_fee END;
        v_offset := (50-i) * INTERVAL '10 minutes';

        -- Insert order
        INSERT INTO orders(user_id, stock_id, order_type, order_mode, quantity, status, placed_at, executed_at)
        VALUES (v_user_id, v_stock_id, v_type, 'MARKET', v_qty, 'EXECUTED', NOW()-v_offset, NOW()-v_offset)
        RETURNING order_id INTO v_order_id;

        -- Insert transaction (skip triggers by using advisory lock workaround — direct insert)
        INSERT INTO transactions(order_id, user_id, stock_id, txn_type, quantity, price_per_unit, brokerage_fee, net_amount, executed_at)
        VALUES (v_order_id, v_user_id, v_stock_id, v_type, v_qty, v_price, v_fee, v_net, NOW()-v_offset);

    END LOOP;
END LOOP;

RAISE NOTICE 'Transactions done: 250 rows';

-- ─────────────────────────────────────────────────────────────
-- 3. PORTFOLIO: rebuild clean holdings for all users
-- ─────────────────────────────────────────────────────────────
DELETE FROM portfolio;

INSERT INTO portfolio(user_id, stock_id, quantity, avg_buy_price)
SELECT
    t.user_id,
    t.stock_id,
    GREATEST(
        SUM(CASE WHEN t.txn_type='BUY' THEN t.quantity ELSE -t.quantity END),
        0
    ),
    AVG(CASE WHEN t.txn_type='BUY' THEN t.price_per_unit END)
FROM transactions t
GROUP BY t.user_id, t.stock_id
HAVING GREATEST(SUM(CASE WHEN t.txn_type='BUY' THEN t.quantity ELSE -t.quantity END), 0) > 0
   AND AVG(CASE WHEN t.txn_type='BUY' THEN t.price_per_unit END) IS NOT NULL;

RAISE NOTICE 'Portfolio rebuilt';

-- ─────────────────────────────────────────────────────────────
-- 4. PENDING LIMIT/STOP-LOSS ORDERS: 5 per user = 25 rows
-- ─────────────────────────────────────────────────────────────
FOR v_user_id IN 1..5 LOOP
    FOR v_stock_id IN 1..5 LOOP
        SELECT current_price INTO v_price FROM stocks WHERE stock_id = v_stock_id;
        INSERT INTO orders(user_id, stock_id, order_type, order_mode, quantity, limit_price, stop_price, status)
        VALUES (
            v_user_id, v_stock_id, 'SELL', 'STOP_LOSS', (RANDOM()*4+1)::INT,
            NULL,
            ROUND(v_price * 0.92, 2),
            'PENDING'
        );
    END LOOP;
END LOOP;

RAISE NOTICE 'Pending orders done: 25 rows';

-- ─────────────────────────────────────────────────────────────
-- 5. WATCHLIST additions
-- ─────────────────────────────────────────────────────────────
INSERT INTO watchlist(user_id, stock_id, alert_price)
SELECT u.user_id, s.stock_id, ROUND(s.current_price * 1.05, 2)
FROM users u
CROSS JOIN stocks s
WHERE u.role = 'trader'
  AND NOT EXISTS (
    SELECT 1 FROM watchlist w WHERE w.user_id=u.user_id AND w.stock_id=s.stock_id
  )
LIMIT 40;

RAISE NOTICE 'Watchlist done';

-- ─────────────────────────────────────────────────────────────
-- 6. LEADERBOARD SNAPSHOTS: hourly for last 24h = 5 × 24 = 120 rows
-- ─────────────────────────────────────────────────────────────
FOR v_user_id IN 1..5 LOOP
    FOR i IN 1..24 LOOP
        SELECT wallet_balance INTO v_price FROM users WHERE user_id = v_user_id;
        INSERT INTO leaderboard_snapshots(user_id, total_portfolio_value, total_profit_loss, rank, snapped_at)
        VALUES (
            v_user_id,
            ROUND(v_price + RANDOM()*20000, 2),
            ROUND((RANDOM()-0.3)*15000, 2),
            (RANDOM()*4+1)::INT,
            NOW() - (i * INTERVAL '1 hour')
        );
    END LOOP;
END LOOP;

RAISE NOTICE 'Leaderboard snapshots done: 120 rows';

END $$;
