from fastapi import APIRouter
from config.db import query, execute

router = APIRouter(prefix="/analytics", tags=["Analytics"])

@router.get("/leaderboard")
def leaderboard():
    return query("SELECT * FROM vw_live_leaderboard ORDER BY rank LIMIT 20")

@router.post("/leaderboard/snapshot")
def snapshot_leaderboard():
    execute("CALL refresh_leaderboard()")
    return {"message": "Leaderboard snapshot saved"}

@router.get("/volatility")
def volatility():
    return query("""
        SELECT DISTINCT ON (ticker) ticker, company_name,
               volatility_7d, moving_avg_7d, trade_date
        FROM vw_stock_volatility
        ORDER BY ticker, trade_date DESC
    """)

@router.get("/top-traded")
def top_traded():
    return query("""
        SELECT s.ticker, s.company_name,
               COUNT(t.txn_id)     AS num_trades,
               SUM(t.quantity)     AS total_shares,
               SUM(t.total_amount) AS total_turnover
        FROM transactions t
        JOIN stocks s ON t.stock_id = s.stock_id
        GROUP BY s.ticker, s.company_name
        ORDER BY total_shares DESC
        LIMIT 10
    """)

@router.get("/sector-allocation/{user_id}")
def sector_allocation(user_id: int):
    return query("""
        SELECT sec.sector_name,
               ROUND(SUM(p.quantity * s.current_price), 2) AS value,
               ROUND(SUM(p.quantity * s.current_price) /
                     SUM(SUM(p.quantity * s.current_price)) OVER () * 100, 2) AS pct
        FROM portfolio p
        JOIN stocks s ON p.stock_id = s.stock_id
        JOIN sectors sec ON s.sector_id = sec.sector_id
        WHERE p.user_id = %s
        GROUP BY sec.sector_name
        ORDER BY value DESC
    """, (user_id,))

@router.get("/audit-log")
def audit_log(limit: int = 50):
    return query("""
        SELECT a.log_id, u.username, a.action, a.table_name,
               a.old_value, a.new_value, a.logged_at
        FROM audit_log a
        LEFT JOIN users u ON a.user_id = u.user_id
        ORDER BY a.logged_at DESC
        LIMIT %s
    """, (limit,))
