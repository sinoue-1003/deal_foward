import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers import calls, deals, analytics, bots, conversations, leads, visitors

app = FastAPI(title="DealForward API", version="2.0.0")

# Allow Cloudflare Pages URL + local dev.
# Set ALLOWED_ORIGIN env var in production (e.g. https://dealforward.pages.dev).
_origin = os.environ.get("ALLOWED_ORIGIN", "")
_origins = [o for o in (_origin, "http://localhost:5173", "http://localhost:3000") if o]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(calls.router)
app.include_router(deals.router)
app.include_router(analytics.router)
app.include_router(bots.router)
app.include_router(conversations.router)
app.include_router(leads.router)
app.include_router(visitors.router)


@app.get("/api/health")
async def health():
    return {"status": "ok"}
