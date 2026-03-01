from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timedelta

from database import get_db
from models.call import Call
from models.deal import Deal

router = APIRouter(prefix="/api/analytics", tags=["analytics"])


@router.get("/overview")
def get_overview(db: Session = Depends(get_db)):
    now = datetime.utcnow()
    thirty_days_ago = now - timedelta(days=30)

    total_deals = db.query(Deal).count()
    open_deals = db.query(Deal).filter(Deal.stage.notin_(["closed_won", "closed_lost"])).count()
    won_deals = db.query(Deal).filter(Deal.stage == "closed_won").count()
    lost_deals = db.query(Deal).filter(Deal.stage == "closed_lost").count()

    pipeline_value = db.query(func.sum(Deal.amount)).filter(
        Deal.stage.notin_(["closed_won", "closed_lost"])
    ).scalar() or 0

    won_value = db.query(func.sum(Deal.amount)).filter(Deal.stage == "closed_won").scalar() or 0

    total_calls = db.query(Call).count()
    recent_calls = db.query(Call).filter(Call.date >= thirty_days_ago).count()

    avg_duration = db.query(func.avg(Call.duration_seconds)).scalar() or 0

    sentiment_counts = {}
    for sentiment in ["positive", "neutral", "negative"]:
        count = db.query(Call).filter(Call.sentiment == sentiment).count()
        sentiment_counts[sentiment] = count

    win_rate = round(won_deals / (won_deals + lost_deals) * 100) if (won_deals + lost_deals) > 0 else 0

    return {
        "deals": {
            "total": total_deals,
            "open": open_deals,
            "won": won_deals,
            "lost": lost_deals,
            "win_rate": win_rate,
            "pipeline_value": pipeline_value,
            "won_value": won_value,
        },
        "calls": {
            "total": total_calls,
            "recent_30d": recent_calls,
            "avg_duration_seconds": round(avg_duration),
        },
        "sentiment": sentiment_counts,
    }


@router.get("/pipeline")
def get_pipeline(db: Session = Depends(get_db)):
    stages = ["prospect", "qualify", "demo", "proposal", "negotiation", "closed_won", "closed_lost"]
    stage_labels = {
        "prospect": "見込み客",
        "qualify": "資格確認",
        "demo": "デモ",
        "proposal": "提案",
        "negotiation": "交渉",
        "closed_won": "成約",
        "closed_lost": "失注",
    }
    pipeline = []
    for stage in stages:
        deals = db.query(Deal).filter(Deal.stage == stage).all()
        total_amount = sum(d.amount for d in deals)
        pipeline.append({
            "stage": stage,
            "label": stage_labels[stage],
            "count": len(deals),
            "total_amount": total_amount,
        })
    return pipeline


@router.get("/call-trends")
def get_call_trends(days: int = 30, db: Session = Depends(get_db)):
    now = datetime.utcnow()
    start = now - timedelta(days=days)

    calls = db.query(Call).filter(Call.date >= start).all()

    daily = {}
    current = start
    while current <= now:
        key = current.strftime("%Y-%m-%d")
        daily[key] = {"date": key, "count": 0, "avg_duration": 0, "durations": []}
        current += timedelta(days=1)

    for call in calls:
        key = call.date.strftime("%Y-%m-%d")
        if key in daily:
            daily[key]["count"] += 1
            daily[key]["durations"].append(call.duration_seconds)

    result = []
    for key in sorted(daily.keys()):
        entry = daily[key]
        durations = entry.pop("durations")
        entry["avg_duration"] = round(sum(durations) / len(durations)) if durations else 0
        result.append(entry)

    return result
