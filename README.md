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

## Pre-commit hook（自動更新 sitemap）

[`scripts/install-hooks.sh`](scripts/install-hooks.sh) 安裝後，每次 commit 變更 `*.html` 會由 [`scripts/update_sitemap.py`](scripts/update_sitemap.py) 自動把對應頁面在 [`sitemap.xml`](sitemap.xml) 的 `<lastmod>` 改成今日。

```bash
bash scripts/install-hooks.sh
```

## 申辦資訊

- 申辦專線：**0952-999-575**（電銷服務專員）
- 24 小時客服：0809-006-899
- LINE 官方帳號：[@tmg6174l](https://line.me/R/ti/p/@tmg6174l)

## 授權

© 2026 凱擘大寬頻．數位有線電視（第四臺）．All Rights Reserved.
