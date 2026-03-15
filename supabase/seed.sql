-- Breakout AI seed data (demo)
-- Inbound AI SDR platform demo data
-- Run after 001_initial.sql

TRUNCATE calls, deals RESTART IDENTITY CASCADE;

INSERT INTO deals (name, company, stage, amount, probability, owner, contact_name, contact_email, competitors, close_date, notes) VALUES
  ('山田 花子 / Salesforce Japan',     'Salesforce Japan',           'negotiation',  4800000, 85, '田中 太郎', '山田 花子', 'hanako@salesforce.co.jp',    '["Qualified","Drift"]',         NOW() + INTERVAL '14 days',  '料金ページを3回訪問。デモ後に競合比較をリクエスト。'),
  ('鈴木 一郎 / ソフトバンク',         'ソフトバンク株式会社',        'proposal',     2400000, 62, '佐藤 次郎', '鈴木 一郎', 'ichiro@softbank.co.jp',       '["Intercom"]',                  NOW() + INTERVAL '30 days',  '100名以上チームでの導入。AI会話で予算確認済み。'),
  ('高橋 誠 / NTTデータ',              'NTTデータ株式会社',           'demo',         3600000, 45, '田中 太郎', '高橋 誠', 'makoto@nttdata.co.jp',        '["Drift","HubSpot"]',           NOW() + INTERVAL '45 days',  'エンタープライズプランに関心。セキュリティ要件あり。'),
  ('中村 美咲 / パナソニック',         'パナソニック株式会社',        'qualify',      1800000, 30, '山本 花子', '中村 美咲', 'misaki@panasonic.co.jp',      '["Qualified"]',                 NOW() + INTERVAL '60 days',  '新規事業部門でのインバウンド強化を検討中。'),
  ('伊藤 健一 / トヨタ自動車',         'トヨタ自動車',                'closed_won',    960000,100, '佐藤 次郎', '伊藤 健一', 'kenichi@toyota.co.jp',        '[]',                            NOW() - INTERVAL '5 days',   'Webサイトのコンバージョン率が3倍に。'),
  ('渡辺 直樹 / KDDI',                 'KDDI株式会社',                'closed_lost',  2400000,  0, '田中 太郎', '渡辺 直樹', 'naoki@kddi.co.jp',            '["Salesforce"]',                NOW() - INTERVAL '10 days',  '予算承認が得られず。来年度再検討の可能性あり。'),
  ('加藤 純子 / 三菱電機',             '三菱電機株式会社',            'prospect',     1200000, 15, '山本 花子', '加藤 純子', 'junko@mitsubishi.co.jp',      '[]',                            NOW() + INTERVAL '90 days',  'AI会話でインテントスコア88を記録。高関心。'),
  ('小林 翔 / 富士通',                 '富士通株式会社',              'demo',         2100000, 42, '佐藤 次郎', '小林 翔', 'sho@fujitsu.co.jp',           '["Intercom","Drift"]',          NOW() + INTERVAL '40 days',  'テクニカルデモをリクエスト。API連携が重要要件。');

INSERT INTO calls (title, date, duration_seconds, participants, transcript, summary, sentiment, keywords, next_steps, talk_ratio, deal_id) VALUES
  ('Webサイト訪問者との会話 — Salesforce Japan', NOW() - INTERVAL '25 days', 840,
   '[{"name":"Breakout AI","role":"rep"},{"name":"山田 花子","role":"prospect"}]',
   'Breakout AI: こんにちは！本日はBreakoutのサイトにお越しいただきありがとうございます。何かお手伝いできることはありますか？
訪問者: 料金プランについて詳しく知りたいです。今使っているチャットボットより良いのか確認したいです。
Breakout AI: もちろんです！現在どのようなツールをお使いですか？どんな課題がありますか？
訪問者: Driftを使っていますが、設定が複雑で、AIの回答精度も低くて困っています。
Breakout AI: ご存知ですか？BreakoutはDriftと比べて平均セットアップ時間が80%短く、AIの回答精度も大幅に向上しています。具体的には—
訪問者: 実際のデモを見てみたいです。チームは20名です。
Breakout AI: 素晴らしいです！20名のチームでしたら、スタンダードプランがお勧めです。月額38万円からです。今すぐデモをご予約できますよ。
訪問者: はい、ぜひ。来週の月曜午後はいかがですか？
Breakout AI: 月曜14時はいかがですか？田中 太郎が担当します。確認メールをお送りしますね。',
   'Drift利用中の顧客がコスト・精度の課題を持ち来訪。Breakoutの優位性を説明し、20名チーム向けデモを予約。コンバージョン成功。',
   'positive',
   '["Drift比較","セットアップ","AI精度","20名チーム","デモ予約","月38万円"]',
   '["デモセッションの準備","競合比較資料を準備","20名向け見積書作成"]',
   '{"rep":48,"prospect":52}', 1),

  ('インテントシグナル検知 — ソフトバンク', NOW() - INTERVAL '18 days', 660,
   '[{"name":"Breakout AI","role":"rep"},{"name":"鈴木 一郎","role":"prospect"}]',
   'Breakout AI: こんにちは！料金プランページを複数回ご覧いただいていますね。ご質問はありますか？
訪問者: はい。エンタープライズプランの詳細が知りたいです。今100名のチームがいます。
Breakout AI: 100名規模でしたら、エンタープライズプランをお勧めします。カスタム料金と専任サポートが含まれます。
訪問者: 他社と比べてどうですか？Intercomも検討しています。
Breakout AI: IntercomはCS中心のツールですが、BreakoutはインバウンドB2B営業に特化しています。訪問者の企業識別、リアルタイムアラート、自動ミーティング予約が強みです。
訪問者: 導入事例を見せてもらえますか？
Breakout AI: もちろんです！同規模の会社で3ヶ月でコンバージョン率が2.5倍になった事例があります。詳細をメールでお送りしますね。メールアドレスを教えていただけますか？
訪問者: ichiro@softbank.co.jp です。',
   '100名チームのエンタープライズ需要を確認。Intercomとの差別化を実施。事例資料送付に合意、メールアドレス取得。リード化成功。',
   'positive',
   '["エンタープライズ","100名","Intercom比較","導入事例","メール取得"]',
   '["事例資料をメール送付","デモの日程調整","エンタープライズ見積書作成"]',
   '{"rep":52,"prospect":48}', 2),

  ('プロダクトデモフォロー — NTTデータ', NOW() - INTERVAL '10 days', 720,
   '[{"name":"Breakout AI","role":"rep"},{"name":"高橋 誠","role":"prospect"}]',
   'Breakout AI: こんにちは高橋様。先日のデモはいかがでしたか？ご質問はありますか？
訪問者: デモは良かったです。セキュリティ要件について確認したいことがあります。
Breakout AI: もちろんです。どのようなセキュリティ要件をお持ちですか？
訪問者: SOC2認定はありますか？データの保管場所も重要です。
Breakout AI: Breakoutは SOC2 Type II認定を取得済みで、データは国内データセンターに保管できます。詳細な技術資料をお送りできます。
訪問者: ぜひお願いします。社内の情報セキュリティ部門にも確認が必要です。
Breakout AI: 承知しました。セキュリティチェックリストも一緒にお送りします。フォローアップの日程を設定しましょうか？',
   'デモ後フォロー。SOC2認定とデータ保管場所の確認。セキュリティ資料の送付に合意。情報セキュリティ部門の承認が次ステップ。',
   'neutral',
   '["SOC2","セキュリティ","データ保管","情報セキュリティ部門","技術資料"]',
   '["セキュリティ資料を送付","情報セキュリティ部門向けQ&Aを準備","2週間後フォローアップ"]',
   '{"rep":55,"prospect":45}', 3),

  ('初回訪問 — パナソニック', NOW() - INTERVAL '7 days', 480,
   '[{"name":"Breakout AI","role":"rep"},{"name":"中村 美咲","role":"prospect"}]',
   NULL, NULL, 'neutral', '["インバウンド強化","新規事業","予算検討中"]', '["事業概要資料を送付","デモ日程の調整"]',
   '{"rep":50,"prospect":50}', 4),

  ('成約確認 — トヨタ自動車', NOW() - INTERVAL '5 days', 540,
   '[{"name":"Breakout AI","role":"rep"},{"name":"伊藤 健一","role":"prospect"}]',
   NULL, NULL, 'positive', '["契約締結","オンボーディング","API連携","ROI確認"]', '["契約書に署名","キックオフ日程を確定","技術担当者とAPI連携の打ち合わせ"]',
   '{"rep":40,"prospect":60}', 5),

  ('ハイインテント訪問者 — 三菱電機', NOW() - INTERVAL '3 days', 600,
   '[{"name":"Breakout AI","role":"rep"},{"name":"加藤 純子","role":"prospect"}]',
   'Breakout AI: こんにちは！料金ページと機能ページを複数回ご覧いただいていますね。何かご質問はありますか？
訪問者: はい。新規事業部でインバウンドマーケティングを強化したいと思っています。
Breakout AI: 素晴らしいですね！どのようなインバウンドの課題をお持ちですか？
訪問者: Webサイトの訪問者が誰なのかわからないし、リード化もうまくいっていません。
Breakout AI: まさにBreakoutが解決する課題です！企業識別で訪問者の会社名をリアルタイムで把握し、AIが24時間対応してリード化します。
訪問者: 実際にどのくらいの期間で効果が出ますか？
Breakout AI: 多くのお客様は2〜4週間でリード数が増加し始め、3ヶ月以内にROIを実感されています。
訪問者: 予算の承認が必要なので、まず概要資料をいただけますか？',
   'インバウンドマーケティング強化の需要を確認。企業識別とAIリード化機能への高い関心。予算承認プロセスが必要なため資料送付で合意。',
   'positive',
   '["企業識別","インバウンド","リード化","ROI","予算承認","資料請求"]',
   '["概要資料と料金表を送付","予算承認後のフォローアップ日程設定"]',
   '{"rep":50,"prospect":50}', 7),

  ('テクニカルデモ — 富士通', NOW() - INTERVAL '2 days', 780,
   '[{"name":"Breakout AI","role":"rep"},{"name":"小林 翔","role":"prospect"}]',
   NULL, NULL, 'neutral', '["API連携","Salesforce連携","技術要件","カスタマイズ"]', '["APIドキュメントを送付","技術担当者とのミーティング設定"]',
   '{"rep":58,"prospect":42}', 8),

  ('デモ申込ページ訪問 — 本田技研工業', NOW() - INTERVAL '1 day', 420,
   '[{"name":"Breakout AI","role":"rep"},{"name":"田村 明夫","role":"prospect"}]',
   'Breakout AI: こんにちは！デモ申込ページをご覧いただいていますね。今すぐデモをご予約できますよ。
訪問者: 少し質問があります。Breakoutはどのプラットフォームと連携できますか？
Breakout AI: Salesforce、HubSpot、Slack、Zoomなど50以上のツールと連携しています。現在お使いのツールはありますか？
訪問者: HubSpotです。
Breakout AI: HubSpotとのネイティブ連携があります。会話データが自動的にHubSpotのコンタクトに反映されます。
訪問者: 良いですね。デモを予約したいです。',
   'HubSpot連携への高い関心。デモ予約に合意。インテントスコア高。',
   'positive',
   '["HubSpot連携","デモ予約","ツール連携","即時コンバージョン"]',
   '["デモ日程を確定","HubSpot連携の詳細資料を事前送付"]',
   '{"rep":55,"prospect":45}', NULL);
