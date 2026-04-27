#!/bin/sh
# 安裝 git hooks（.git/hooks 不入版控，需在每台 clone 後執行一次）
# 使用：
#   sh scripts/install-hooks.sh
set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOK="$REPO_ROOT/.git/hooks/pre-commit"

cat > "$HOOK" <<'HOOK_EOF'
#!/bin/sh
# 自動同步 sitemap.xml lastmod 到工作區實際狀態
# 若有 HTML 變更，sitemap.xml 會被一併更新並加入本次 commit

set -e

if git diff --cached --name-only --diff-filter=ACMR | grep -qE '\.html$' \
   || git diff --name-only --diff-filter=ACMR | grep -qE '\.html$'; then
  python3 scripts/update_sitemap.py
  git add sitemap.xml
fi
HOOK_EOF

chmod +x "$HOOK"
echo "✓ pre-commit hook installed at $HOOK"
