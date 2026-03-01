from datetime import datetime, timedelta, timezone
from fastapi import APIRouter

from db import get_db

router = APIRouter(prefix="/api/analytics", tags=["analytics"])

OPEN_STAGES = {"prospect", "qualify", "demo", "proposal", "negotiation"}
STAGE_LABELS = {
    "prospect": "見込み客", "qualify": "資格確認", "demo": "デモ",
    "proposal": "提案", "negotiation": "交渉",
    "closed_won": "成約", "closed_lost": "失注",
}
ALL_STAGES = list(STAGE_LABELS.keys())


@router.get("/overview")
async def get_overview():
    db = get_db()
    deals, calls = await _fetch_all(db)

    now = datetime.now(timezone.utc)
    cutoff = (now - timedelta(days=30)).isoformat()

    open_d = [d for d in deals if d["stage"] in OPEN_STAGES]
    won    = [d for d in deals if d["stage"] == "closed_won"]
    lost   = [d for d in deals if d["stage"] == "closed_lost"]

    pipeline_value = sum(d["amount"] for d in open_d)
    won_value      = sum(d["amount"] for d in won)
    win_rate = round(len(won) / (len(won) + len(lost)) * 100) if (won or lost) else 0

    recent = [c for c in calls if (c.get("date") or "") >= cutoff]
    avg_dur = (sum(c["duration_seconds"] for c in calls) / len(calls)) if calls else 0

    sentiment: dict[str, int] = {}
    for s in ("positive", "neutral", "negative"):
        sentiment[s] = sum(1 for c in calls if c.get("sentiment") == s)

    return {
        "deals": {
            "total": len(deals),
            "open": len(open_d),
            "won": len(won),
            "lost": len(lost),
            "win_rate": win_rate,
            "pipeline_value": pipeline_value,
            "won_value": won_value,
        },
        "calls": {
            "total": len(calls),
            "recent_30d": len(recent),
            "avg_duration_seconds": round(avg_dur),
        },
        "sentiment": sentiment,
    }


@router.get("/pipeline")
async def get_pipeline():
    db = get_db()
    deals, _ = await _fetch_all(db)

    return [
        {
            "stage": stage,
            "label": STAGE_LABELS[stage],
            "count": sum(1 for d in deals if d["stage"] == stage),
            "total_amount": sum(d["amount"] for d in deals if d["stage"] == stage),
        }
        for stage in ALL_STAGES
    ]


@router.get("/call-trends")
async def get_call_trends(days: int = 30):
    db = get_db()
    now = datetime.now(timezone.utc)
    cutoff = (now - timedelta(days=days)).isoformat()

    calls = await db.table("calls").gte("date", cutoff).execute()

    # Build daily buckets
    daily: dict[str, dict] = {}
    for i in range(days + 1):
        key = (now - timedelta(days=days - i)).strftime("%Y-%m-%d")
        daily[key] = {"date": key, "count": 0, "_dur": []}

    for c in calls:
        key = (c.get("date") or "")[:10]
        if key in daily:
            daily[key]["count"] += 1
            daily[key]["_dur"].append(c["duration_seconds"])

    result = []
    for key in sorted(daily):
        entry = daily[key]
        durs = entry.pop("_dur")
        entry["avg_duration"] = round(sum(durs) / len(durs)) if durs else 0
        result.append(entry)
    return result


async def _fetch_all(db) -> tuple[list, list]:
    import asyncio
    deals, calls = await asyncio.gather(
        db.table("deals").execute(),
        db.table("calls").execute(),
    )
    return deals, calls
