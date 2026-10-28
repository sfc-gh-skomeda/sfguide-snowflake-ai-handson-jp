-- ============================================================
-- ハンズオン環境の後片付け（teardown.sql）
-- setup.sql で作ったものをすべて削除します（元には戻せません）
-- トライアル期間中に復習したい方は、実行しなくてもかまいません
-- ============================================================

-- 管理者ロールに切り替えます（削除に必要な権限を持つロールです）
USE ROLE ACCOUNTADMIN;

-- ハンズオン用のデータベースを中身ごと削除します
DROP DATABASE IF EXISTS HANDSON_DB;

-- GitHub を読むための設定（API 統合）を削除します
DROP API INTEGRATION IF EXISTS HANDSON_GIT_API;

-- ハンズオン用のウェアハウスを削除します
DROP WAREHOUSE IF EXISTS HANDSON_WH;

-- ハンズオン用のロールを削除します
DROP ROLE IF EXISTS HANDSON_ROLE;
