# 凱擘大寬頻 · 電銷服務網站

> 凱擘大寬頻（kbro）光纖上網、數位有線電視（第四台）與雙享方案的形象與申辦導購網站，部署於 [kbro.net](https://kbro.net)。

## 內容

- **首頁** [`index.html`](index.html)：服務總覽、品牌訊息、雙享方案推薦
- **方案費用** [`plans.html`](plans.html)：300M / 500M / 1G 光纖、有線電視、雙享方案費用比較
- **3G/1G 雙向極速專案** [`promo-3g.html`](promo-3g.html)：台北市率先登場的對稱寬頻方案
- **關於我們** [`about.html`](about.html)
- **聯絡我們** [`contact.html`](contact.html)
- **合作社區頁面** [`partner/`](partner/)：12 個社區/區域客製化 landing page（新北、桃園、新竹等）

## 技術棧

純靜態網站，無 build / 框架：

- HTML5 + Bootstrap 5（[`css/lib/`](css/lib/)）
- 客製樣式 [`css/style.css`](css/style.css) + 各頁內嵌 `<style>`
- Bootstrap Icons
- GA4（`G-FBWQJNXDNS`，lazy-load：首次互動或 3 秒後載入）
- 圖片採 WebP 格式 + `loading="lazy"`、LCP 圖加 `fetchpriority="high"`

## SEO / 結構化資料

- 每頁 `<title>`、`<meta description>`、canonical、Open Graph / Twitter Card
- JSON-LD：`Organization`、`WebSite`、`Service` + `OfferCatalog`、`BreadcrumbList`、`FAQPage`
- [`sitemap.xml`](sitemap.xml)：列出全站 URL
- [`robots.txt`](robots.txt)：含 `Sitemap:` 指令、額外允許 GPTBot / ClaudeBot 等 AI 爬蟲
- [`llms.txt`](llms.txt)：給 LLM 的網站摘要

## 部署

GitHub Pages（自訂網域 `kbro.net`，見 [`CNAME`](CNAME)）。推到 `main` 後自動部署。

```bash
# 一般開發
git add <files>
git commit -m "..."
git push origin main
```

## 本機開發環境

需 Node.js **20+**（CI 使用 Node 20）。第一次 clone 後執行：

```bash
npm install                  # 安裝 lint / Lighthouse 工具鏈
bash scripts/install-hooks.sh  # 啟用 pre-commit hook
```

> **Mac Silicon 注意**：Lighthouse 需要 **arm64 版本的 Node**，否則本機跑 LH 會因 Rosetta 翻譯 Chrome 而失敗。用 `nvm` 安裝時請確認 `file $(which node)` 顯示 `arm64`。lint 與 sitemap 在 x64 Node 下不受影響，CI（Ubuntu）也無此問題。

### 可用指令

| 指令 | 說明 |
|---|---|
| `npm run lint` | 同時跑 html-validate + stylelint |
| `npm run lint:html` | 只跑 html-validate |
| `npm run lint:css` | 只跑 stylelint（含 HTML 內 `<style>`） |
| `npm run lh:autorun` | 對全部 17 頁跑 Lighthouse + assert + 上傳臨時公開連結 |

### Pre-commit hook 行為

[`scripts/install-hooks.sh`](scripts/install-hooks.sh) 安裝後，每次 commit 會：

1. **sitemap.xml 自動同步**：若 staged 中有 `*.html`，[`scripts/update_sitemap.py`](scripts/update_sitemap.py) 會把對應頁面的 `<lastmod>` 改成今日並一併加入 commit。
2. **Lighthouse 量測**：對 staged 中變動的 HTML 頁面跑 Lighthouse（desktop 預設），於終端機印出分數表。**預設只報告不擋 commit**。

#### 環境變數

| 變數 | 預設 | 說明 |
|---|---|---|
| `KBRO_SKIP_LH=1` | unset | 跳過 Lighthouse（sitemap 仍會跑） |
| `KBRO_LH_STRICT=1` | unset | 跑 `lhci assert`，分數不達閾值會擋 commit |
| `KBRO_LH_MAX=N` | `1` | 本次 commit 含 >N 個 HTML 變動時跳過 LH，建議事後手動 `npm run lh:autorun` |

範例：

```bash
KBRO_SKIP_LH=1 git commit -m "..."           # 暫時跳過 LH
KBRO_LH_STRICT=1 git commit -m "..."         # 嚴格模式，分數不達標就擋
KBRO_LH_MAX=20 git commit -m "..."           # 批次改多頁時放寬上限
```

## CI（GitHub Actions）

定義於 [`.github/workflows/ci.yml`](.github/workflows/ci.yml)，觸發：PR + push to `main`。

- **`lint` job**：跑 html-validate + stylelint，**違規即 fail**。
- **`lighthouse` job**：對 17 頁完整跑 Lighthouse（lint 通過後才執行），結果：
  - log 中印出 **公開臨時連結**（保留約 7 天，`temporary-public-storage`）
  - **Actions artifact** `lighthouse-report`（保留 90 天，含完整 `.lighthouseci/`）
- 閾值（見 [`lighthouserc.json`](lighthouserc.json)）：
  - Accessibility ≥ 90、SEO ≥ 95 → **error**（會擋）
  - Performance ≥ 80、Best Practices ≥ 85 → **warn**（不擋，因 LH 分數本身有 ±5pt 抖動）

## 已知限制

- 內聯 `<script>` 區塊（gtag / JSON-LD）不在 ESLint 範圍內，僅由 html-validate 抓 `<script>` tag 語法問題與 Lighthouse 在執行期抓錯。
- `temporary-public-storage` 連結對任何拿到網址的人都可見，但不會被搜尋引擎索引。

## 申辦資訊

- 申辦專線：**0952-999-575**（電銷服務專員）
- 24 小時客服：0809-006-899
- LINE 官方帳號：[@tmg6174l](https://line.me/R/ti/p/@tmg6174l)

## 授權

© 2026 凱擘大寬頻．數位有線電視（第四臺）．All Rights Reserved.
