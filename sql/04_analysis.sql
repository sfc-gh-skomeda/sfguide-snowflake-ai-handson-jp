-- 第4章 SQL でアドホック分析（ストーリー: 新商品の販促効果を振り返る）
-- ロール・ウェアハウス・スキーマを選びます
USE ROLE HANDSON_ROLE;
-- 計算に使うウェアハウスを選びます
USE WAREHOUSE HANDSON_WH;
-- 使うスキーマを選びます
USE SCHEMA HANDSON_DB.MART;

-- 課題1: カテゴリ別の売上合計を出し、棒グラフにします
SELECT p.category AS "カテゴリ", SUM(s.sales_amount) AS "売上合計"
FROM SALES_DAILY s JOIN PRODUCTS p ON s.product_id = p.product_id
GROUP BY p.category
ORDER BY "売上合計" DESC;

-- 課題2: 新商品（商品ID 11）の月別販売数を出し、折れ線グラフにします
SELECT DATE_TRUNC('month', s.sale_date) AS "月", SUM(s.quantity) AS "販売数"
FROM SALES_DAILY s
WHERE s.product_id = 11
GROUP BY "月"
ORDER BY "月";

-- 課題3: キャンペーンの前・中・後で、1日あたりの販売数を比べます
SELECT
  CASE WHEN s.sale_date < c.start_date THEN '1_前'
       WHEN s.sale_date <= c.end_date THEN '2_中'
       ELSE '3_後' END AS "期間",
  ROUND(SUM(s.quantity) / COUNT(DISTINCT s.sale_date), 1) AS "1日あたり販売数"
FROM SALES_DAILY s JOIN CAMPAIGNS c ON s.product_id = c.product_id
WHERE c.campaign_id = 1
  AND s.sale_date BETWEEN '2026-04-01' AND '2026-06-30'
GROUP BY "期間"
ORDER BY "期間";

-- 課題4: 新商品の月別販売数に、前月比と累計を付けます
SELECT "月", "販売数",
  "販売数" - LAG("販売数") OVER (ORDER BY "月") AS "前月差",
  SUM("販売数") OVER (ORDER BY "月") AS "累計"
FROM (
  SELECT DATE_TRUNC('month', sale_date) AS "月", SUM(quantity) AS "販売数"
  FROM SALES_DAILY WHERE product_id = 11 GROUP BY 1
)
ORDER BY "月";

-- 課題5-1: アプリ利用ログ（JSON）の中身をそのまま見ます
SELECT log FROM APP_LOGS LIMIT 5;
-- 課題5-2: コロン（:）で項目を取り出し、::で型をそろえます
SELECT log:event.type::STRING AS "イベント", log:user.age_band::STRING AS "年代"
FROM APP_LOGS LIMIT 5;
-- 課題5-3: 配列（screens）を1行ずつに展開し、画面ごとの表示回数を数えます
SELECT f.value::STRING AS "画面", COUNT(*) AS "表示回数"
FROM APP_LOGS a, LATERAL FLATTEN(input => a.log:screens) f
GROUP BY "画面"
ORDER BY "表示回数" DESC;
-- 課題5-4: よく使う形をビューとして保存します
CREATE OR REPLACE VIEW APP_EVENTS AS
SELECT log:event.type::STRING AS event_type,
       log:event.ts::TIMESTAMP_NTZ AS event_ts,
       log:user.id::STRING AS user_id,
       log:user.age_band::STRING AS age_band
FROM APP_LOGS;
-- 【確認クエリ】ビューから年代別のイベント数を数えます
SELECT age_band AS "年代", COUNT(*) AS "件数" FROM APP_EVENTS GROUP BY 1 ORDER BY 1;
