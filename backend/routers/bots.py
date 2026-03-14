from fastapi import APIRouter, HTTPException, Request

from services.recording_bot import create_bot, stop_bot, get_bot, list_bots, _detect_platform

router = APIRouter(prefix="/api/bots", tags=["bots"])


@router.post("/")
async def start_bot(request: Request):
    """
    Start a recording bot that joins a meeting and records it.

    Body:
      meeting_url  (str, required)  – Zoom / Google Meet / Teams URL
      bot_name     (str)            – Display name shown in the meeting
      deal_id      (int)            – Link the resulting call to a deal
      title        (str)            – Title for the saved call record
    """
    payload: dict = await request.json()
    meeting_url: str = payload.get("meeting_url", "").strip()
    if not meeting_url:
        raise HTTPException(status_code=400, detail="meeting_url is required")

    # Validate URL is a supported platform before launching
    try:
        _detect_platform(meeting_url)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    bot = await create_bot(
        meeting_url=meeting_url,
        bot_name=payload.get("bot_name", "DealForward Bot"),
        deal_id=payload.get("deal_id"),
        title=payload.get("title"),
    )
    return bot.to_dict()


@router.get("/")
async def get_bots():
    """List all recording bot instances (in-memory, resets on server restart)."""
    return list_bots()


@router.get("/{bot_id}")
async def get_bot_status(bot_id: str):
    """Get the current status of a recording bot."""
    bot = get_bot(bot_id)
    if not bot:
        raise HTTPException(status_code=404, detail="Bot not found")
    return bot.to_dict()


@router.post("/{bot_id}/stop")
async def stop_bot_endpoint(bot_id: str):
    """Stop a running recording bot and trigger transcription + analysis."""
    bot = await stop_bot(bot_id)
    if not bot:
        raise HTTPException(status_code=404, detail="Bot not found")
    return bot.to_dict()
