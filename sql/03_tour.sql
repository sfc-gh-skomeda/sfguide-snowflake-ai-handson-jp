-- 第3章 Snowsight ツアー
-- 使うロールを「HANDSON_ROLE」に切り替えます
USE ROLE HANDSON_ROLE;
-- 計算に使うウェアハウス（コンピュータ）を選びます
USE WAREHOUSE HANDSON_WH;
-- これから使うデータベースとスキーマを選びます
USE SCHEMA HANDSON_DB.MART;
-- 商品マスタの中身を10行だけ見てみます
SELECT * FROM PRODUCTS LIMIT 10;
-- 【確認クエリ】日次販売テーブルの件数を数えます（期待結果: 500000）
SELECT COUNT(*) AS "件数" FROM SALES_DAILY;
