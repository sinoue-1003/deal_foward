-- DealForward seed data (demo)
-- Run after 001_initial.sql

TRUNCATE calls, deals RESTART IDENTITY CASCADE;

INSERT INTO deals (name, company, stage, amount, probability, owner, contact_name, contact_email, competitors, close_date) VALUES
  ('エンタープライズ契約',      '株式会社テクノフロント',        'negotiation',  4800000, 80, '田中 太郎', '山田 花子', 'hanako@technofront.jp',   '["Salesforce","HubSpot"]',        NOW() + INTERVAL '14 days'),
  ('SaaS導入プロジェクト',      'フューチャーソリューションズ',   'proposal',     2400000, 60, '鈴木 一郎', '佐藤 次郎', 'jiro@futuresol.jp',       '["Pipedrive"]',                   NOW() + INTERVAL '30 days'),
  ('クラウド移行支援',          'グローバルコープ株式会社',       'demo',         1800000, 40, '田中 太郎', '中村 三郎', 'saburo@globalcorp.jp',    '["Zoho"]',                        NOW() + INTERVAL '45 days'),
  ('データ分析基盤構築',        'イノベーション工業',            'qualify',      3600000, 25, '高橋 花子', '渡辺 四郎', 'shiro@innovation.jp',     '["Salesforce","Pipedrive"]',      NOW() + INTERVAL '60 days'),
  ('セキュリティ監査サービス',  'セーフガード株式会社',          'closed_won',    960000,100, '鈴木 一郎', '伊藤 五郎', 'goro@safeguard.jp',       '[]',                              NOW() - INTERVAL '5 days'),
  ('ERPシステム更新',           '大阪製造',                      'closed_lost',  7200000,  0, '田中 太郎', '加藤 六郎', 'rokuro@osaka-mfg.jp',     '["Salesforce"]',                  NOW() - INTERVAL '10 days'),
  ('AI活用コンサルティング',    'デジタルパイオニア',            'prospect',     1200000, 10, '高橋 花子', '吉田 七子', 'nanako@digitalpioneer.jp','[]',                              NOW() + INTERVAL '90 days'),
  ('顧客管理システム刷新',      'リテールジャパン株式会社',      'demo',         2100000, 40, '鈴木 一郎', '小林 八郎', 'hachi@retailjapan.jp',    '["HubSpot"]',                     NOW() + INTERVAL '40 days');

INSERT INTO calls (title, date, duration_seconds, participants, transcript, summary, sentiment, keywords, next_steps, talk_ratio, deal_id) VALUES
  ('初回ディスカバリーコール', NOW() - INTERVAL '25 days', 1800,
   '[{"name":"田中 太郎","role":"rep"},{"name":"山田 花子","role":"prospect"}]',
   '田中: こんにちは、田中です。本日はお時間をいただきありがとうございます。
山田: こちらこそよろしくお願いします。御社のプロダクトに興味があります。
田中: まず、現在どのような課題をお持ちか聞かせていただけますか？
山田: 主に営業の効率化ですね。商談の進捗管理が難しくて。
田中: 弊社のソリューションはまさにそこに特化しています。月間どれくらいの商談を管理していますか？
山田: だいたい50件くらいです。Salesforceも使っているんですが、入力が大変で。
田中: 弊社のツールはSalesforceと連携できますので、入力の手間を大幅に削減できます。
山田: それは魅力的ですね。価格はどのくらいですか？
田中: チームの規模によりますが、10名で月40万円からです。デモを見ていただけますか？
山田: はい、ぜひ見たいです。来週あたりはいかがですか？',
   '顧客の営業効率化という課題を確認し、Salesforce連携の価値提案を実施。デモの日程調整で合意。',
   'positive',
   '["営業効率化","Salesforce連携","デモ日程","価格","月40万円"]',
   '["来週のデモ日程を確定する","見積書を準備して送付"]',
   '{"rep":55,"prospect":45}', 1),

  ('製品デモセッション', NOW() - INTERVAL '18 days', 3200,
   '[{"name":"鈴木 一郎","role":"rep"},{"name":"佐藤 次郎","role":"prospect"}]',
   '鈴木: 鈴木です。先日お送りした提案書についてご質問がありますか？
佐藤: はい。競合他社のSalesforceと比べてどう違うのか教えてください。
鈴木: 大きな違いは2点あります。まず、AIによる商談分析機能が充実しています。
佐藤: 具体的にどんな分析ができるんですか？
鈴木: 営業担当者の発話比率、感情分析、次のアクション提案などです。
佐藤: なるほど。導入コストはどのくらいかかりますか？
鈴木: 初期費用50万円、月額20万円です。ROIは通常6ヶ月で回収できています。
佐藤: 少し高いですね。ディスカウントは可能ですか？
鈴木: 年間契約をいただければ20%割引が可能です。ご検討いただけますか？
佐藤: 上司に相談してから回答します。1週間ほどお待ちください。',
   'Salesforceとの差別化を説明し、AIによる会話分析機能をデモ。価格交渉が発生、年間割引を提案。',
   'neutral',
   '["Salesforce比較","AI分析","価格交渉","年間割引","ROI"]',
   '["上司への説明資料を追加送付","1週間後にフォローアップ電話"]',
   '{"rep":60,"prospect":40}', 2),

  ('フォローアップコール', NOW() - INTERVAL '10 days', 900,
   '[{"name":"田中 太郎","role":"rep"},{"name":"中村 三郎","role":"prospect"}]',
   NULL, NULL, 'neutral', '[]', '[]', '{"rep":50,"prospect":50}', 3),

  ('提案書レビュー', NOW() - INTERVAL '7 days', 2700,
   '[{"name":"高橋 花子","role":"rep"},{"name":"渡辺 四郎","role":"prospect"}]',
   NULL, NULL, 'positive', '["予算","Q3導入","データ基盤"]', '["技術検証の日程調整"]',
   '{"rep":45,"prospect":55}', 4),

  ('成約クロージング', NOW() - INTERVAL '5 days', 1200,
   '[{"name":"鈴木 一郎","role":"rep"},{"name":"伊藤 五郎","role":"prospect"}]',
   NULL, NULL, 'positive', '["契約書","スタート日","オンボーディング"]', '["契約書を締結","キックオフ日程を設定"]',
   '{"rep":40,"prospect":60}', 5),

  ('技術要件確認', NOW() - INTERVAL '3 days', 2100,
   '[{"name":"高橋 花子","role":"rep"},{"name":"吉田 七子","role":"prospect"}]',
   NULL, NULL, 'neutral', '["AI活用","予算未定","2025年度"]', '["概算見積書を送付"]',
   '{"rep":65,"prospect":35}', 7),

  ('価格交渉ミーティング', NOW() - INTERVAL '1 day', 1500,
   '[{"name":"田中 太郎","role":"rep"},{"name":"山田 花子","role":"prospect"}]',
   NULL, NULL, 'positive', '["最終価格","契約条件","SLA"]', '["最終契約書の草案を共有"]',
   '{"rep":50,"prospect":50}', 1),

  ('初回ヒアリング', NOW() - INTERVAL '2 days', 1800,
   '[{"name":"鈴木 一郎","role":"rep"},{"name":"小林 八郎","role":"prospect"}]',
   NULL, NULL, 'neutral', '["顧客管理","移行コスト","現行システム"]', '["現行システムの詳細をヒアリング"]',
   '{"rep":55,"prospect":45}', 8);
