from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from database import init_db, SessionLocal
from routers import calls, deals, analytics

app = FastAPI(title="Gong Clone API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(calls.router)
app.include_router(deals.router)
app.include_router(analytics.router)


@app.on_event("startup")
def startup():
    init_db()
    db = SessionLocal()
    try:
        from services.seed import seed
        seed(db)
    finally:
        db.close()


@app.get("/api/health")
def health():
    return {"status": "ok"}
