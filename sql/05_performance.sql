-- 第5章 遅い SQL を速くする
-- ロールとウェアハウスを選びます
USE ROLE HANDSON_ROLE;
-- 計算に使うウェアハウスを選びます
USE WAREHOUSE HANDSON_WH;
-- 使うスキーマを選びます
USE SCHEMA HANDSON_DB.PERF;
-- 前回の結果を使い回さない（結果キャッシュを無効にする）設定にします
ALTER SESSION SET USE_CACHED_RESULT = FALSE;

-- P1 改善前: 全列を読み込みます（プロファイルでスキャン量を確認）
SELECT * FROM LINEITEM_SORTED WHERE l_shipdate = '1995-03-15' LIMIT 1000;
-- P1 改善後: 必要な列だけを読み込みます
SELECT l_orderkey, l_quantity FROM LINEITEM_SORTED WHERE l_shipdate = '1995-03-15' LIMIT 1000;

-- P2 改善前: 列を関数で加工してから絞り込みます（パーティション数を確認）
SELECT COUNT(*) AS "件数" FROM LINEITEM_SORTED WHERE TO_CHAR(l_shipdate, 'YYYY-MM') = '1995-03';
-- P2 改善後: 列はそのままで、範囲で絞り込みます
SELECT COUNT(*) AS "件数" FROM LINEITEM_SORTED WHERE l_shipdate >= '1995-03-01' AND l_shipdate < '1995-04-01';

-- P3 改善前: 結合キーが足りず、行が増えてしまいます（結合の行数を確認）
SELECT COUNT(*) AS "件数"
FROM LINEITEM_SORTED l JOIN PARTSUPP ps ON l.l_partkey = ps.ps_partkey
WHERE l.l_shipdate >= '1995-03-01' AND l.l_shipdate < '1995-04-01';
-- P3 改善後: 結合キーをすべて指定します
SELECT COUNT(*) AS "件数"
FROM LINEITEM_SORTED l JOIN PARTSUPP ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
WHERE l.l_shipdate >= '1995-03-01' AND l.l_shipdate < '1995-04-01';

-- P4: ウェアハウスのサイズを XS → S → M → L → XL と変えて、同じ重い集計の秒数を比べます
-- サンプルデータの10倍の規模（TPCH_SF100・明細 約6億行）で、1年分の明細と注文を結合して集計する重い SQL です
-- サイズを1段上げるごとに料金（1時間あたり）は2倍になります。サイズを上げると最低1分ぶんの料金がかかります
-- WAIT_FOR_COMPLETION = TRUE は「サイズの切り替えが終わるまで待つ」指定です（待たないと前のサイズで動くことがあります）
-- P4: あとで履歴から探せるよう、目印（クエリタグ）を付けます
ALTER SESSION SET QUERY_TAG = 'HANDSON_P4_XSMALL';
-- P4: X-Small（いまのサイズ・1時間あたり1クレジット）で重い集計を実行し、秒数を表に記録します
SELECT o.o_orderpriority AS "注文の優先度", COUNT(*) AS "明細数",
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS "売上合計"
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM l
JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS o ON o.o_orderkey = l.l_orderkey
WHERE l.l_shipdate >= '1995-01-01' AND l.l_shipdate < '1996-01-01'
GROUP BY 1 ORDER BY 1;
-- P4: サイズを Small（2クレジット） に変えます
ALTER WAREHOUSE HANDSON_WH SET WAREHOUSE_SIZE = 'SMALL' WAIT_FOR_COMPLETION = TRUE;
-- P4: あとで履歴から探せるよう、目印（クエリタグ）を付けます
ALTER SESSION SET QUERY_TAG = 'HANDSON_P4_SMALL';
-- P4: Small（2クレジット）で重い集計を実行し、秒数を表に記録します
SELECT o.o_orderpriority AS "注文の優先度", COUNT(*) AS "明細数",
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS "売上合計"
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM l
JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS o ON o.o_orderkey = l.l_orderkey
WHERE l.l_shipdate >= '1995-01-01' AND l.l_shipdate < '1996-01-01'
GROUP BY 1 ORDER BY 1;
-- P4: サイズを Medium（4クレジット） に変えます
ALTER WAREHOUSE HANDSON_WH SET WAREHOUSE_SIZE = 'MEDIUM' WAIT_FOR_COMPLETION = TRUE;
-- P4: あとで履歴から探せるよう、目印（クエリタグ）を付けます
ALTER SESSION SET QUERY_TAG = 'HANDSON_P4_MEDIUM';
-- P4: Medium（4クレジット）で重い集計を実行し、秒数を表に記録します
SELECT o.o_orderpriority AS "注文の優先度", COUNT(*) AS "明細数",
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS "売上合計"
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM l
JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS o ON o.o_orderkey = l.l_orderkey
WHERE l.l_shipdate >= '1995-01-01' AND l.l_shipdate < '1996-01-01'
GROUP BY 1 ORDER BY 1;
-- P4: サイズを Large（8クレジット） に変えます
ALTER WAREHOUSE HANDSON_WH SET WAREHOUSE_SIZE = 'LARGE' WAIT_FOR_COMPLETION = TRUE;
-- P4: あとで履歴から探せるよう、目印（クエリタグ）を付けます
ALTER SESSION SET QUERY_TAG = 'HANDSON_P4_LARGE';
-- P4: Large（8クレジット）で重い集計を実行し、秒数を表に記録します
SELECT o.o_orderpriority AS "注文の優先度", COUNT(*) AS "明細数",
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS "売上合計"
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM l
JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS o ON o.o_orderkey = l.l_orderkey
WHERE l.l_shipdate >= '1995-01-01' AND l.l_shipdate < '1996-01-01'
GROUP BY 1 ORDER BY 1;
-- P4: サイズを X-Large（16クレジット） に変えます
ALTER WAREHOUSE HANDSON_WH SET WAREHOUSE_SIZE = 'XLARGE' WAIT_FOR_COMPLETION = TRUE;
-- P4: あとで履歴から探せるよう、目印（クエリタグ）を付けます
ALTER SESSION SET QUERY_TAG = 'HANDSON_P4_XLARGE';
-- P4: X-Large（16クレジット）で重い集計を実行し、秒数を表に記録します
SELECT o.o_orderpriority AS "注文の優先度", COUNT(*) AS "明細数",
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS "売上合計"
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM l
JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS o ON o.o_orderkey = l.l_orderkey
WHERE l.l_shipdate >= '1995-01-01' AND l.l_shipdate < '1996-01-01'
GROUP BY 1 ORDER BY 1;
-- P4: 目印を外します
ALTER SESSION UNSET QUERY_TAG;
-- P4: 【必ず実行】サイズを X-Small に戻します（大きいままだと無料枠の減りが速くなります）
ALTER WAREHOUSE HANDSON_WH SET WAREHOUSE_SIZE = 'XSMALL';
-- P4: size の列が X-Small になっていることを確かめます
SHOW WAREHOUSES LIKE 'HANDSON_WH';

-- P5: 結果キャッシュを有効に戻します
ALTER SESSION SET USE_CACHED_RESULT = TRUE;
-- P5: 同じ SQL を2回実行し、2回目が一瞬で終わることを確認します
SELECT COUNT(*) AS "件数" FROM LINEITEM_SORTED WHERE l_shipdate >= '1995-03-01' AND l_shipdate < '1995-04-01';
-- P5: もう一度実行します（2回目）
SELECT COUNT(*) AS "件数" FROM LINEITEM_SORTED WHERE l_shipdate >= '1995-03-01' AND l_shipdate < '1995-04-01';

-- ============================================================
-- 講師デモ（トライアルでは実行できません）
-- ============================================================
-- デモC: CoCo in Snowsight に、この章の結果を HTML レポートにしてもらう
--   CoCo への依頼の例:「直前に HANDSON_WH で実行した第5章の SQL をクエリ履歴から集め、サイズ別の秒数とクレジット、
--   P1〜P3 の改善前後、結果キャッシュの効果、推奨、X-Small を1日8時間・月20日使った場合の月額の目安を HTML レポートにして」
--   CoCo は、たとえば次のような SQL でクエリ履歴を集めます:
-- SELECT query_tag, warehouse_size, total_elapsed_time / 1000 AS "秒"
-- FROM TABLE(HANDSON_DB.INFORMATION_SCHEMA.QUERY_HISTORY())
-- WHERE query_tag LIKE 'HANDSON_P4_%' ORDER BY start_time;
