#!/bin/sh
# 安裝 git hooks（.git/hooks 不入版控，需在每台 clone 後執行一次）
# 使用：
#   sh scripts/install-hooks.sh
set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOK="$REPO_ROOT/.git/hooks/pre-commit"

cat > "$HOOK" <<'HOOK_EOF'
#!/bin/sh
# kbro pre-commit hook
#   1. 自動同步 sitemap.xml lastmod 到工作區實際狀態
#   2. 對有變動的 HTML 頁面跑 Lighthouse，於終端機印分數表（預設不擋 commit）
#
# 環境變數：
#   KBRO_SKIP_LH=1     完全跳過 Lighthouse（sitemap 仍會跑）
#   KBRO_LH_STRICT=1   跑 lhci assert，分數不達 lighthouserc.json 閾值時擋 commit
#   KBRO_LH_MAX=N      本次 commit 含 >N 個 HTML 變動時跳過 LH（預設 1）

set -e

# --- 1. sitemap.xml 自動更新 ---
if git diff --cached --name-only --diff-filter=ACMR | grep -qE '\.html$' \
   || git diff --name-only --diff-filter=ACMR | grep -qE '\.html$'; then
  python3 scripts/update_sitemap.py
  git add sitemap.xml
fi

# --- 2. Lighthouse 量測（report-only by default）---
[ "$KBRO_SKIP_LH" = "1" ] && exit 0

CHANGED=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.html$' || true)
[ -z "$CHANGED" ] && exit 0

if [ ! -x node_modules/.bin/lhci ]; then
  printf '\033[33m[lh] @lhci/cli 未安裝，跳過 Lighthouse。請執行 npm install 啟用本機檢查。\033[0m\n'
  exit 0
fi

MAX=${KBRO_LH_MAX:-1}
COUNT=$(printf '%s\n' "$CHANGED" | wc -l | tr -d ' ')
if [ "$COUNT" -gt "$MAX" ]; then
  printf '\033[33m[lh] 本次變動 %s 個 HTML，超過上限 %s，跳過 Lighthouse。改後請手動跑 npm run lh:autorun\033[0m\n' "$COUNT" "$MAX"
  exit 0
fi

URLS=$(printf '%s\n' "$CHANGED" | sed 's|^|http://localhost/|' | paste -sd, -)
printf '\033[36m[lh] 量測 %s 個頁面，請稍候...\033[0m\n' "$COUNT"
rm -rf .lighthouseci
if ! ./node_modules/.bin/lhci collect \
      --staticDistDir=. \
      --numberOfRuns=1 \
      --url="$URLS" >/dev/null 2>&1; then
  printf '\033[33m[lh] lhci collect 失敗，跳過分數報告。\033[0m\n'
  exit 0
fi
node scripts/lh-report.js

if [ "$KBRO_LH_STRICT" = "1" ]; then
  printf '\033[36m[lh] strict mode：跑 lhci assert\033[0m\n'
  ./node_modules/.bin/lhci assert
fi
HOOK_EOF

chmod +x "$HOOK"
echo "✓ pre-commit hook installed at $HOOK"
