#!/usr/bin/env python3
"""架空の社内文書（Markdown）から PDF を作る（第6章の講師デモ CoWork RAG 用）。
usage: python3 public/data/make_docs_pdf.py
前提: pandoc と Google Chrome（headless で PDF 印刷）。出力: public/data/docs/pdf/*.pdf
"""
import pathlib
import subprocess
import tempfile

DOCS = pathlib.Path(__file__).resolve().parent / "docs"
OUT = DOCS / "pdf"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
CSS = """body{font-family:'Hiragino Sans','Hiragino Kaku Gothic ProN','Noto Sans JP',sans-serif;font-size:11pt;line-height:1.7;margin:24mm 20mm;color:#222}
h1{font-size:18pt;border-bottom:2px solid #29b5e8;padding-bottom:4px}h2{font-size:13pt;margin-top:1.4em}h3{font-size:11.5pt}
table{border-collapse:collapse;width:100%}th,td{border:1px solid #999;padding:4px 8px;text-align:left}th{background:#eef6fb}
blockquote{color:#666;border-left:3px solid #ccc;margin:0;padding-left:10px}"""


def main():
    OUT.mkdir(exist_ok=True)
    for md in sorted(DOCS.glob("*.md")):
        with tempfile.TemporaryDirectory() as tmp:
            html = pathlib.Path(tmp) / "doc.html"
            css = pathlib.Path(tmp) / "doc.css"
            css.write_text(CSS, encoding="utf-8")
            # Markdown → HTML（表を含む）
            subprocess.run(["pandoc", str(md), "-f", "gfm", "-t", "html5", "-s", "--metadata", f"title={md.stem}",
                            "-c", str(css), "-o", str(html)], check=True)
            # 自動で付くタイトルを消して本文の見出しだけにする
            s = html.read_text(encoding="utf-8").replace('<header id="title-block-header">', '<header style="display:none">')
            html.write_text(s, encoding="utf-8")
            pdf = OUT / f"{md.stem}.pdf"
            subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                            f"--print-to-pdf={pdf}", html.as_uri()], check=True, capture_output=True)
            print("ok", pdf.name)


if __name__ == "__main__":
    main()
