"""Visitors router — returns demo/mock data for real-time website visitor tracking."""
from fastapi import APIRouter
from datetime import datetime, timezone, timedelta
import random

router = APIRouter(prefix="/api/visitors", tags=["visitors"])

# Demo visitor data (in production this would come from a tracking pixel + IP enrichment service)
DEMO_VISITORS = [
    {"id": 1, "company": "Salesforce Japan", "location": "東京都", "pages": 8, "time_on_site": 720, "intent_score": 94, "status": "active", "current_page": "料金プランページ", "source": "Google広告"},
    {"id": 2, "company": "NTTデータ株式会社", "location": "東京都", "pages": 5, "time_on_site": 480, "intent_score": 91, "status": "chatting", "current_page": "デモ申込ページ", "source": "有機検索"},
    {"id": 3, "company": "トヨタ自動車", "location": "愛知県", "pages": 6, "time_on_site": 540, "intent_score": 87, "status": "active", "current_page": "機能詳細ページ", "source": "LinkedIn"},
    {"id": 4, "company": "ソフトバンク株式会社", "location": "東京都", "pages": 3, "time_on_site": 180, "intent_score": 72, "status": "active", "current_page": "トップページ", "source": "有機検索"},
    {"id": 5, "company": "株式会社リクルート", "location": "東京都", "pages": 4, "time_on_site": 360, "intent_score": 68, "status": "active", "current_page": "導入事例ページ", "source": "参照リンク"},
    {"id": 6, "company": "KDDI株式会社", "location": "東京都", "pages": 2, "time_on_site": 120, "intent_score": 55, "status": "left", "current_page": "トップページ", "source": "メール"},
    {"id": 7, "company": "パナソニック株式会社", "location": "大阪府", "pages": 7, "time_on_site": 600, "intent_score": 83, "status": "qualified", "current_page": "統合ページ", "source": "Google広告"},
    {"id": 8, "company": "富士通株式会社", "location": "東京都", "pages": 3, "time_on_site": 240, "intent_score": 61, "status": "active", "current_page": "ブログ記事", "source": "有機検索"},
    {"id": 9, "company": "株式会社NEC", "location": "東京都", "pages": 5, "time_on_site": 420, "intent_score": 79, "status": "chatting", "current_page": "セキュリティページ", "source": "LinkedIn"},
    {"id": 10, "company": "キヤノン株式会社", "location": "東京都", "pages": 2, "time_on_site": 90, "intent_score": 42, "status": "left", "current_page": "採用ページ", "source": "有機検索"},
    {"id": 11, "company": "本田技研工業", "location": "埼玉県", "pages": 4, "time_on_site": 300, "intent_score": 74, "status": "active", "current_page": "機能詳細ページ", "source": "Twitter"},
    {"id": 12, "company": "三菱電機株式会社", "location": "東京都", "pages": 6, "time_on_site": 500, "intent_score": 88, "status": "active", "current_page": "料金プランページ", "source": "Google広告"},
]


@router.get("/")
async def list_visitors(status: str = "", min_score: int = 0, limit: int = 50):
    visitors = DEMO_VISITORS
    if status:
        visitors = [v for v in visitors if v["status"] == status]
    if min_score > 0:
        visitors = [v for v in visitors if v["intent_score"] >= min_score]
    return visitors[:limit]


@router.get("/summary")
async def get_visitor_summary():
    active = sum(1 for v in DEMO_VISITORS if v["status"] in ("active", "chatting"))
    high_intent = sum(1 for v in DEMO_VISITORS if v["intent_score"] >= 80)
    chatting = sum(1 for v in DEMO_VISITORS if v["status"] == "chatting")
    return {
        "active_visitors": active,
        "high_intent": high_intent,
        "chatting": chatting,
        "total_today": len(DEMO_VISITORS),
    }
