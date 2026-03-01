from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException, Request

from db import get_db

router = APIRouter(prefix="/api/deals", tags=["deals"])

VALID_STAGES = ["prospect", "qualify", "demo", "proposal", "negotiation", "closed_won", "closed_lost"]


@router.get("/")
async def list_deals(skip: int = 0, limit: int = 100):
    db = get_db()
    return await db.table("deals").order("created_at", desc=True).offset(skip).limit(limit).execute()


@router.get("/{deal_id}")
async def get_deal(deal_id: int):
    db = get_db()
    rows = await db.table("deals").eq("id", deal_id).limit(1).execute()
    if not rows:
        raise HTTPException(status_code=404, detail="Deal not found")

    deal = rows[0]
    calls = await db.table("calls").eq("deal_id", deal_id).order("date", desc=True).execute()
    deal["calls"] = [
        {k: c[k] for k in ("id", "title", "date", "duration_seconds", "sentiment") if k in c}
        for c in calls
    ]
    return deal


@router.post("/")
async def create_deal(request: Request):
    payload: dict = await request.json()
    stage = payload.get("stage", "prospect")
    if stage not in VALID_STAGES:
        raise HTTPException(status_code=400, detail=f"Invalid stage: {stage}")

    now = datetime.now(timezone.utc).isoformat()
    data = {
        "name": payload.get("name", "").strip(),
        "company": payload.get("company", "").strip(),
        "stage": stage,
        "amount": float(payload.get("amount", 0)),
        "probability": int(payload.get("probability", 10)),
        "owner": payload.get("owner", "").strip(),
        "contact_name": payload.get("contact_name"),
        "contact_email": payload.get("contact_email"),
        "notes": payload.get("notes"),
        "competitors": payload.get("competitors", []),
        "close_date": payload.get("close_date"),
        "created_at": now,
        "updated_at": now,
    }
    if not data["name"] or not data["company"] or not data["owner"]:
        raise HTTPException(status_code=400, detail="name, company, owner are required")

    db = get_db()
    return await db.table("deals").insert(data)


@router.patch("/{deal_id}")
async def update_deal(deal_id: int, request: Request):
    payload: dict = await request.json()
    if "stage" in payload and payload["stage"] not in VALID_STAGES:
        raise HTTPException(status_code=400, detail=f"Invalid stage: {payload['stage']}")

    allowed = {"name", "company", "stage", "amount", "probability", "owner",
               "contact_name", "contact_email", "notes", "competitors", "close_date"}
    data = {k: v for k, v in payload.items() if k in allowed}
    data["updated_at"] = datetime.now(timezone.utc).isoformat()

    db = get_db()
    rows = await db.table("deals").eq("id", deal_id).limit(1).execute()
    if not rows:
        raise HTTPException(status_code=404, detail="Deal not found")
    return await db.table("deals").eq("id", deal_id).update(data)


@router.delete("/{deal_id}")
async def delete_deal(deal_id: int):
    db = get_db()
    await db.table("deals").eq("id", deal_id).delete()
    return {"ok": True}
