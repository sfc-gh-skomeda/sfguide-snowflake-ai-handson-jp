# 第0章 環境セットアップ（当日までに・目安 15 分）
## この章でやること
ハンズオン用のデータと環境を、ご自身のトライアルアカウントに作成します。
## 前提
- Snowflake のトライアルアカウント（Enterprise / AWS / Asia Pacific (Tokyo)）を作成済みであること
- ACCOUNTADMIN ロールでログインできること
## 手順
### Step 1 SQL ファイル（ワークシート）を開く
Snowsight にログインし、左メニューの「Projects」→「Workspaces」を開き、「SQL file」ボタンで新しい SQL ファイルを作ります。
### Step 2 setup.sql を実行する
このリポジトリの [setup.sql](../setup.sql) の中身をすべてコピーして SQL ファイルに貼り付け、「すべて実行」（Ctrl/Cmd + Shift + Enter）します。約2分で終わります。
## 確認ポイント（期待結果）
最後に次の表が表示されれば完了です。

| 表 | 件数 |
|---|---|
| PRODUCTS | 30 |
| STORES | 200 |
| SALES_DAILY | 500000 |
| APP_LOGS | 50000 |
| INQUIRIES | 300 |

## うまくいかない時
- 権限エラー: 右上のロールが ACCOUNTADMIN か確認してください。
- 途中で止まった: setup.sql は何度実行しても大丈夫です。もう一度すべて実行してください。
- リージョンの確認: `SELECT CURRENT_REGION();` の結果が **AWS_AP_NORTHEAST_1**（東京）でない場合は、トライアル作成時のリージョン選択が違っています。講師にお知らせください。
