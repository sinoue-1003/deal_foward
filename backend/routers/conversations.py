"""Conversations router — maps to the calls table with Breakout AI terminology."""
from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException, Request

from db import get_db
from services.ai_analysis import analyze_transcript

router = APIRouter(prefix="/api/conversations", tags=["conversations"])


@router.get("/")
async def list_conversations(skip: int = 0, limit: int = 50):
    db = get_db()
    return await db.table("calls").order("date", desc=True).offset(skip).limit(limit).execute()


@router.get("/{conversation_id}")
async def get_conversation(conversation_id: int):
    db = get_db()
    rows = await db.table("calls").eq("id", conversation_id).limit(1).execute()
    if not rows:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return rows[0]


@router.post("/")
async def create_conversation(request: Request):
    payload: dict = await request.json()
    title: str = payload.get("title", "").strip()
    if not title:
        raise HTTPException(status_code=400, detail="title is required")

    now = datetime.now(timezone.utc).isoformat()
    data = {
        "title": title,
        "participants": payload.get("participants", []),
        "deal_id": payload.get("lead_id") or payload.get("deal_id"),
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


@router.post("/{conversation_id}/analyze")
async def analyze_conversation(conversation_id: int):
    db = get_db()
    rows = await db.table("calls").eq("id", conversation_id).limit(1).execute()
    if not rows:
        raise HTTPException(status_code=404, detail="Conversation not found")
    conv = rows[0]
    if not conv.get("transcript"):
        raise HTTPException(status_code=400, detail="No transcript available")

    analysis = analyze_transcript(conv["transcript"])
    return await db.table("calls").eq("id", conversation_id).update(_analysis_fields(analysis))


@router.delete("/{conversation_id}")
async def delete_conversation(conversation_id: int):
    db = get_db()
    await db.table("calls").eq("id", conversation_id).delete()
    return {"ok": True}


def _analysis_fields(analysis: dict) -> dict:
    return {
        "summary": analysis.get("summary", ""),
        "sentiment": analysis.get("sentiment", "neutral"),
        "keywords": analysis.get("keywords", []),
        "next_steps": analysis.get("next_steps", []),
        "talk_ratio": analysis.get("talk_ratio", {"rep": 50, "prospect": 50}),
    }
