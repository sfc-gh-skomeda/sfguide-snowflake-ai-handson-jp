# 第3章 Snowsight ツアー（目安 10 分）
## この章でやること
画面の見方、データの探し方、ワークシートでの SQL 実行を体験します。
## 前提
第0章が終わっていること。
## 手順
### Step 1 画面を見る
左メニューの各項目（Projects / Catalog / Monitoring / Compute / Admin）を講師と一緒に確認します。
### Step 2 データを探す
「Catalog」を開き、左の「Catalog explorer」（表示されていなければ左上のボタンで開きます）で HANDSON_DB → MART → Tables → PRODUCTS を選び、「Preview」タブで中身を見ます（SQL ファイルの画面の左側「Databases」タブからもたどれます）。
### Step 3 SQL を実行する
新しい SQL ファイル（Projects → Workspaces →「SQL file」）に [sql/03_tour.sql](../sql/03_tour.sql) を貼り付け、上から1文ずつ実行します（カーソルを文に置いて Ctrl/Cmd + Enter）。
## 確認ポイント（期待結果）
```sql
-- 日次販売テーブルの件数を数えます
SELECT COUNT(*) AS "件数" FROM HANDSON_DB.MART.SALES_DAILY;
```
結果が **500000** なら OK です。
## うまくいかない時
- 「ウェアハウスがない」エラー: SQL ファイル右上で HANDSON_WH を選ぶか、`USE WAREHOUSE HANDSON_WH;` を実行します。
- 「オブジェクトがない」エラー: ロールが HANDSON_ROLE か確認します。
