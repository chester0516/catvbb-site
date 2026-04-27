#!/usr/bin/env python3
"""根據 git log + 工作區狀態更新 sitemap.xml 的 lastmod。

規則：
- 若該 HTML 檔在工作區或 staging area 有未 commit 變更 → lastmod 設為今天
- 否則 → lastmod 取該檔最後一次 commit 的 author date (YYYY-MM-DD)

可獨立執行：python3 scripts/update_sitemap.py
也可由 .git/hooks/pre-commit 自動呼叫
"""
import re
import subprocess
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SITEMAP = ROOT / "sitemap.xml"
TODAY = date.today().isoformat()


def url_to_path(loc: str) -> Path:
    """https://example.com/foo/bar.html → ROOT/foo/bar.html。結尾 / 視為 index.html。"""
    rel = loc.split("://", 1)[-1]
    rel = rel.split("/", 1)[1] if "/" in rel else ""
    if rel == "" or rel.endswith("/"):
        rel = rel + "index.html"
    return ROOT / rel


def last_change_date(fp: Path) -> str:
    if not fp.exists():
        return TODAY
    rel = fp.relative_to(ROOT).as_posix()
    dirty = subprocess.run(
        ["git", "status", "--porcelain", "--", rel],
        cwd=ROOT, capture_output=True, text=True,
    ).stdout.strip()
    if dirty:
        return TODAY
    last = subprocess.run(
        ["git", "log", "-1", "--format=%cs", "--", rel],
        cwd=ROOT, capture_output=True, text=True,
    ).stdout.strip()
    return last or TODAY


def main():
    content = SITEMAP.read_text(encoding="utf-8")
    pattern = re.compile(
        r"(<url>\s*<loc>([^<]+)</loc>\s*<lastmod>)([^<]+)(</lastmod>)",
        re.DOTALL,
    )
    changes = []

    def replace(m):
        loc, old = m.group(2), m.group(3)
        fp = url_to_path(loc)
        new = last_change_date(fp)
        if new != old:
            changes.append((loc, old, new))
        return m.group(1) + new + m.group(4)

    new_content = pattern.sub(replace, content)
    if new_content != content:
        SITEMAP.write_text(new_content, encoding="utf-8")

    if changes:
        for loc, old, new in changes:
            print(f"  {loc}: {old} → {new}")
        print(f"sitemap.xml updated ({len(changes)} entries)")
    else:
        print("sitemap.xml: no lastmod changes")


if __name__ == "__main__":
    main()
