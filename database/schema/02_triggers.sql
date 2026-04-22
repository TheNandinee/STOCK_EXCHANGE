-- STOCK EXCHANGE v2.0 — TRIGGERS

CREATE OR REPLACE FUNCTION fn_track_price_change()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.current_price <> OLD.current_price THEN
        NEW.prev_close := OLD.current_price;
        INSERT INTO price_history(stock_id, close_price)
        VALUES (OLD.stock_id, NEW.current_price);
        INSERT INTO audit_log(action, table_name, record_id, old_value, new_value)
        VALUES ('PRICE_UPDATED', 'stocks', OLD.stock_id,
                OLD.current_price::TEXT, NEW.current_price::TEXT);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_track_price_change
BEFORE UPDATE OF current_price ON stocks
FOR EACH ROW EXECUTE FUNCTION fn_track_price_change();


CREATE OR REPLACE FUNCTION fn_check_stop_loss()
RETURNS TRIGGER AS $$
DECLARE v_order RECORD;
BEGIN
    IF NEW.current_price < OLD.current_price THEN
        FOR v_order IN
            SELECT * FROM orders
            WHERE stock_id = NEW.stock_id
              AND order_type = 'SELL'
              AND order_mode = 'STOP_LOSS'
              AND status = 'PENDING'
              AND stop_price >= NEW.current_price
        LOOP
            UPDATE orders SET status = 'EXECUTED', executed_at = NOW()
            WHERE order_id = v_order.order_id;
            INSERT INTO audit_log(user_id, action, table_name, record_id, old_value, new_value)
            VALUES (v_order.user_id, 'STOP_LOSS_TRIGGERED', 'orders',
                    v_order.order_id, 'PENDING', 'EXECUTED at ' || NEW.current_price::TEXT);
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_stop_loss
AFTER UPDATE OF current_price ON stocks
FOR EACH ROW EXECUTE FUNCTION fn_check_stop_loss();


CREATE OR REPLACE FUNCTION fn_validate_wallet()
RETURNS TRIGGER AS $$
DECLARE
    v_price    NUMERIC;
    v_required NUMERIC;
    v_balance  NUMERIC;
BEGIN
    IF NEW.order_type = 'BUY' THEN
        SELECT current_price INTO v_price FROM stocks WHERE stock_id = NEW.stock_id;
        SELECT wallet_balance INTO v_balance FROM users WHERE user_id = NEW.user_id;
        v_required := COALESCE(NEW.limit_price, v_price) * NEW.quantity;
        IF v_balance < v_required THEN
            RAISE EXCEPTION 'Insufficient balance. Need %, have %', v_required, v_balance;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_wallet
BEFORE INSERT ON orders
FOR EACH ROW EXECUTE FUNCTION fn_validate_wallet();


CREATE OR REPLACE FUNCTION fn_validate_sell_qty()
RETURNS TRIGGER AS $$
DECLARE v_owned INT;
BEGIN
    IF NEW.txn_type = 'SELL' THEN
        SELECT quantity INTO v_owned
        FROM portfolio
        WHERE user_id = NEW.user_id AND stock_id = NEW.stock_id;
        IF NOT FOUND OR v_owned < NEW.quantity THEN
            RAISE EXCEPTION 'Cannot sell %. You own %', NEW.quantity, COALESCE(v_owned, 0);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_sell_qty
BEFORE INSERT ON transactions
FOR EACH ROW EXECUTE FUNCTION fn_validate_sell_qty();


CREATE OR REPLACE FUNCTION fn_sync_portfolio()
RETURNS TRIGGER AS $$
DECLARE
    v_qty INT;
    v_avg NUMERIC;
BEGIN
    IF NEW.txn_type = 'BUY' THEN
        SELECT quantity, avg_buy_price INTO v_qty, v_avg
        FROM portfolio WHERE user_id = NEW.user_id AND stock_id = NEW.stock_id;
        IF FOUND THEN
            UPDATE portfolio SET
                avg_buy_price = ((v_qty * v_avg) + (NEW.quantity * NEW.price_per_unit))
                                 / (v_qty + NEW.quantity),
                quantity = quantity + NEW.quantity
            WHERE user_id = NEW.user_id AND stock_id = NEW.stock_id;
        ELSE
            INSERT INTO portfolio(user_id, stock_id, quantity, avg_buy_price)
            VALUES (NEW.user_id, NEW.stock_id, NEW.quantity, NEW.price_per_unit);
        END IF;
        UPDATE users SET wallet_balance = wallet_balance - NEW.net_amount
        WHERE user_id = NEW.user_id;
    ELSIF NEW.txn_type = 'SELL' THEN
        UPDATE portfolio SET quantity = quantity - NEW.quantity
        WHERE user_id = NEW.user_id AND stock_id = NEW.stock_id;
        DELETE FROM portfolio
        WHERE user_id = NEW.user_id AND stock_id = NEW.stock_id AND quantity = 0;
        UPDATE users SET wallet_balance = wallet_balance + NEW.net_amount
        WHERE user_id = NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_portfolio
AFTER INSERT ON transactions
FOR EACH ROW EXECUTE FUNCTION fn_sync_portfolio();
