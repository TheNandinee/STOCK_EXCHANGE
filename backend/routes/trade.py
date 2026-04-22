from fastapi import APIRouter, HTTPException
from config.db import query, execute, get_conn
from pydantic import BaseModel
from typing import Optional
import psycopg2

router = APIRouter(prefix="/trade", tags=["Trading"])

class MarketOrderRequest(BaseModel):
    user_id: int
    stock_id: int
    order_type: str   # BUY or SELL
    quantity: int

class LimitOrderRequest(BaseModel):
    user_id: int
    stock_id: int
    order_type: str
    order_mode: str   # LIMIT or STOP_LOSS
    quantity: int
    limit_price: Optional[float] = None
    stop_price: Optional[float] = None

@router.post("/market")
def market_order(req: MarketOrderRequest):
    if req.order_type not in ("BUY", "SELL"):
        raise HTTPException(status_code=400, detail="order_type must be BUY or SELL")
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute(
            "CALL execute_market_trade(%s, %s, %s, %s)",
            (req.user_id, req.stock_id, req.order_type, req.quantity)
        )
        conn.commit()
        cur.close()
        conn.close()
        return {"message": f"{req.order_type} order executed for {req.quantity} shares"}
    except psycopg2.errors.RaiseException as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/limit")
def limit_order(req: LimitOrderRequest):
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute(
            "CALL place_limit_order(%s, %s, %s, %s, %s, %s, %s)",
            (req.user_id, req.stock_id, req.order_type, req.order_mode,
             req.quantity, req.limit_price, req.stop_price)
        )
        conn.commit()
        cur.close()
        conn.close()
        return {"message": f"{req.order_mode} {req.order_type} order placed"}
    except psycopg2.errors.RaiseException as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.delete("/order/{order_id}/user/{user_id}")
def cancel_order(order_id: int, user_id: int):
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("CALL cancel_order(%s, %s)", (order_id, user_id))
        conn.commit()
        cur.close()
        conn.close()
        return {"message": f"Order {order_id} cancelled"}
    except psycopg2.errors.RaiseException as e:
        raise HTTPException(status_code=400, detail=str(e))
