-- STOCK EXCHANGE v2.0 — STORED PROCEDURES

CREATE OR REPLACE PROCEDURE execute_market_trade(
    p_user_id  INT,
    p_stock_id INT,
    p_type     VARCHAR(4),
    p_qty      INT,
    p_brokerage_pct NUMERIC DEFAULT 0.001
)
LANGUAGE plpgsql AS $$
DECLARE
    v_price    NUMERIC;
    v_fee      NUMERIC;
    v_net      NUMERIC;
    v_order_id INT;
BEGIN
    SELECT current_price INTO v_price FROM stocks WHERE stock_id = p_stock_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Stock % not found', p_stock_id; END IF;
    v_fee := ROUND(v_price * p_qty * p_brokerage_pct, 2);
    v_net := CASE p_type
                 WHEN 'BUY'  THEN (v_price * p_qty) + v_fee
                 WHEN 'SELL' THEN (v_price * p_qty) - v_fee
             END;
    INSERT INTO orders(user_id, stock_id, order_type, order_mode, quantity, status, executed_at)
    VALUES (p_user_id, p_stock_id, p_type, 'MARKET', p_qty, 'EXECUTED', NOW())
    RETURNING order_id INTO v_order_id;
    INSERT INTO transactions(order_id, user_id, stock_id, txn_type,
                              quantity, price_per_unit, brokerage_fee, net_amount)
    VALUES (v_order_id, p_user_id, p_stock_id, p_type, p_qty, v_price, v_fee, v_net);
    INSERT INTO audit_log(user_id, action, table_name, record_id, new_value)
    VALUES (p_user_id, 'TRADE_EXECUTED', 'transactions', v_order_id,
            p_type || ' ' || p_qty || ' @ ' || v_price);
END;
$$;

CREATE OR REPLACE PROCEDURE place_limit_order(
    p_user_id     INT,
    p_stock_id    INT,
    p_type        VARCHAR(4),
    p_mode        VARCHAR(10),
    p_qty         INT,
    p_limit_price NUMERIC DEFAULT NULL,
    p_stop_price  NUMERIC DEFAULT NULL
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO orders(user_id, stock_id, order_type, order_mode,
                       quantity, limit_price, stop_price, status)
    VALUES (p_user_id, p_stock_id, p_type, p_mode,
            p_qty, p_limit_price, p_stop_price, 'PENDING');
END;
$$;

CREATE OR REPLACE PROCEDURE simulate_price_tick(
    p_volatility NUMERIC DEFAULT 0.02
)
LANGUAGE plpgsql AS $$
DECLARE
    v_stock     RECORD;
    v_new_price NUMERIC;
BEGIN
    FOR v_stock IN SELECT stock_id, current_price FROM stocks WHERE is_active = TRUE LOOP
        v_new_price := ROUND(
            v_stock.current_price * (1 + (RANDOM() * 2 - 1) * p_volatility), 2
        );
        IF v_new_price < 1 THEN v_new_price := 1; END IF;
        UPDATE stocks SET current_price = v_new_price WHERE stock_id = v_stock.stock_id;
    END LOOP;
END;
$$;

CREATE OR REPLACE PROCEDURE refresh_leaderboard()
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO leaderboard_snapshots(user_id, total_portfolio_value, total_profit_loss, rank)
    SELECT
        u.user_id,
        ROUND(u.wallet_balance + COALESCE(SUM(p.quantity * s.current_price), 0), 2),
        ROUND((u.wallet_balance + COALESCE(SUM(p.quantity * s.current_price), 0)) - 100000, 2),
        RANK() OVER (
            ORDER BY (u.wallet_balance + COALESCE(SUM(p.quantity * s.current_price), 0)) DESC
        )
    FROM users u
    LEFT JOIN portfolio p ON u.user_id = p.user_id
    LEFT JOIN stocks s    ON p.stock_id = s.stock_id
    WHERE u.role = 'trader'
    GROUP BY u.user_id, u.wallet_balance;
END;
$$;

CREATE OR REPLACE PROCEDURE cancel_order(p_order_id INT, p_user_id INT)
LANGUAGE plpgsql AS $$
DECLARE v_status VARCHAR;
BEGIN
    SELECT status INTO v_status FROM orders
    WHERE order_id = p_order_id AND user_id = p_user_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Order not found';
    ELSIF v_status != 'PENDING' THEN RAISE EXCEPTION 'Cannot cancel — status is %', v_status;
    END IF;
    UPDATE orders SET status = 'CANCELLED' WHERE order_id = p_order_id;
    INSERT INTO audit_log(user_id, action, table_name, record_id)
    VALUES (p_user_id, 'ORDER_CANCELLED', 'orders', p_order_id);
END;
$$;
