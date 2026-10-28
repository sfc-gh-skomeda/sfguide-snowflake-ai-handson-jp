#!/usr/bin/env python3
"""ハンズオン用の架空の問い合わせ文（お客様相談窓口）を作るスクリプトです。

- 乱数の種を固定しているため、何度実行しても同じファイルができます。
- 人名・住所・電話番号など、個人を特定できる情報は含めません。
- 出力: このファイルと同じフォルダの inquiries/INQ_YYYYMMDD_NNNN.txt（1件1ファイル、UTF-8）

使い方: python3 public/data/generate_inquiries.py
"""
import datetime
import pathlib
import random

OUT = pathlib.Path(__file__).parent / "inquiries"
N = 300
rng = random.Random(20261119)

# setup.sql の PRODUCTS と同じ商品名（一部）。新商品はキャンペーン後に声が増える
NEW = "さくさくナッツバー 抹茶"
OTHERS = ["ミルクチョコレート", "ビターチョコレート", "アーモンドチョコ", "いちごチョコ",
          "バタービスケット", "全粒粉ビスケット", "チーズクラッカー", "ミントガム",
          "グレープガム", "さくさくナッツバー プレーン"]

# 話題ごとの文（setup.sql の KEYWORDS 表のキーワードが含まれるように書く）
TOPICS = {
    "味": ["甘さ控えめでとても美味しかったです。", "以前より味が薄く感じました。",
           "抹茶の苦みがちょうどよく、家族にも好評でした。", "少し甘すぎるように思います。"],
    "価格": ["値段が少し高いと感じます。", "この価格でこの量なら満足です。",
             "セールで安くなっていたので購入しました。"],
    "パッケージ": ["個包装が開けにくく、子どもが困っていました。", "箱のデザインがかわいいです。",
                   "袋がかさばるので小さくしてほしいです。"],
    "量": ["内容量が以前より少なくなった気がします。", "一度に食べきれる量でちょうどよいです。"],
    "購入": ["近くの店頭で見つからず困りました。", "どこで売っているか教えてください。",
             "コンビニで見かけて購入しました。"],
}
OPEN = ["", "いつも楽しみにしています。", "先日初めて購入しました。", "子どものおやつに買っています。"]
CLOSE = ["", "今後もよろしくお願いします。", "ご検討いただけるとうれしいです。", "また購入します。"]


def pick_date(new_product: bool) -> datetime.date:
    # 新商品は 2026-04 発売、5月のキャンペーン以降に声が集中する
    if new_product:
        start, days = datetime.date(2026, 4, 1), 213
        d = rng.choices(range(days), weights=[3 if 30 <= i < 61 else 1 for i in range(days)])[0]
    else:
        start, days = datetime.date(2024, 11, 1), 730
        d = rng.randrange(days)
    return start + datetime.timedelta(days=d)


def main():
    OUT.mkdir(exist_ok=True)
    for old in OUT.glob("INQ_*.txt"):
        old.unlink()
    for i in range(1, N + 1):
        new_product = rng.random() < 0.4
        product = NEW if new_product else rng.choice(OTHERS)
        topics = rng.sample(list(TOPICS), k=rng.choice([1, 1, 2]))
        body = "".join(rng.choice(TOPICS[t]) for t in topics)
        if not new_product:
            body = body.replace("抹茶の", "")
        text = f"{rng.choice(OPEN)}「{product}」について。{body}{rng.choice(CLOSE)}"
        d = pick_date(new_product)
        (OUT / f"INQ_{d:%Y%m%d}_{i:04d}.txt").write_text(text + "\n", encoding="utf-8")
    print("ok", N, "files ->", OUT)


if __name__ == "__main__":
    main()
