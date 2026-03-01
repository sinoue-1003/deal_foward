import os
import aiofiles
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

from database import get_db
from models.call import Call
from services.transcription import transcribe_audio
from services.ai_analysis import analyze_transcript

router = APIRouter(prefix="/api/calls", tags=["calls"])

UPLOAD_DIR = "data/uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)


class CallCreate(BaseModel):
    title: str
    participants: list[dict]
    deal_id: Optional[int] = None
    transcript: Optional[str] = None


class CallUpdate(BaseModel):
    title: Optional[str] = None
    deal_id: Optional[int] = None
    transcript: Optional[str] = None


@router.get("/")
def list_calls(skip: int = 0, limit: int = 50, db: Session = Depends(get_db)):
    calls = db.query(Call).order_by(Call.date.desc()).offset(skip).limit(limit).all()
    return [_serialize(c) for c in calls]


@router.get("/{call_id}")
def get_call(call_id: int, db: Session = Depends(get_db)):
    call = db.query(Call).filter(Call.id == call_id).first()
    if not call:
        raise HTTPException(status_code=404, detail="Call not found")
    return _serialize(call)


@router.post("/")
def create_call(payload: CallCreate, db: Session = Depends(get_db)):
    call = Call(
        title=payload.title,
        participants=payload.participants,
        deal_id=payload.deal_id,
        transcript=payload.transcript,
    )
    if payload.transcript:
        analysis = analyze_transcript(payload.transcript)
        _apply_analysis(call, analysis)

    db.add(call)
    db.commit()
    db.refresh(call)
    return _serialize(call)


@router.post("/{call_id}/upload")
async def upload_audio(
    call_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    call = db.query(Call).filter(Call.id == call_id).first()
    if not call:
        raise HTTPException(status_code=404, detail="Call not found")

    audio_path = os.path.join(UPLOAD_DIR, f"{call_id}_{file.filename}")
    async with aiofiles.open(audio_path, "wb") as f:
        content = await file.read()
        await f.write(content)

    call.audio_path = audio_path
    transcript = transcribe_audio(audio_path)
    call.transcript = transcript

    analysis = analyze_transcript(transcript)
    _apply_analysis(call, analysis)

    db.commit()
    db.refresh(call)
    return _serialize(call)


@router.post("/{call_id}/analyze")
def analyze_call(call_id: int, db: Session = Depends(get_db)):
    call = db.query(Call).filter(Call.id == call_id).first()
    if not call:
        raise HTTPException(status_code=404, detail="Call not found")
    if not call.transcript:
        raise HTTPException(status_code=400, detail="No transcript available")

    analysis = analyze_transcript(call.transcript)
    _apply_analysis(call, analysis)
    db.commit()
    db.refresh(call)
    return _serialize(call)


@router.delete("/{call_id}")
def delete_call(call_id: int, db: Session = Depends(get_db)):
    call = db.query(Call).filter(Call.id == call_id).first()
    if not call:
        raise HTTPException(status_code=404, detail="Call not found")
    db.delete(call)
    db.commit()
    return {"ok": True}


def _serialize(call: Call) -> dict:
    return {
        "id": call.id,
        "title": call.title,
        "date": call.date.isoformat() if call.date else None,
        "duration_seconds": call.duration_seconds,
        "participants": call.participants or [],
        "audio_path": call.audio_path,
        "transcript": call.transcript,
        "summary": call.summary,
        "sentiment": call.sentiment,
        "keywords": call.keywords or [],
        "next_steps": call.next_steps or [],
        "talk_ratio": call.talk_ratio or {"rep": 50, "prospect": 50},
        "deal_id": call.deal_id,
        "created_at": call.created_at.isoformat() if call.created_at else None,
    }


def _apply_analysis(call: Call, analysis: dict):
    call.summary = analysis.get("summary", "")
    call.sentiment = analysis.get("sentiment", "neutral")
    call.keywords = analysis.get("keywords", [])
    call.next_steps = analysis.get("next_steps", [])
    call.talk_ratio = analysis.get("talk_ratio", {"rep": 50, "prospect": 50})
