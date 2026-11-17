-- 第6章 非構造化データの活用
-- ロールとウェアハウスを選びます
USE ROLE HANDSON_ROLE;
-- 計算に使うウェアハウスを選びます
USE WAREHOUSE HANDSON_WH;
-- 使うスキーマを選びます
USE SCHEMA HANDSON_DB.VOC;

-- U1: ステージに置いたファイルの一覧を見ます
SELECT relative_path AS "ファイル", size AS "サイズ" FROM DIRECTORY(@INQUIRY_STAGE) ORDER BY 1 LIMIT 10;
-- U1【確認クエリ】ファイル数を数えます（期待結果: 300）
SELECT COUNT(*) AS "ファイル数" FROM DIRECTORY(@INQUIRY_STAGE);

-- U2: 「値段」か「価格」を含む問い合わせを探します
SELECT inquiry_id, inquiry_text FROM INQUIRIES WHERE inquiry_text ILIKE '%価格%' OR inquiry_text ILIKE '%値段%' LIMIT 10;
-- U2: 商品ごとの問い合わせ件数を数えます
SELECT product_name AS "商品", COUNT(*) AS "件数" FROM INQUIRIES GROUP BY 1 ORDER BY 2 DESC;

-- U3【確認クエリ】キーワード辞書と突き合わせ、話題ごとの件数を数えます
SELECT k.topic AS "話題", COUNT(DISTINCT i.inquiry_id) AS "件数"
FROM INQUIRIES i JOIN KEYWORDS k ON i.inquiry_text ILIKE '%' || k.keyword || '%'
GROUP BY 1
ORDER BY 2 DESC;

-- ============================================================
-- 講師デモ（トライアルでは実行できません。AI スキーマは講師アカウントで別途作成）
-- ============================================================
-- デモD: AI 関数で問い合わせ文の感情と分類を付ける。例:
-- SELECT inquiry_text, AI_SENTIMENT(inquiry_text):categories[0]:sentiment::STRING AS 感情,
--        AI_CLASSIFY(inquiry_text, ['味', '量', '価格', '売り場', 'パッケージ']):labels[0]::STRING AS 分類
-- FROM HANDSON_DB.VOC.INQUIRIES LIMIT 10;
-- デモE: Snowflake CoWork で、社内文書（架空の PDF・data/docs/pdf）と販売データに質問する（RAG）
--   PDF を AI_PARSE_DOCUMENT で文章にし、Cortex Search で検索できるようにして、Agent から使います。例:
-- CREATE OR REPLACE TABLE HANDSON_DB.AI.DOCS_PARSED AS
-- SELECT relative_path, AI_PARSE_DOCUMENT(TO_FILE('@HANDSON_DB.AI.DOCS_STAGE', relative_path), {'mode': 'LAYOUT'}):content::STRING AS content
-- FROM DIRECTORY(@HANDSON_DB.AI.DOCS_STAGE);
--   本文を約800文字ずつに分けて、検索しやすくします:
-- CREATE OR REPLACE TABLE HANDSON_DB.AI.DOC_CHUNKS AS
-- SELECT d.relative_path, c.value::STRING AS chunk
-- FROM HANDSON_DB.AI.DOCS_PARSED d, LATERAL FLATTEN(SNOWFLAKE.CORTEX.SPLIT_TEXT_RECURSIVE_CHARACTER(d.content, 'markdown', 800, 100)) c;
-- CREATE OR REPLACE CORTEX SEARCH SERVICE HANDSON_DB.AI.DOCS_SEARCH ON chunk WAREHOUSE = HANDSON_WH TARGET_LAG = '1 day'
--   AS SELECT relative_path, chunk FROM HANDSON_DB.AI.DOC_CHUNKS;
--   CoWork での質問の例:「抹茶ナッツバーに卵は入っていますか？」「7月に近畿で新商品の売上が落ちた理由は？」
