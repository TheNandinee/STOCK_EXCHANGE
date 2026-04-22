from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import stocks, users, trade, analytics

app = FastAPI(
    title="Stock Exchange Simulator v2.0",
    description="A production-grade DBMS project — triggers, procedures, views, analytics",
    version="2.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(stocks.router)
app.include_router(users.router)
app.include_router(trade.router)
app.include_router(analytics.router)

@app.get("/")
def root():
    return {"message": "Stock Exchange API v2.0 is running 🚀"}
