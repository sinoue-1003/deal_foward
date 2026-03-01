from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

from database import get_db
from models.deal import Deal
from models.call import Call

router = APIRouter(prefix="/api/deals", tags=["deals"])

VALID_STAGES = ["prospect", "qualify", "demo", "proposal", "negotiation", "closed_won", "closed_lost"]


class DealCreate(BaseModel):
    name: str
    company: str
    stage: str
    amount: float
    probability: int
    owner: str
    contact_name: Optional[str] = None
    contact_email: Optional[str] = None
    notes: Optional[str] = None
    competitors: list[str] = []
    close_date: Optional[datetime] = None


class DealUpdate(BaseModel):
    name: Optional[str] = None
    company: Optional[str] = None
    stage: Optional[str] = None
    amount: Optional[float] = None
    probability: Optional[int] = None
    owner: Optional[str] = None
    contact_name: Optional[str] = None
    contact_email: Optional[str] = None
    notes: Optional[str] = None
    competitors: Optional[list[str]] = None
    close_date: Optional[datetime] = None


@router.get("/")
def list_deals(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    deals = db.query(Deal).order_by(Deal.created_at.desc()).offset(skip).limit(limit).all()
    return [_serialize(d) for d in deals]


@router.get("/{deal_id}")
def get_deal(deal_id: int, db: Session = Depends(get_db)):
    deal = db.query(Deal).filter(Deal.id == deal_id).first()
    if not deal:
        raise HTTPException(status_code=404, detail="Deal not found")
    calls = db.query(Call).filter(Call.deal_id == deal_id).order_by(Call.date.desc()).all()
    result = _serialize(deal)
    result["calls"] = [
        {"id": c.id, "title": c.title, "date": c.date.isoformat() if c.date else None,
         "duration_seconds": c.duration_seconds, "sentiment": c.sentiment}
        for c in calls
    ]
    return result


@router.post("/")
def create_deal(payload: DealCreate, db: Session = Depends(get_db)):
    if payload.stage not in VALID_STAGES:
        raise HTTPException(status_code=400, detail=f"Invalid stage. Must be one of: {VALID_STAGES}")
    deal = Deal(**payload.model_dump())
    db.add(deal)
    db.commit()
    db.refresh(deal)
    return _serialize(deal)


@router.patch("/{deal_id}")
def update_deal(deal_id: int, payload: DealUpdate, db: Session = Depends(get_db)):
    deal = db.query(Deal).filter(Deal.id == deal_id).first()
    if not deal:
        raise HTTPException(status_code=404, detail="Deal not found")
    if payload.stage and payload.stage not in VALID_STAGES:
        raise HTTPException(status_code=400, detail=f"Invalid stage. Must be one of: {VALID_STAGES}")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(deal, field, value)
    deal.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(deal)
    return _serialize(deal)


@router.delete("/{deal_id}")
def delete_deal(deal_id: int, db: Session = Depends(get_db)):
    deal = db.query(Deal).filter(Deal.id == deal_id).first()
    if not deal:
        raise HTTPException(status_code=404, detail="Deal not found")
    db.delete(deal)
    db.commit()
    return {"ok": True}


def _serialize(deal: Deal) -> dict:
    return {
        "id": deal.id,
        "name": deal.name,
        "company": deal.company,
        "stage": deal.stage,
        "amount": deal.amount,
        "probability": deal.probability,
        "owner": deal.owner,
        "contact_name": deal.contact_name,
        "contact_email": deal.contact_email,
        "notes": deal.notes,
        "competitors": deal.competitors or [],
        "close_date": deal.close_date.isoformat() if deal.close_date else None,
        "created_at": deal.created_at.isoformat() if deal.created_at else None,
        "updated_at": deal.updated_at.isoformat() if deal.updated_at else None,
    }
