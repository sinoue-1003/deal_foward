import os
import json
from anthropic import Anthropic

client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY", ""))


def analyze_transcript(transcript: str) -> dict:
    """Analyze a call transcript using Claude to extract insights."""
    if not transcript:
        return _empty_analysis()

    prompt = f"""以下は営業通話のトランスクリプトです。分析して以下の情報をJSON形式で返してください:

1. summary: 通話の要約（200文字以内）
2. sentiment: 全体的な感情トーン（"positive", "neutral", "negative" のいずれか）
3. keywords: 重要なキーワード・トピック（最大10個のリスト）
4. next_steps: 次のアクション項目（最大5個のリスト）
5. talk_ratio: 発話比率 {{"rep": 数値(0-100), "prospect": 数値(0-100)}}
6. competitors: 言及された競合他社（リスト）
7. objections: 顧客の懸念・反論（リスト）

必ずJSON形式のみで返してください。

トランスクリプト:
{transcript[:4000]}"""

    try:
        message = client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=1024,
            messages=[{"role": "user", "content": prompt}],
        )
        content = message.content[0].text.strip()
        if content.startswith("```"):
            content = content.split("```")[1]
            if content.startswith("json"):
                content = content[4:]
        return json.loads(content)
    except Exception:
        return _empty_analysis()


def _empty_analysis() -> dict:
    return {
        "summary": "",
        "sentiment": "neutral",
        "keywords": [],
        "next_steps": [],
        "talk_ratio": {"rep": 50, "prospect": 50},
        "competitors": [],
        "objections": [],
    }
