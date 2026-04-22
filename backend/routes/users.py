from fastapi import APIRouter, HTTPException
from config.db import query, execute
from pydantic import BaseModel
import hashlib

router = APIRouter(prefix="/users", tags=["Users"])

class RegisterRequest(BaseModel):
    username: str
    email: str
    password: str

@router.post("/register")
def register(req: RegisterRequest):
    existing = query("SELECT user_id FROM users WHERE email = %s OR username = %s",
                     (req.email, req.username))
    if existing:
        raise HTTPException(status_code=400, detail="Username or email already exists")
    pw_hash = hashlib.sha256(req.password.encode()).hexdigest()
    execute(
        "INSERT INTO users (username, email, password_hash) VALUES (%s, %s, %s)",
        (req.username, req.email, pw_hash)
    )
    return {"message": f"User {req.username} registered successfully"}

@router.get("/{user_id}")
def get_user(user_id: int):
    rows = query(
        "SELECT user_id, username, email, wallet_balance, role, created_at FROM users WHERE user_id = %s",
        (user_id,)
    )
    if not rows:
        raise HTTPException(status_code=404, detail="User not found")
    return rows[0]

@router.get("/{user_id}/portfolio")
def get_portfolio(user_id: int):
    return query(
        "SELECT * FROM vw_portfolio_summary WHERE user_id = %s",
        (user_id,)
    )

@router.get("/{user_id}/transactions")
def get_transactions(user_id: int):
    return query("""
        SELECT t.txn_type, s.ticker, t.quantity, t.price_per_unit,
               t.total_amount, t.brokerage_fee, t.net_amount, t.executed_at
        FROM transactions t
        JOIN stocks s ON t.stock_id = s.stock_id
        WHERE t.user_id = %s
        ORDER BY t.executed_at DESC
    """, (user_id,))

@router.get("/{user_id}/orders")
def get_orders(user_id: int):
    return query("""
        SELECT o.order_id, o.order_type, o.order_mode, s.ticker,
               o.quantity, o.limit_price, o.stop_price, o.status, o.placed_at, o.executed_at
        FROM orders o
        JOIN stocks s ON o.stock_id = s.stock_id
        WHERE o.user_id = %s
        ORDER BY o.placed_at DESC
    """, (user_id,))
