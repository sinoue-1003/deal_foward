"""Seed the database with sample data for demonstration."""
from datetime import datetime, timedelta
import random
from sqlalchemy.orm import Session
from models.call import Call
from models.deal import Deal


STAGES = ["prospect", "qualify", "demo", "proposal", "negotiation", "closed_won", "closed_lost"]
STAGE_PROB = {"prospect": 10, "qualify": 25, "demo": 40, "proposal": 60, "negotiation": 80, "closed_won": 100, "closed_lost": 0}

SAMPLE_DEALS = [
    {"name": "エンタープライズ契約", "company": "株式会社テクノフロント", "stage": "negotiation", "amount": 4800000, "owner": "田中 太郎", "contact_name": "山田 花子"},
    {"name": "SaaS導入プロジェクト", "company": "フューチャーソリューションズ", "stage": "proposal", "amount": 2400000, "owner": "鈴木 一郎", "contact_name": "佐藤 次郎"},
    {"name": "クラウド移行支援", "company": "グローバルコープ株式会社", "stage": "demo", "amount": 1800000, "owner": "田中 太郎", "contact_name": "中村 三郎"},
    {"name": "データ分析基盤構築", "company": "イノベーション工業", "stage": "qualify", "amount": 3600000, "owner": "高橋 花子", "contact_name": "渡辺 四郎"},
    {"name": "セキュリティ監査サービス", "company": "セーフガード株式会社", "stage": "closed_won", "amount": 960000, "owner": "鈴木 一郎", "contact_name": "伊藤 五郎"},
    {"name": "ERPシステム更新", "company": "大阪製造", "stage": "closed_lost", "amount": 7200000, "owner": "田中 太郎", "contact_name": "加藤 六郎"},
    {"name": "AI活用コンサルティング", "company": "デジタルパイオニア", "stage": "prospect", "amount": 1200000, "owner": "高橋 花子", "contact_name": "吉田 七子"},
    {"name": "顧客管理システム刷新", "company": "リテールジャパン株式会社", "stage": "demo", "amount": 2100000, "owner": "鈴木 一郎", "contact_name": "小林 八郎"},
]

SAMPLE_TRANSCRIPTS = [
    """田中: こんにちは、田中です。本日はお時間をいただきありがとうございます。
山田: こちらこそよろしくお願いします。御社のプロダクトに興味があります。
田中: ありがとうございます。まず、現在どのような課題をお持ちか聞かせていただけますか？
山田: 主に営業の効率化ですね。商談の進捗管理が難しくて。
田中: 弊社のソリューションはまさにそこに特化しています。月間どれくらいの商談を管理していますか？
山田: だいたい50件くらいです。Salesforceも使っているんですが、入力が大変で。
田中: なるほど。弊社のツールはSalesforceと連携できますので、入力の手間を大幅に削減できます。
山田: それは魅力的ですね。価格はどのくらいですか？
田中: チームの規模によりますが、10名で月40万円からです。デモを見ていただけますか？
山田: はい、ぜひ見たいです。来週あたりはいかがですか？""",

    """鈴木: 鈴木です。先日お送りした提案書についてご質問がありますか？
佐藤: はい。競合他社のSalesforceと比べてどう違うのか教えてください。
鈴木: 大きな違いは2点あります。まず、AIによる商談分析機能が充実しています。
佐藤: 具体的にどんな分析ができるんですか？
鈴木: 営業担当者の発話比率、感情分析、次のアクション提案などです。
佐藤: なるほど。導入コストはどのくらいかかりますか？
鈴木: 初期費用50万円、月額20万円です。ROIは通常6ヶ月で回収できています。
佐藤: 少し高いですね。ディスカウントは可能ですか？
鈴木: 年間契約をいただければ20%割引が可能です。ご検討いただけますか？
佐藤: 上司に相談してから回答します。1週間ほどお待ちください。""",
]


def seed(db: Session):
    if db.query(Deal).count() > 0:
        return  # Already seeded

    now = datetime.utcnow()

    # Create deals
    deals = []
    for d in SAMPLE_DEALS:
        deal = Deal(
            name=d["name"],
            company=d["company"],
            stage=d["stage"],
            amount=d["amount"],
            probability=STAGE_PROB[d["stage"]],
            owner=d["owner"],
            contact_name=d["contact_name"],
            contact_email=f"{d['contact_name'].replace(' ', '').lower()}@example.com",
            competitors=random.sample(["Salesforce", "HubSpot", "Pipedrive", "Zoho"], k=random.randint(0, 2)),
            close_date=now + timedelta(days=random.randint(7, 90)),
            created_at=now - timedelta(days=random.randint(10, 60)),
        )
        db.add(deal)
        deals.append(deal)

    db.flush()

    # Create calls
    participants_pool = [
        [{"name": "田中 太郎", "role": "rep"}, {"name": "山田 花子", "role": "prospect"}],
        [{"name": "鈴木 一郎", "role": "rep"}, {"name": "佐藤 次郎", "role": "prospect"}],
        [{"name": "高橋 花子", "role": "rep"}, {"name": "渡辺 四郎", "role": "prospect"}],
    ]

    call_titles = [
        "初回ディスカバリーコール", "製品デモセッション", "提案書レビュー",
        "価格交渉ミーティング", "フォローアップコール", "技術要件確認",
        "意思決定者ミーティング", "クロージングコール",
    ]

    for i in range(12):
        participants = random.choice(participants_pool)
        transcript = random.choice(SAMPLE_TRANSCRIPTS) if i % 3 != 0 else None
        deal = random.choice(deals)

        call = Call(
            title=random.choice(call_titles),
            date=now - timedelta(days=random.randint(0, 30), hours=random.randint(0, 8)),
            duration_seconds=random.randint(600, 3600),
            participants=participants,
            transcript=transcript,
            summary="営業担当者が顧客の課題を確認し、ソリューションを提案。次のステップとしてデモを設定。" if transcript else None,
            sentiment=random.choice(["positive", "positive", "neutral", "negative"]),
            keywords=random.sample(["価格", "機能", "導入期間", "ROI", "競合", "デモ", "意思決定", "予算", "サポート"], k=random.randint(3, 6)),
            next_steps=["デモの日程調整", "見積書の送付"] if transcript else [],
            talk_ratio={"rep": random.randint(40, 65), "prospect": random.randint(35, 60)},
            deal_id=deal.id,
            created_at=now - timedelta(days=random.randint(0, 30)),
        )
        db.add(call)

    db.commit()
