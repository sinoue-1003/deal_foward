"""Leads router — maps to the deals table with DealForward terminology."""
from fastapi import APIRouter, HTTPException, Request
from datetime import datetime, timezone

from db import get_db

router = APIRouter(prefix="/api/leads", tags=["leads"])

VALID_STAGES = {"prospect", "qualify", "demo", "proposal", "negotiation", "closed_won", "closed_lost"}


@router.get("/")
async def list_leads(skip: int = 0, limit: int = 50):
    db = get_db()
    return await db.table("deals").order("created_at", desc=True).offset(skip).limit(limit).execute()


@router.get("/{lead_id}")
async def get_lead(lead_id: int):
    db = get_db()
    rows = await db.table("deals").eq("id", lead_id).limit(1).execute()
    if not rows:
        raise HTTPException(status_code=404, detail="Lead not found")
    lead = rows[0]

    # Attach related conversations
    calls = await db.table("calls").eq("deal_id", lead_id).order("date", desc=True).execute()
    lead["calls"] = calls
    return lead


@router.post("/")
async def create_lead(request: Request):
    payload: dict = await request.json()
    name: str = payload.get("name", "").strip()
    company: str = payload.get("company", "").strip()
    if not name or not company:
        raise HTTPException(status_code=400, detail="name and company are required")

    stage = payload.get("stage", "prospect")
    if stage not in VALID_STAGES:
        raise HTTPException(status_code=400, detail=f"Invalid stage: {stage}")

    now = datetime.now(timezone.utc).isoformat()
    data = {
        "name": name,
        "company": company,
        "stage": stage,
        "amount": float(payload.get("amount", 0)),
        "probability": int(payload.get("probability", 10)),
        "owner": payload.get("owner", ""),
        "contact_name": payload.get("contact_name", ""),
        "contact_email": payload.get("contact_email", ""),
        "notes": payload.get("notes", ""),
        "created_at": now,
    }

    db = get_db()
    return await db.table("deals").insert(data)


@router.patch("/{lead_id}")
async def update_lead(lead_id: int, request: Request):
    payload: dict = await request.json()
    allowed = {"stage", "amount", "probability", "notes", "owner", "contact_name", "contact_email", "close_date"}
    updates = {k: v for k, v in payload.items() if k in allowed}

    if "stage" in updates and updates["stage"] not in VALID_STAGES:
        raise HTTPException(status_code=400, detail=f"Invalid stage: {updates['stage']}")

    db = get_db()
    rows = await db.table("deals").eq("id", lead_id).limit(1).execute()
    if not rows:
        raise HTTPException(status_code=404, detail="Lead not found")

    return await db.table("deals").eq("id", lead_id).update(updates)


@router.delete("/{lead_id}")
async def delete_lead(lead_id: int):
    db = get_db()
    await db.table("deals").eq("id", lead_id).delete()
    return {"ok": True}
