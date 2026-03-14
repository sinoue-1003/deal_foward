"""
Recording bot service — joins Zoom / Google Meet / Teams meetings,
records audio with FFmpeg + PulseAudio virtual sink, then transcribes
and analyses the recording via the existing pipeline.

System requirements:
  - Playwright + Chromium: `pip install playwright && playwright install chromium`
  - FFmpeg: `apt install ffmpeg`
  - PulseAudio: `apt install pulseaudio` (runs as a virtual audio sink)
"""
import asyncio
import logging
import os
import subprocess
import uuid
from datetime import datetime, timezone
from enum import Enum
from pathlib import Path
from typing import Dict, Optional

logger = logging.getLogger(__name__)

RECORDINGS_DIR = Path(os.getenv("RECORDINGS_DIR", "/tmp/recordings"))
RECORDINGS_DIR.mkdir(parents=True, exist_ok=True)

BOT_DEFAULT_NAME = os.getenv("BOT_NAME", "DealForward Bot")


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

class Platform(str, Enum):
    ZOOM = "zoom"
    GOOGLE_MEET = "google_meet"
    TEAMS = "teams"


class BotStatus(str, Enum):
    PENDING = "pending"
    JOINING = "joining"
    RECORDING = "recording"
    PROCESSING = "processing"
    DONE = "done"
    ERROR = "error"


# ---------------------------------------------------------------------------
# Bot instance
# ---------------------------------------------------------------------------

class BotInstance:
    def __init__(
        self,
        bot_id: str,
        meeting_url: str,
        bot_name: str,
        deal_id: Optional[int],
        title: Optional[str],
    ):
        self.bot_id = bot_id
        self.meeting_url = meeting_url
        self.bot_name = bot_name
        self.platform = _detect_platform(meeting_url)
        self.deal_id = deal_id
        self.title = title

        self.status = BotStatus.PENDING
        self.started_at: Optional[datetime] = None
        self.ended_at: Optional[datetime] = None
        self.audio_path: Optional[str] = None
        self.call_id: Optional[int] = None
        self.error: Optional[str] = None

        self._sink_name: Optional[str] = None
        self._sink_module_id: Optional[str] = None
        self._ffmpeg_proc: Optional[subprocess.Popen] = None
        self._task: Optional[asyncio.Task] = None

    def to_dict(self) -> dict:
        return {
            "bot_id": self.bot_id,
            "meeting_url": self.meeting_url,
            "bot_name": self.bot_name,
            "platform": self.platform,
            "deal_id": self.deal_id,
            "title": self.title,
            "status": self.status,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "ended_at": self.ended_at.isoformat() if self.ended_at else None,
            "call_id": self.call_id,
            "error": self.error,
        }


# ---------------------------------------------------------------------------
# In-memory registry
# ---------------------------------------------------------------------------

_bots: Dict[str, BotInstance] = {}


def get_bot(bot_id: str) -> Optional[BotInstance]:
    return _bots.get(bot_id)


def list_bots() -> list:
    return [b.to_dict() for b in _bots.values()]


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

async def create_bot(
    meeting_url: str,
    bot_name: str = BOT_DEFAULT_NAME,
    deal_id: Optional[int] = None,
    title: Optional[str] = None,
) -> BotInstance:
    bot_id = str(uuid.uuid4())
    bot = BotInstance(bot_id, meeting_url, bot_name, deal_id, title)
    _bots[bot_id] = bot
    bot._task = asyncio.create_task(_run_bot(bot))
    return bot


async def stop_bot(bot_id: str) -> Optional[BotInstance]:
    bot = _bots.get(bot_id)
    if not bot:
        return None

    # Stop FFmpeg → triggers processing
    _stop_ffmpeg(bot)

    if bot._task and not bot._task.done():
        bot._task.cancel()

    if bot.status == BotStatus.RECORDING:
        bot.status = BotStatus.PROCESSING
        bot.ended_at = datetime.now(timezone.utc)
        if bot.audio_path and Path(bot.audio_path).exists():
            asyncio.create_task(_process_recording(bot))

    return bot


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _detect_platform(url: str) -> Platform:
    if "zoom.us" in url or "zoom.com" in url:
        return Platform.ZOOM
    if "meet.google.com" in url:
        return Platform.GOOGLE_MEET
    if "teams.microsoft.com" in url or "teams.live.com" in url:
        return Platform.TEAMS
    raise ValueError(f"Unsupported meeting URL: {url}")


def _stop_ffmpeg(bot: BotInstance) -> None:
    if bot._ffmpeg_proc and bot._ffmpeg_proc.poll() is None:
        bot._ffmpeg_proc.terminate()
        try:
            bot._ffmpeg_proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            bot._ffmpeg_proc.kill()


def _unload_pulse_sink(bot: BotInstance) -> None:
    if bot._sink_module_id:
        try:
            subprocess.run(
                ["pactl", "unload-module", bot._sink_module_id],
                check=False, capture_output=True,
            )
        except FileNotFoundError:
            pass  # pactl not available


# ---------------------------------------------------------------------------
# Core bot runner
# ---------------------------------------------------------------------------

async def _run_bot(bot: BotInstance) -> None:
    try:
        bot.status = BotStatus.JOINING
        bot.started_at = datetime.now(timezone.utc)

        # Create a PulseAudio virtual null-sink so browser audio is captured.
        sink_name = f"dfbot_{bot.bot_id.replace('-', '_')}"
        bot._sink_name = sink_name
        try:
            result = subprocess.run(
                ["pactl", "load-module", "module-null-sink",
                 f"sink_name={sink_name}",
                 f"sink_properties=device.description={sink_name}"],
                capture_output=True, text=True, check=True,
            )
            bot._sink_module_id = result.stdout.strip()
        except (FileNotFoundError, subprocess.CalledProcessError) as e:
            logger.warning("PulseAudio not available, audio capture may fail: %s", e)
            sink_name = "default"

        from playwright.async_api import async_playwright

        async with async_playwright() as pw:
            browser = await pw.chromium.launch(
                headless=True,
                env={**os.environ, "PULSE_SINK": sink_name},
                args=[
                    "--no-sandbox",
                    "--disable-setuid-sandbox",
                    "--use-fake-ui-for-media-stream",
                    "--disable-web-security",
                    "--allow-running-insecure-content",
                    "--autoplay-policy=no-user-gesture-required",
                ],
            )
            context = await browser.new_context(
                permissions=["microphone", "camera"],
            )
            page = await context.new_page()

            # Join the meeting
            if bot.platform == Platform.ZOOM:
                await _join_zoom(page, bot)
            elif bot.platform == Platform.GOOGLE_MEET:
                await _join_google_meet(page, bot)
            elif bot.platform == Platform.TEAMS:
                await _join_teams(page, bot)

            bot.status = BotStatus.RECORDING

            # Start FFmpeg recording from virtual sink monitor
            audio_file = str(RECORDINGS_DIR / f"{bot.bot_id}.wav")
            bot.audio_path = audio_file
            pulse_source = f"{sink_name}.monitor" if sink_name != "default" else "default"
            bot._ffmpeg_proc = subprocess.Popen(
                [
                    "ffmpeg", "-y",
                    "-f", "pulse", "-i", pulse_source,
                    "-ar", "16000", "-ac", "1",
                    audio_file,
                ],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            logger.info("Bot %s recording started (platform=%s)", bot.bot_id, bot.platform)

            # Monitor meeting — exit when page unloads or bot is stopped
            while bot.status == BotStatus.RECORDING:
                await asyncio.sleep(10)
                try:
                    # Check if browser still has the meeting page
                    if page.is_closed():
                        break
                except Exception:
                    break

            await browser.close()

    except asyncio.CancelledError:
        pass
    except Exception as exc:
        bot.status = BotStatus.ERROR
        bot.error = str(exc)
        logger.exception("Bot %s crashed: %s", bot.bot_id, exc)
    finally:
        _stop_ffmpeg(bot)
        _unload_pulse_sink(bot)
        if bot.ended_at is None:
            bot.ended_at = datetime.now(timezone.utc)

    # Auto-process if recording completed normally
    if bot.status == BotStatus.RECORDING:
        bot.status = BotStatus.PROCESSING
        await _process_recording(bot)


# ---------------------------------------------------------------------------
# Platform-specific join logic
# ---------------------------------------------------------------------------

async def _join_zoom(page, bot: BotInstance) -> None:
    """Join a Zoom meeting via the web client (no app required)."""
    url = bot.meeting_url

    # Convert standard invite URL to web-client URL
    if "/j/" in url:
        meeting_id = url.split("/j/")[1].split("?")[0].replace(" ", "")
        params = url.split("?")[1] if "?" in url else ""
        pwd = ""
        for part in params.split("&"):
            if part.startswith("pwd="):
                pwd = part
                break
        web_url = f"https://zoom.us/wc/{meeting_id}/join?prefer=1&un={bot.bot_name}"
        if pwd:
            web_url += f"&{pwd}"
    else:
        web_url = url

    await page.goto(web_url, timeout=30_000)
    await page.wait_for_timeout(3_000)

    # Dismiss cookie/GDPR banners if present
    for selector in ["#onetrust-accept-btn-handler", "button[data-testid='accept-cookies']"]:
        try:
            if await page.locator(selector).is_visible(timeout=2_000):
                await page.locator(selector).click()
        except Exception:
            pass

    # Click "Join from Your Browser" link
    for text in ["Join from Your Browser", "ブラウザから参加"]:
        try:
            link = page.get_by_text(text, exact=False)
            if await link.is_visible(timeout=5_000):
                await link.click()
                break
        except Exception:
            pass

    await page.wait_for_timeout(2_000)

    # Fill in display name
    for selector in [
        'input[placeholder*="name" i]',
        'input[id*="inputname" i]',
        'input[aria-label*="name" i]',
    ]:
        try:
            inp = page.locator(selector).first
            if await inp.is_visible(timeout=3_000):
                await inp.fill(bot.bot_name)
                break
        except Exception:
            pass

    # Mute mic/camera before joining
    for selector in ["button[aria-label*='mute' i]", "button[aria-label*='ミュート' i]"]:
        try:
            btn = page.locator(selector).first
            if await btn.is_visible(timeout=2_000):
                await btn.click()
        except Exception:
            pass

    # Click Join
    for selector in [
        "button.preview-join-button",
        "button:has-text('Join')",
        "button:has-text('参加')",
    ]:
        try:
            btn = page.locator(selector).first
            if await btn.is_visible(timeout=5_000):
                await btn.click()
                break
        except Exception:
            pass

    await page.wait_for_timeout(5_000)
    logger.info("Bot %s joined Zoom meeting", bot.bot_id)


async def _join_google_meet(page, bot: BotInstance) -> None:
    """Join a Google Meet session as a guest (no Google account required)."""
    await page.goto(bot.meeting_url, timeout=30_000)
    await page.wait_for_timeout(3_000)

    # Dismiss permission/notification dialogs
    for text in ["Got it", "わかりました", "Dismiss", "閉じる"]:
        try:
            btn = page.get_by_role("button", name=text, exact=False)
            if await btn.is_visible(timeout=2_000):
                await btn.click()
        except Exception:
            pass

    # Enter display name if prompted (guest flow)
    for selector in [
        'input[aria-label*="name" i]',
        'input[placeholder*="name" i]',
        'input[data-initial-value]',
    ]:
        try:
            inp = page.locator(selector).first
            if await inp.is_visible(timeout=5_000):
                await inp.fill(bot.bot_name)
                break
        except Exception:
            pass

    # "Ask to join" or "Join now"
    for text in ["Ask to join", "今すぐ参加", "Join now", "参加をリクエスト"]:
        try:
            btn = page.get_by_role("button", name=text, exact=False)
            if await btn.is_visible(timeout=5_000):
                await btn.click()
                break
        except Exception:
            pass

    await page.wait_for_timeout(5_000)
    logger.info("Bot %s joined Google Meet", bot.bot_id)


async def _join_teams(page, bot: BotInstance) -> None:
    """Join a Microsoft Teams meeting via the web client."""
    await page.goto(bot.meeting_url, timeout=30_000)
    await page.wait_for_timeout(3_000)

    # "Join on the web instead" — skip the app prompt
    for selector in [
        "a:has-text('Join on the web')",
        "button:has-text('Join on the web')",
        "a:has-text('ウェブから参加')",
    ]:
        try:
            el = page.locator(selector).first
            if await el.is_visible(timeout=5_000):
                await el.click()
                break
        except Exception:
            pass

    await page.wait_for_timeout(3_000)

    # Enter display name
    for selector in [
        'input[data-tid="prejoin-display-name-input"]',
        'input[placeholder*="name" i]',
        'input[aria-label*="name" i]',
    ]:
        try:
            inp = page.locator(selector).first
            if await inp.is_visible(timeout=5_000):
                await inp.fill(bot.bot_name)
                break
        except Exception:
            pass

    # Mute mic/video before joining
    for selector in [
        'button[data-tid="toggle-mute"]',
        'button[aria-label*="mute" i]',
        'div[data-tid="prejoin-mic-toggle"]',
    ]:
        try:
            btn = page.locator(selector).first
            if await btn.is_visible(timeout=2_000):
                await btn.click()
        except Exception:
            pass

    # Click "Join now"
    for selector in [
        'button[data-tid="prejoin-join-button"]',
        "button:has-text('Join now')",
        "button:has-text('今すぐ参加')",
    ]:
        try:
            btn = page.locator(selector).first
            if await btn.is_visible(timeout=5_000):
                await btn.click()
                break
        except Exception:
            pass

    await page.wait_for_timeout(5_000)
    logger.info("Bot %s joined Teams meeting", bot.bot_id)


# ---------------------------------------------------------------------------
# Post-processing: transcribe + analyse + save to DB
# ---------------------------------------------------------------------------

async def _process_recording(bot: BotInstance) -> None:
    try:
        from services.transcription import transcribe_audio
        from services.ai_analysis import analyze_transcript
        from db import get_db

        audio_path = bot.audio_path
        if not audio_path or not Path(audio_path).exists():
            raise FileNotFoundError(f"Audio file not found: {audio_path}")

        # Transcription is synchronous — run in thread pool
        transcript = await asyncio.to_thread(transcribe_audio, audio_path)

        # Analysis is synchronous — run in thread pool
        analysis = await asyncio.to_thread(analyze_transcript, transcript)

        duration = 0
        if bot.started_at and bot.ended_at:
            duration = int((bot.ended_at - bot.started_at).total_seconds())

        now = datetime.now(timezone.utc).isoformat()
        call_data: dict = {
            "title": bot.title or f"{bot.platform.value.replace('_', ' ').title()} Recording",
            "date": bot.started_at.isoformat() if bot.started_at else now,
            "duration_seconds": duration,
            "participants": [bot.bot_name],
            "audio_path": audio_path,
            "transcript": transcript,
            "summary": analysis.get("summary", ""),
            "sentiment": analysis.get("sentiment", "neutral"),
            "keywords": analysis.get("keywords", []),
            "next_steps": analysis.get("next_steps", []),
            "talk_ratio": analysis.get("talk_ratio", {"rep": 50, "prospect": 50}),
            "created_at": now,
        }
        if bot.deal_id:
            call_data["deal_id"] = bot.deal_id

        db = get_db()
        row = await db.table("calls").insert(call_data)
        bot.call_id = row.get("id")
        bot.status = BotStatus.DONE
        logger.info("Bot %s processing done, call_id=%s", bot.bot_id, bot.call_id)

    except Exception as exc:
        bot.status = BotStatus.ERROR
        bot.error = f"Processing failed: {exc}"
        logger.exception("Bot %s processing error: %s", bot.bot_id, exc)
