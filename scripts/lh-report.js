#!/usr/bin/env node
/**
 * 讀 .lighthouseci/ 目錄下所有 lhr-*.json，輸出單一表格。
 * 供 pre-commit hook 使用，commit 前快速顯示分數，不擋 commit。
 *
 * Usage: node scripts/lh-report.js
 */

const fs = require("fs");
const path = require("path");

const LHCI_DIR = path.resolve(process.cwd(), ".lighthouseci");

if (!fs.existsSync(LHCI_DIR)) {
  console.error("[lh-report] .lighthouseci/ 不存在，請先跑 lhci collect。");
  process.exit(0);
}

const files = fs
  .readdirSync(LHCI_DIR)
  .filter((f) => f.startsWith("lhr-") && f.endsWith(".json"));

if (files.length === 0) {
  console.error("[lh-report] 找不到 lhr-*.json 報告檔。");
  process.exit(0);
}

const rows = [];
for (const f of files) {
  try {
    const report = JSON.parse(
      fs.readFileSync(path.join(LHCI_DIR, f), "utf8")
    );
    const url = report.finalDisplayedUrl || report.requestedUrl || f;
    // localhost path → 顯示為 "index.html" / "partner/foo.html"
    const display = url.replace(/^https?:\/\/[^/]+\//, "");
    const c = report.categories || {};
    const score = (k) =>
      c[k] && typeof c[k].score === "number"
        ? Math.round(c[k].score * 100)
        : "—";
    rows.push({
      page: display,
      perf: score("performance"),
      a11y: score("accessibility"),
      bp: score("best-practices"),
      seo: score("seo"),
    });
  } catch (e) {
    console.error(`[lh-report] 解析 ${f} 失敗：${e.message}`);
  }
}

if (rows.length === 0) {
  process.exit(0);
}

rows.sort((a, b) => a.page.localeCompare(b.page));

const pageW = Math.max(4, ...rows.map((r) => r.page.length));
const pad = (s, w) => String(s).padEnd(w, " ");
const padR = (s, w) => String(s).padStart(w, " ");

const COL = { perf: 5, a11y: 5, bp: 4, seo: 4 };
const color = (n) => {
  if (n === "—") return n;
  if (n >= 90) return `\x1b[32m${n}\x1b[0m`; // 綠
  if (n >= 80) return `\x1b[33m${n}\x1b[0m`; // 黃
  return `\x1b[31m${n}\x1b[0m`; // 紅
};

console.log("");
console.log(
  `${pad("頁面", pageW)}  ${padR("Perf", COL.perf)}  ${padR("A11y", COL.a11y)}  ${padR("BP", COL.bp)}  ${padR("SEO", COL.seo)}`
);
console.log(
  `${"-".repeat(pageW)}  ${"-".repeat(COL.perf)}  ${"-".repeat(COL.a11y)}  ${"-".repeat(COL.bp)}  ${"-".repeat(COL.seo)}`
);
for (const r of rows) {
  console.log(
    `${pad(r.page, pageW)}  ${padR(color(r.perf), COL.perf + 9)}  ${padR(color(r.a11y), COL.a11y + 9)}  ${padR(color(r.bp), COL.bp + 9)}  ${padR(color(r.seo), COL.seo + 9)}`
  );
}
console.log("");
