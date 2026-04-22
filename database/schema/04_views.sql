-- STOCK EXCHANGE v2.0 — VIEWS & ANALYTICS

CREATE OR REPLACE VIEW vw_portfolio_summary AS
SELECT
    u.user_id, u.username,
    s.ticker, s.company_name,
    p.quantity, p.avg_buy_price, s.current_price,
    ROUND((s.current_price - p.avg_buy_price) * p.quantity, 2)             AS unrealized_pnl,
    ROUND((s.current_price - p.avg_buy_price) / p.avg_buy_price * 100, 2) AS pnl_pct,
    ROUND(p.quantity * s.current_price, 2)                                  AS current_value
FROM portfolio p
JOIN users  u ON p.user_id  = u.user_id
JOIN stocks s ON p.stock_id = s.stock_id;


CREATE OR REPLACE VIEW vw_live_leaderboard AS
SELECT
    u.user_id, u.username,
    ROUND(u.wallet_balance, 2)                                                   AS cash,
    ROUND(COALESCE(SUM(p.quantity * s.current_price), 0), 2)                    AS stock_value,
    ROUND(u.wallet_balance + COALESCE(SUM(p.quantity * s.current_price), 0), 2) AS total_value,
    ROUND((u.wallet_balance + COALESCE(SUM(p.quantity * s.current_price), 0)) - 100000, 2) AS net_pnl,
    RANK() OVER (
        ORDER BY (u.wallet_balance + COALESCE(SUM(p.quantity * s.current_price), 0)) DESC
    ) AS rank
FROM users u
LEFT JOIN portfolio p ON u.user_id = p.user_id
LEFT JOIN stocks s    ON p.stock_id = s.stock_id
WHERE u.role = 'trader' AND u.is_active = TRUE
GROUP BY u.user_id, u.username, u.wallet_balance;


CREATE OR REPLACE VIEW vw_market_overview AS
SELECT
    sec.sector_name,
    COUNT(s.stock_id)                                                AS num_stocks,
    ROUND(AVG(s.current_price), 2)                                   AS avg_price,
    ROUND(AVG((s.current_price - s.prev_close)
              / NULLIF(s.prev_close, 0) * 100), 2)                  AS avg_change_pct,
    COUNT(CASE WHEN s.current_price > s.prev_close THEN 1 END)      AS gainers,
    COUNT(CASE WHEN s.current_price < s.prev_close THEN 1 END)      AS losers
FROM stocks s
LEFT JOIN sectors sec ON s.sector_id = sec.sector_id
WHERE s.is_active = TRUE
GROUP BY sec.sector_name;


CREATE OR REPLACE VIEW vw_stock_volatility AS
WITH daily_returns AS (
    SELECT
        stock_id, close_price,
        LAG(close_price) OVER (PARTITION BY stock_id ORDER BY recorded_at) AS prev_price,
        recorded_at::DATE AS trade_date
    FROM price_history
),
pct_returns AS (
    SELECT stock_id, trade_date, close_price,
           CASE WHEN prev_price > 0
                THEN (close_price - prev_price) / prev_price * 100
                ELSE NULL END AS daily_return
    FROM daily_returns
)
SELECT
    r.stock_id, s.ticker, s.company_name, r.trade_date,
    ROUND(STDDEV(r.daily_return) OVER (
        PARTITION BY r.stock_id ORDER BY r.trade_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 4) AS volatility_7d,
    ROUND(AVG(r.close_price) OVER (
        PARTITION BY r.stock_id ORDER BY r.trade_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_7d
FROM pct_returns r
JOIN stocks s ON r.stock_id = s.stock_id;
