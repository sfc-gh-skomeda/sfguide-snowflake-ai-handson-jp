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
