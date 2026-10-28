# Snowflake ハンズオン

このリポジトリは Snowflake ハンズオン（約2時間）の参加者向け資材です。

## 事前準備
1. Snowflake の無料トライアルアカウントを作成してください（Enterprise エディション推奨）。
2. Snowsight にログインし、ワークシートで [`setup.sql`](setup.sql) の内容を実行してください。

## 構成
| パス | 内容 |
|---|---|
| `setup.sql` | 環境構築 |
| `teardown.sql` | 後片付け（作成したオブジェクトを全削除） |
| `chapters/` | 各章の手順 |
| `data/` | 合成データ |
| `notebooks/` `apps/` | Notebook / Streamlit |

> 本資材のデータはすべて架空の合成データです。
