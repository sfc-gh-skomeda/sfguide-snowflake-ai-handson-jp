-- ============================================================
-- ハンズオン環境のセットアップ（setup.sql）
-- 前提: Snowflake のトライアルアカウント（AWS 東京・Enterprise）に
--       ACCOUNTADMIN ロールでログインしていること
-- 使い方: Snowsight のワークシートに全文を貼り付け、
--         「すべて実行」で上から順に実行します（約1〜2分）
-- 何度実行しても同じ状態になります（やり直してもかまいません）
-- データはすべて架空の合成データです
-- ============================================================

-- 管理者ロールに切り替えます（環境を作るために必要な権限を持つロールです）
USE ROLE ACCOUNTADMIN;

-- ------------------------------------------------------------
-- 1. ウェアハウス・データベース・ロールを作る
-- ------------------------------------------------------------

-- ハンズオン用のウェアハウス（SQL を実行するための計算資源）を作ります
-- 一番小さい XSMALL、60秒使わなければ自動で停止して課金も止まります
CREATE WAREHOUSE IF NOT EXISTS HANDSON_WH
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

-- これ以降の処理は HANDSON_WH で実行します
USE WAREHOUSE HANDSON_WH;

-- ハンズオン用のデータベースを作ります（作り直すと中身は初期状態に戻ります）
CREATE OR REPLACE DATABASE HANDSON_DB;

-- 販売データを置くスキーマ（データベースの中のフォルダのようなもの）です（第3・4章）
CREATE SCHEMA HANDSON_DB.MART;

-- 性能改善の実習で使うスキーマです（第5章）
CREATE SCHEMA HANDSON_DB.PERF;

-- お客様の声（問い合わせ文）を置くスキーマです（第6章）
CREATE SCHEMA HANDSON_DB.VOC;

-- 実習で使うロール（権限のまとまり）を作ります
CREATE ROLE IF NOT EXISTS HANDSON_ROLE;

-- 今ログインしているユーザーの名前を変数 u に入れます
SET u = CURRENT_USER();

-- 自分自身に HANDSON_ROLE を付けて、実習で使えるようにします
GRANT ROLE HANDSON_ROLE TO USER IDENTIFIER($u);

-- ------------------------------------------------------------
-- 2. 販売データ（MART スキーマ）を作る
-- ------------------------------------------------------------

-- 商品マスタ（30商品）を作ります。商品名・カテゴリ・単価・発売日を持ちます
CREATE TABLE HANDSON_DB.MART.PRODUCTS (
  product_id   INT,      -- 商品の番号
  product_name STRING,   -- 商品名
  category     STRING,   -- カテゴリ
  unit_price   INT,      -- 店頭での単価（円）
  launch_date  DATE      -- 発売日
);

-- 商品マスタにデータを入れます。11番が今回の主役の新商品です
INSERT INTO HANDSON_DB.MART.PRODUCTS VALUES
  (1, 'ミルクチョコレート', 'チョコレート', 120, '2015-04-01'),
  (2, 'ビターチョコレート', 'チョコレート', 130, '2016-04-01'),
  (3, 'アーモンドチョコ', 'チョコレート', 200, '2014-09-01'),
  (4, 'いちごチョコ', 'チョコレート', 150, '2018-01-15'),
  (5, 'ホワイトチョコレート', 'チョコレート', 130, '2017-10-01'),
  (6, 'バタービスケット', 'ビスケット', 180, '2012-04-01'),
  (7, '全粒粉ビスケット', 'ビスケット', 200, '2019-03-01'),
  (8, 'チーズクラッカー', 'ビスケット', 160, '2013-06-01'),
  (9, 'ココアクッキー', 'ビスケット', 220, '2020-02-01'),
  (10, 'さくさくナッツバー プレーン', 'シリアルバー', 140, '2021-09-01'),
  (11, 'さくさくナッツバー 抹茶', 'シリアルバー', 160, '2026-04-01'),
  (12, 'フルーツグラノーラバー', 'シリアルバー', 150, '2022-04-01'),
  (13, 'プロテインバー カカオ', 'シリアルバー', 180, '2023-03-01'),
  (14, 'ミントガム', 'ガム', 110, '2010-04-01'),
  (15, 'グレープガム', 'ガム', 110, '2011-04-01'),
  (16, 'レモンガム', 'ガム', 110, '2016-07-01'),
  (17, 'のど飴 はちみつ', 'キャンディ', 200, '2014-11-01'),
  (18, 'ミルクキャンディ', 'キャンディ', 180, '2012-10-01'),
  (19, 'フルーツキャンディ', 'キャンディ', 180, '2015-05-01'),
  (20, 'ポテトチップス うすしお', 'スナック', 150, '2011-08-01'),
  (21, 'ポテトチップス のり塩', 'スナック', 150, '2011-08-01'),
  (22, 'コーンスナック', 'スナック', 120, '2013-04-01'),
  (23, 'えびせんべい', 'スナック', 170, '2014-04-01'),
  (24, 'プリン', 'デザート', 130, '2018-04-01'),
  (25, 'チョコムース', 'デザート', 160, '2019-09-01'),
  (26, '杏仁豆腐', 'デザート', 150, '2020-04-01'),
  (27, '乳酸菌ドリンク', '飲料', 100, '2017-04-01'),
  (28, 'カフェラテ', '飲料', 140, '2018-09-01'),
  (29, '麦茶', '飲料', 100, '2010-04-01'),
  (30, 'アイスバー バニラ', 'アイス', 120, '2016-05-01');

-- 店舗マスタ（200店舗・全国8エリア・3業態）を作ります
-- HASH は「同じ入力なら必ず同じ値になる」関数です。誰が実行しても同じデータになります
CREATE TABLE HANDSON_DB.MART.STORES AS
SELECT
  SEQ4() + 1 AS store_id,                                              -- 店舗の番号
  '店舗' || LPAD((SEQ4() + 1)::STRING, 3, '0') AS store_name,           -- 店舗名
  GET(ARRAY_CONSTRUCT('北海道','東北','関東','中部','近畿','中国','四国','九州'),
      MOD(ABS(HASH(SEQ4(), 'area')), 8))::STRING AS area,               -- エリア
  GET(ARRAY_CONSTRUCT('スーパー','コンビニ','ドラッグストア'),
      MOD(ABS(HASH(SEQ4(), 'ch')), 3))::STRING AS channel               -- 業態
FROM TABLE(GENERATOR(ROWCOUNT => 200));

-- 販促キャンペーンの表を作り、新商品のキャンペーン（2026年5月）を入れます
CREATE TABLE HANDSON_DB.MART.CAMPAIGNS (
  campaign_id   INT,     -- キャンペーンの番号
  campaign_name STRING,  -- キャンペーン名
  product_id    INT,     -- 対象の商品
  start_date    DATE,    -- 開始日
  end_date      DATE     -- 終了日
);

-- キャンペーンのデータを入れます
INSERT INTO HANDSON_DB.MART.CAMPAIGNS VALUES
  (1, '新商品 抹茶ナッツバー 発売記念キャンペーン', 11, '2026-05-01', '2026-05-31'),
  (2, '冬のチョコレートフェア', 1, '2025-12-01', '2025-12-25');

-- 日別の販売データ（約50万行・2024年11月〜2026年10月）を作ります
-- 新商品は発売日前には売れず、キャンペーン中と関東・近畿でよく売れるようにしています
CREATE TABLE HANDSON_DB.MART.SALES_DAILY AS
WITH base AS (
  SELECT
    SEQ4() AS n,
    DATEADD(day, MOD(ABS(HASH(SEQ4(), 'd')), 730), '2024-11-01'::DATE) AS sale_date,
    MOD(ABS(HASH(SEQ4(), 's')), 200) + 1 AS store_id,
    MOD(ABS(HASH(SEQ4(), 'p')), 30) + 1 AS p0,
    MOD(ABS(HASH(SEQ4(), 'q')), 12) + 1 AS q0
  FROM TABLE(GENERATOR(ROWCOUNT => 500000))
), fixed AS (
  SELECT
    b.n, b.sale_date, b.store_id,
    -- 発売前の新商品の行は、ほかの商品に置き換えます
    IFF(b.p0 = 11 AND b.sale_date < '2026-04-01', MOD(b.n, 10) + 1, b.p0) AS product_id,
    b.q0
  FROM base b
)
SELECT
  f.sale_date,                                                     -- 販売日
  f.store_id,                                                      -- 店舗の番号
  f.product_id,                                                    -- 商品の番号
  ROUND(f.q0
    * IFF(f.product_id = 11 AND f.sale_date BETWEEN '2026-05-01' AND '2026-05-31', 3, 1)
    * IFF(f.product_id = 11 AND s.area IN ('関東','近畿'), 1.5, 1)
    * IFF(f.sale_date >= '2025-11-01', 1.05, 1))::INT AS quantity,  -- 販売個数
  quantity * p.unit_price AS sales_amount                          -- 売上金額（円）
FROM fixed f
JOIN HANDSON_DB.MART.STORES s ON s.store_id = f.store_id
JOIN HANDSON_DB.MART.PRODUCTS p ON p.product_id = f.product_id;

-- アプリの利用ログ（約5万件・JSON）を VARIANT 型の列に入れます
-- VARIANT は JSON をそのまま入れられる型です（第4章の課題5で使います）
CREATE TABLE HANDSON_DB.MART.APP_LOGS AS
SELECT
  OBJECT_CONSTRUCT(
    'event', OBJECT_CONSTRUCT(
      'type', 'session',
      'ts', DATEADD(minute, MOD(ABS(HASH(SEQ4(), 't')), 60 * 24 * 365), '2025-11-01'::TIMESTAMP_NTZ)::STRING),
    'user', OBJECT_CONSTRUCT(
      'id', 'U' || LPAD((MOD(ABS(HASH(SEQ4(), 'u')), 3000) + 1)::STRING, 5, '0'),
      'age_band', GET(ARRAY_CONSTRUCT('10s','20s','30s','40s','50s','60s'), MOD(ABS(HASH(SEQ4(), 'a')), 6))),
    'screens', ARRAY_SLICE(
      ARRAY_CONSTRUCT('ホーム', GET(ARRAY_CONSTRUCT('新商品','キャンペーン','レシピ','店舗検索','新商品'),
                                   MOD(ABS(HASH(SEQ4(), 'x')), 5)),
                     '商品詳細', 'お気に入り'),
      0, MOD(ABS(HASH(SEQ4(), 'k')), 4) + 1)
  )::VARIANT AS log
FROM TABLE(GENERATOR(ROWCOUNT => 50000));

-- ------------------------------------------------------------
-- 3. 性能改善の実習用データ（PERF スキーマ）を作る
-- ------------------------------------------------------------

-- サンプルデータのデータベースを用意します（トライアルには最初からあります）
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_SAMPLE_DATA FROM SHARE SFC_SAMPLES.SAMPLE_DATA;

-- サンプルの注文明細（約6千万行）を、出荷日の順に並べてコピーします（約30秒）
-- 日付順に並べると、日付で絞り込んだときに不要な部分を読み飛ばせます（第5章で確認します）
CREATE TABLE HANDSON_DB.PERF.LINEITEM_SORTED AS
SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.LINEITEM
ORDER BY l_shipdate;

-- 部品と仕入れ先の表（結合の実習用）もコピーします
CREATE TABLE HANDSON_DB.PERF.PARTSUPP AS
SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.PARTSUPP;

-- ------------------------------------------------------------
-- 4. お客様の声（VOC スキーマ）を作る
-- ------------------------------------------------------------

-- GitHub の公開リポジトリを読みに行くための設定（API 統合）を作ります
CREATE OR REPLACE API INTEGRATION HANDSON_GIT_API
  API_PROVIDER = GIT_HTTPS_API
  API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-skomeda')
  ENABLED = TRUE;

-- ハンズオン資材の公開リポジトリを Snowflake から参照できるようにします
CREATE GIT REPOSITORY HANDSON_DB.VOC.HANDSON_REPO
  API_INTEGRATION = HANDSON_GIT_API
  ORIGIN = 'https://github.com/sfc-gh-skomeda/sfguide-snowflake-ai-handson-jp.git';

-- 問い合わせ文のファイルを置くステージ（ファイル置き場）を作ります
-- DIRECTORY を有効にすると、ファイルの一覧を表のように SQL で見られます
CREATE STAGE HANDSON_DB.VOC.INQUIRY_STAGE
  DIRECTORY = (ENABLE = TRUE);

-- リポジトリの問い合わせ文ファイル（約300件）をステージにコピーします
COPY FILES INTO @HANDSON_DB.VOC.INQUIRY_STAGE
  FROM @HANDSON_DB.VOC.HANDSON_REPO/branches/main/data/inquiries/;

-- ステージのファイル一覧を最新の状態にします
ALTER STAGE HANDSON_DB.VOC.INQUIRY_STAGE REFRESH;

-- テキストファイルを「1ファイル＝1行」として読むための形式を作ります
CREATE FILE FORMAT HANDSON_DB.VOC.TXT_FMT
  TYPE = CSV
  FIELD_DELIMITER = NONE
  RECORD_DELIMITER = NONE
  ENCODING = 'UTF8';

-- ファイルの中身を読み込み、問い合わせの表を作ります
-- ファイル名から受付日を、本文の「」から商品名を取り出しています
CREATE TABLE HANDSON_DB.VOC.INQUIRIES AS
SELECT
  REGEXP_SUBSTR(METADATA$FILENAME, 'INQ_[0-9]+_[0-9]+') AS inquiry_id,          -- 問い合わせ番号
  TO_DATE(REGEXP_SUBSTR(METADATA$FILENAME, 'INQ_([0-9]{8})', 1, 1, 'e'), 'YYYYMMDD') AS received_date, -- 受付日
  REGEXP_SUBSTR($1, '「(.+?)」', 1, 1, 'e') AS product_name,                      -- 商品名
  TRIM($1) AS inquiry_text                                                       -- 問い合わせ本文
FROM @HANDSON_DB.VOC.INQUIRY_STAGE (FILE_FORMAT => 'HANDSON_DB.VOC.TXT_FMT');

-- 話題とキーワードの辞書を作ります（第6章で本文と突き合わせて件数を数えます）
CREATE TABLE HANDSON_DB.VOC.KEYWORDS (
  topic   STRING,  -- 話題
  keyword STRING   -- 本文に含まれていたらその話題とみなす言葉
);

-- 辞書にデータを入れます
INSERT INTO HANDSON_DB.VOC.KEYWORDS VALUES
  ('味', '味'), ('味', '甘'), ('味', '苦み'), ('味', '美味'),
  ('価格', '値段'), ('価格', '価格'), ('価格', '安く'),
  ('パッケージ', '個包装'), ('パッケージ', '箱'), ('パッケージ', '袋'), ('パッケージ', 'デザイン'),
  ('量', '量'),
  ('売り場', '店頭'), ('売り場', '売って'), ('売り場', 'コンビニ');

-- ------------------------------------------------------------
-- 5. HANDSON_ROLE に権限を付ける
-- ------------------------------------------------------------

-- ウェアハウスを使う権限と、サイズを変える権限（第5章のおまけ）を付けます
GRANT USAGE, OPERATE, MODIFY ON WAREHOUSE HANDSON_WH TO ROLE HANDSON_ROLE;

-- データベースとスキーマを使う権限を付けます
GRANT USAGE ON DATABASE HANDSON_DB TO ROLE HANDSON_ROLE;

-- データベースの中のすべてのスキーマを使う権限を付けます
GRANT USAGE ON ALL SCHEMAS IN DATABASE HANDSON_DB TO ROLE HANDSON_ROLE;

-- すべての表を読む権限を付けます
GRANT SELECT ON ALL TABLES IN DATABASE HANDSON_DB TO ROLE HANDSON_ROLE;

-- ステージのファイルを読む権限を付けます（第6章）
GRANT READ ON STAGE HANDSON_DB.VOC.INQUIRY_STAGE TO ROLE HANDSON_ROLE;

-- 課題5でビューを作れるよう、MART スキーマにビューを作る権限を付けます
GRANT CREATE VIEW ON SCHEMA HANDSON_DB.MART TO ROLE HANDSON_ROLE;

-- サンプルデータを読む権限を付けます
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_SAMPLE_DATA TO ROLE HANDSON_ROLE;

-- ------------------------------------------------------------
-- 6. できたか確認する
-- ------------------------------------------------------------

-- 各表の件数を確認します。下の数と同じなら準備完了です
-- PRODUCTS 30 / STORES 200 / SALES_DAILY 500000 / APP_LOGS 50000 / INQUIRIES 300
SELECT 'PRODUCTS' AS "表", COUNT(*) AS "件数" FROM HANDSON_DB.MART.PRODUCTS
UNION ALL SELECT 'STORES', COUNT(*) FROM HANDSON_DB.MART.STORES
UNION ALL SELECT 'SALES_DAILY', COUNT(*) FROM HANDSON_DB.MART.SALES_DAILY
UNION ALL SELECT 'APP_LOGS', COUNT(*) FROM HANDSON_DB.MART.APP_LOGS
UNION ALL SELECT 'INQUIRIES', COUNT(*) FROM HANDSON_DB.VOC.INQUIRIES;
