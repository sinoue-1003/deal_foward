from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException, Request

from db import get_db
from services.ai_analysis import analyze_transcript

router = APIRouter(prefix="/api/calls", tags=["calls"])


@router.get("/")
async def list_calls(skip: int = 0, limit: int = 50):
    db = get_db()
    return await db.table("calls").order("date", desc=True).offset(skip).limit(limit).execute()


@router.get("/{call_id}")
async def get_call(call_id: int):
    db = get_db()
    rows = await db.table("calls").eq("id", call_id).limit(1).execute()
    if not rows:
        raise HTTPException(status_code=404, detail="Call not found")
    return rows[0]


@router.post("/")
async def create_call(request: Request):
    payload: dict = await request.json()
    title: str = payload.get("title", "").strip()
    if not title:
        raise HTTPException(status_code=400, detail="title is required")

    now = datetime.now(timezone.utc).isoformat()
    data = {
        "title": title,
        "participants": payload.get("participants", []),
        "deal_id": payload.get("deal_id"),
        "transcript": payload.get("transcript"),
        "duration_seconds": int(payload.get("duration_seconds", 0)),
        "date": now,
        "created_at": now,
    }

    transcript = data.get("transcript")
    if transcript:
        analysis = analyze_transcript(transcript)
        data.update(_analysis_fields(analysis))

    db = get_db()
    return await db.table("calls").insert(data)


@router.post("/{call_id}/analyze")
async def analyze_call(call_id: int):
    db = get_db()
    rows = await db.table("calls").eq("id", call_id).limit(1).execute()
    if not rows:
        raise HTTPException(status_code=404, detail="Call not found")
    call = rows[0]
    if not call.get("transcript"):
        raise HTTPException(status_code=400, detail="No transcript available")

    analysis = analyze_transcript(call["transcript"])
    return await db.table("calls").eq("id", call_id).update(_analysis_fields(analysis))


@router.delete("/{call_id}")
async def delete_call(call_id: int):
    db = get_db()
    await db.table("calls").eq("id", call_id).delete()
    return {"ok": True}


def _analysis_fields(analysis: dict) -> dict:
    return {
        "summary": analysis.get("summary", ""),
        "sentiment": analysis.get("sentiment", "neutral"),
        "keywords": analysis.get("keywords", []),
        "next_steps": analysis.get("next_steps", []),
        "talk_ratio": analysis.get("talk_ratio", {"rep": 50, "prospect": 50}),
    }
