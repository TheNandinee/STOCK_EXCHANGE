# Stock Exchange Simulator

> A production-grade stock market simulation platform built as a DBMS flagship project.  
> Real triggers. Real stored procedures. Real-time price simulation. Full trading engine.

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?style=flat-square&logo=postgresql&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?style=flat-square&logo=fastapi&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=flat-square&logo=python&logoColor=white)
![Status](https://img.shields.io/badge/status-live-brightgreen?style=flat-square)

---

## 🚀 What This Is

Most stock market DBMS projects are just tables with buy/sell rows. This one isn't.

This simulator has a **full trading engine** — triggers that auto-fire stop-loss orders the moment a price drops, stored procedures that execute trades atomically, window functions computing 7-day rolling volatility, and a live leaderboard that ranks traders by real portfolio value. Everything runs inside PostgreSQL. The frontend updates in real time. The backend documents itself.

---

## ✨ Feature Highlights

| Layer | What's inside |
|---|---|
| **Database** | 12 tables, 3NF normalized, indexed for time-series queries |
| **Triggers** | 5 triggers — stop-loss auto-execution, wallet guard, sell validation, portfolio sync, audit logging |
| **Stored Procedures** | 5 procedures — market trade engine, limit order placement, price tick simulator, leaderboard refresh, order cancellation |
| **Views** | 4 views — live portfolio P&L, real-time leaderboard, sector market overview, 7-day rolling volatility |
| **Analytics** | Window functions: `RANK()`, `STDDEV()`, `LAG()`, rolling `AVG()`, sector allocation |
| **Backend** | FastAPI with 19 REST endpoints, auto-generated Swagger docs at `/docs` |
| **Frontend** | Dark-mode dashboard — market feed, portfolio tracker, trade terminal, audit log |

---

## 🗄️ Database Architecture

```
sectors ──< stocks ──< price_history
                 │
                 └──< orders ──< transactions
                                      │
users ──────────────────────────────< portfolio
  │                                   
  └──< watchlist                    
  └──< instrument_holdings ──< instruments
  └──< leaderboard_snapshots
  └──< audit_log
```

### Triggers in action

```
Price drops below stop_price?
  → trg_check_stop_loss fires
  → PENDING order flips to EXECUTED
  → audit_log entry written
  — all without a single line of application code
```

```
Transaction inserted?
  → trg_sync_portfolio fires
  → portfolio avg_buy_price recalculated
  → wallet_balance debited/credited atomically
```

---

## 📁 Project Structure

```
STOCK_EXCHANGE/
├── database/
│   ├── schema/
│   │   ├── 01_tables.sql        # 12 tables with constraints & indexes
│   │   ├── 02_triggers.sql      # 5 trigger functions
│   │   ├── 03_procedures.sql    # 5 stored procedures
│   │   └── 04_views.sql         # 4 views + window function analytics
│   └── seeds/
│       └── 01_seed.sql          # 15 NSE stocks, 6 users, instruments
├── backend/
│   ├── main.py                  # FastAPI app entry point
│   ├── config/
│   │   └── db.py                # PostgreSQL connection + query helpers
│   └── routes/
│       ├── stocks.py            # Market data, price simulation
│       ├── users.py             # Auth, portfolio, transaction history
│       ├── trade.py             # Market/limit/stop-loss order execution
│       └── analytics.py        # Leaderboard, volatility, audit log
├── frontend/
│   └── index.html               # Single-file dark-mode dashboard
├── .env
└── README.md
```

---

## ⚙️ Setup & Installation

### Prerequisites
- macOS / Linux
- PostgreSQL 14+
- Python 3.10+

### 1. Clone & set up environment

```bash
git clone https://github.com/YOUR_USERNAME/STOCK_EXCHANGE.git
cd STOCK_EXCHANGE
python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn psycopg2-binary python-dotenv
```

### 2. Configure environment

```bash
# Edit .env with your PostgreSQL credentials
DB_HOST=localhost
DB_PORT=5432
DB_NAME=stock_exchange
DB_USER=your_pg_username
DB_PASSWORD=
```

### 3. Create database & load schema

```bash
psql postgres -c "CREATE DATABASE stock_exchange;"

psql -U your_pg_username -d stock_exchange -f database/schema/01_tables.sql
psql -U your_pg_username -d stock_exchange -f database/schema/02_triggers.sql
psql -U your_pg_username -d stock_exchange -f database/schema/03_procedures.sql
psql -U your_pg_username -d stock_exchange -f database/schema/04_views.sql
psql -U your_pg_username -d stock_exchange -f database/seeds/01_seed.sql
```

### 4. Start the backend

```bash
cd backend
uvicorn main:app --reload --port 8000
```

API is live at `http://localhost:8000`  
Swagger docs at `http://localhost:8000/docs`

### 5. Open the frontend

```bash
open frontend/index.html
```

---

## 🔌 API Endpoints

```
GET    /stocks/                          List all stocks with live prices
GET    /stocks/{id}/history              Price history for charting
GET    /stocks/market/overview           Sector-wise gainers/losers
POST   /stocks/simulate-tick             Simulate a random price movement

POST   /users/register                   Register new trader
GET    /users/{id}/portfolio             Holdings with unrealized P&L
GET    /users/{id}/transactions          Full transaction history
GET    /users/{id}/orders                All orders with status

POST   /trade/market                     Execute a market order
POST   /trade/limit                      Place limit or stop-loss order
DELETE /trade/order/{id}/user/{uid}      Cancel a pending order

GET    /analytics/leaderboard            Live trader rankings
GET    /analytics/volatility             7-day rolling volatility per stock
GET    /analytics/top-traded             Most traded stocks by volume
GET    /analytics/sector-allocation/{id} User's sector diversification
GET    /analytics/audit-log              Every database event, timestamped
```

---

## 🧠 Key SQL Concepts Demonstrated

**Triggers**
```sql
-- Auto-fires when price drops below a trader's stop price
CREATE TRIGGER trg_check_stop_loss
AFTER UPDATE OF current_price ON stocks
FOR EACH ROW EXECUTE FUNCTION fn_check_stop_loss();
```

**Stored Procedure**
```sql
-- Atomic trade execution: order + transaction + audit in one call
CALL execute_market_trade(user_id, stock_id, 'BUY', quantity);
```

**Window Functions**
```sql
-- 7-day rolling volatility
ROUND(STDDEV(daily_return) OVER (
    PARTITION BY stock_id ORDER BY trade_date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
), 4) AS volatility_7d
```

**Generated Column**
```sql
total_amount NUMERIC(15,2) GENERATED ALWAYS AS (quantity * price_per_unit) STORED
```

---

## 📊 Sample Data

- **15 stocks** — RELIANCE, TCS, HDFCBANK, INFY, HINDUNILVR, SUNPHARMA, MARUTI, AIRTEL and more (NSE-inspired)
- **8 sectors** — Technology, Banking, FMCG, Pharmaceuticals, Energy, Automobiles, Telecom, Infrastructure
- **6 traders** — each starts with ₹1,00,000 virtual capital
- **6 instruments** — mutual funds, bonds, commodities, ETFs

---

## 🏗️ Tech Stack

| Component | Technology |
|---|---|
| Database | PostgreSQL 16 |
| Backend | Python 3 + FastAPI |
| ORM/Driver | psycopg2 |
| Frontend | Vanilla JS + Tailwind CSS + Chart.js |
| API Docs | Swagger UI (auto-generated) |

---

## 💡 What Makes This Different

Most DBMS projects push all logic into the application layer. This project intentionally keeps **business rules inside the database**:

- A trade can't execute if your wallet is short — enforced by a trigger, not application code
- Stop-loss orders fire the instant a price update hits — no polling, no cron job
- Every state change is timestamped in the audit log automatically
- Portfolio averages recalculate on every transaction via trigger, never stale

This mirrors how production financial systems actually work.

---

*Built as a DBMS course project. Designed to be the best one in the room.*
