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

-- P4（おまけ）: ウェアハウスを一時的に大きくします
ALTER WAREHOUSE HANDSON_WH SET WAREHOUSE_SIZE = 'SMALL';
-- P4: 大きくしたウェアハウスで P3 改善前を再実行し、秒数を比べます
SELECT COUNT(*) AS "件数"
FROM LINEITEM_SORTED l JOIN PARTSUPP ps ON l.l_partkey = ps.ps_partkey
WHERE l.l_shipdate >= '1995-03-01' AND l.l_shipdate < '1995-04-01';
-- P4: ウェアハウスのサイズを元に戻します
ALTER WAREHOUSE HANDSON_WH SET WAREHOUSE_SIZE = 'XSMALL';

-- P5（おまけ）: 結果キャッシュを有効に戻します
ALTER SESSION SET USE_CACHED_RESULT = TRUE;
-- P5: 同じ SQL を2回実行し、2回目が一瞬で終わることを確認します
SELECT COUNT(*) AS "件数" FROM LINEITEM_SORTED WHERE l_shipdate >= '1995-03-01' AND l_shipdate < '1995-04-01';
-- P5: もう一度実行します（2回目）
SELECT COUNT(*) AS "件数" FROM LINEITEM_SORTED WHERE l_shipdate >= '1995-03-01' AND l_shipdate < '1995-04-01';
