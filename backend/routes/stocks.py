from fastapi import APIRouter, HTTPException
from config.db import query, execute

router = APIRouter(prefix="/stocks", tags=["Stocks"])

@router.get("/")
def get_all_stocks():
    return query("""
        SELECT s.stock_id, s.ticker, s.company_name, sec.sector_name,
               s.exchange, s.current_price, s.prev_close,
               ROUND((s.current_price - s.prev_close) / NULLIF(s.prev_close,0) * 100, 2) AS change_pct
        FROM stocks s
        LEFT JOIN sectors sec ON s.sector_id = sec.sector_id
        WHERE s.is_active = TRUE
        ORDER BY s.ticker
    """)

@router.get("/market/overview")
def market_overview():
    return query("SELECT * FROM vw_market_overview ORDER BY sector_name")

@router.post("/simulate-tick")
def simulate_tick(volatility: float = 0.02):
    execute("CALL simulate_price_tick(%s::NUMERIC)", (volatility,))
    return {"message": f"Price tick simulated at ±{volatility*100:.0f}% volatility"}

@router.get("/{stock_id}/history")
def get_price_history(stock_id: int, limit: int = 100):
    rows = query("""
        SELECT close_price, volume, recorded_at
        FROM price_history
        WHERE stock_id = %s
        ORDER BY recorded_at ASC
        LIMIT %s
    """, (stock_id, limit))
    return rows

@router.get("/{stock_id}")
def get_stock(stock_id: int):
    rows = query("SELECT * FROM stocks WHERE stock_id = %s", (stock_id,))
    if not rows:
        raise HTTPException(status_code=404, detail="Stock not found")
    return rows[0]
