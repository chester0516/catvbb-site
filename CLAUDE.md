# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

凱擘大寬頻（kbro.net）電銷導購網站。純靜態 HTML，無 build step、無框架、無 templating，部署於 GitHub Pages（推 `main` 即上線）。網站文案與註解一律使用繁體中文。

## 常用指令

```bash
npm install                    # 安裝 lint / Lighthouse 工具鏈（Node 20+）
bash scripts/install-hooks.sh  # 每次 clone 後執行一次，裝 pre-commit hook

npm run lint                   # html-validate + stylelint（CI 會擋）
npm run lint:html              # 只跑 html-validate（*.html + partner/*.html）
npm run lint:css               # stylelint，含 HTML 內嵌 <style>（postcss-html）
npm run lh:autorun             # 全站 Lighthouse + assert + 上傳臨時公開連結

node scripts/serve.js 8080     # 本機預覽 http://localhost:8080
python3 scripts/update_sitemap.py   # 手動同步 sitemap.xml 的 lastmod
```

單頁 Lighthouse：`npx lhci collect --staticDistDir=. --numberOfRuns=1 --url=http://localhost/plans.html`，再 `node scripts/lh-report.js` 印分數表。

pre-commit hook 環境變數：`KBRO_SKIP_LH=1` 跳過 LH、`KBRO_LH_STRICT=1` 分數不達標就擋、`KBRO_LH_MAX=N` 放寬單次 commit 的 HTML 變動數上限（預設 1，超過就跳過 LH）。批次改多頁時用 `KBRO_LH_MAX=20 git commit ...`，事後補跑 `npm run lh:autorun`。

Mac Silicon：Lighthouse 需要 arm64 版 Node（`file $(which node)` 要看到 `arm64`），否則本機 LH 會失敗；lint 不受影響。

## 架構重點

### CSS 是「內嵌優先」，`css/style.css` 沒有被任何頁面載入

**這是本 repo 最容易踩的坑。** 每個 HTML 頁面在 `<head>` 內嵌一份約 1600 行的完整樣式（`<style>` 區塊），`css/style.css` 只是這份樣式的參考副本 / single source of truth，`grep -rl "style.css" *.html partner/*.html` 是零筆。

改樣式時：改 `css/style.css` **不會有任何效果**，必須同步改動每個受影響頁面的內嵌 `<style>`。若是全站樣式，18 個 HTML 檔都要改（含 `css/style.css` 以維持參考版一致）。

設計 token 定義在 `:root`（Stormy Teal `--brand-primary: #16697A` / Amber Glow `--brand-accent: #FFA62B` / Alabaster `--brand-bg-soft`）。多個 token 的註解標明它是為了通過 WCAG AA 4.5:1 才選的色（例如 `--brand-accent-text`、`--brand-muted`）——改色前先確認對比度，CI 的 accessibility 門檻會擋。

### 沒有 partial／include，共用區塊靠複製

navbar、footer、floating CTA、GA4 lazy-load script、JSON-LD 都是逐頁複製的。因此以下改動都是「全站掃過一遍」的工作：

- 新增／改名導覽列項目 → 18 個 HTML 都要改
- 換申辦專線（目前 `0952-999-575` / `tel:0952999575`）→ 全站近 200 處
- 改 footer、改 GA4 ID（`G-FBWQJNXDNS`）

`partner/` 底下的頁面路徑要用 `../`（`../index.html`、`../images/x.webp`），根目錄頁面則是相對路徑。批次改動時很容易漏掉這個差異。

### 頁面清單分散在四個地方，新增頁面時要一起更新

新增一個 `.html` 頁面後，需同步：

1. `sitemap.xml` — 加 `<url>` 區塊（`lastmod` 由 `scripts/update_sitemap.py` 依 git log 自動維護，不要手填）
2. `lighthouserc.json` 的 `ci.collect.url` — 沒加就不會進 CI 的 Lighthouse 檢查
3. 全站 navbar（若要出現在導覽列）
4. `llms.txt` — 給 LLM 爬蟲的網站摘要

`promo-1g.html` 曾經漏掉第 2 項（已於 2026-07-21 補上，CI 現在跑 18 頁），新增頁面時別重蹈覆轍。

### SEO 是這個站的主要產出，不是附加品

每頁都有完整的 title / meta description / keywords / canonical / OG / Twitter Card，以及大量 JSON-LD（`Organization`、`WebSite`、`Service` + `OfferCatalog`、`BreadcrumbList`、`FAQPage`、partner 頁的 `LocalBusiness` + `AdministrativeArea` 服務區域清單）。改動頁面內容（尤其方案價格、服務地區、FAQ）時，**同一頁的 JSON-LD 通常也要跟著改**，否則結構化資料會和畫面對不上。

CI 門檻（`lighthouserc.json`）：Accessibility ≥ 90、SEO ≥ 95 為 **error（會擋）**；Performance ≥ 80、Best Practices ≥ 85 為 warn。

### 效能約定

- 圖片一律提供 `.webp`（`.jpg` 為 fallback／OG 用），非首屏加 `loading="lazy"`
- LCP 圖（hero / page-header 背景）用 `<img class="page-header-bg">` + `fetchpriority="high"` + `<link rel="preload" as="image">`，並帶上 `width`/`height` 避免 CLS
- GA4 延後到「首次互動或 3 秒後」才載入，勿改成同步載入
- Bootstrap 5 與 Bootstrap Icons 都是 vendored 在 `css/lib/`，不走 CDN

## Lint 設定的既有豁免

`.htmlvalidate.json` 關掉了 `no-inline-style`、`prefer-native-element`、`aria-label-misuse` 等規則；`.stylelintrc.json` 關掉了 `no-descending-specificity`、`selector-class-pattern` 等。這些是為了配合現有寫法刻意關的，不要為了「修 lint」去大改既有 markup 風格。內聯 `<script>`（gtag / JSON-LD）不在任何 linter 的檢查範圍內。
