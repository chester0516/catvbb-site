#!/usr/bin/env node
/**
 * 本機靜態檔案 server（preview / 開發用，不入 CI 流程）。
 * Express 已是 @lhci/cli 的傳遞依賴，不需另外裝。
 *
 * 用法（透過 .claude/launch.json）：
 *   node scripts/serve.js
 * 或手動：
 *   node scripts/serve.js 8080
 */

const path = require("path");
const express = require("express");

const port = Number(process.argv[2]) || 8080;
const root = path.resolve(__dirname, "..");

const app = express();
app.use(
  express.static(root, {
    extensions: ["html"],
    setHeaders: (res) => {
      res.setHeader("Cache-Control", "no-store");
    },
  })
);

app.listen(port, () => {
  console.log(`kbro static server: http://localhost:${port}`);
});
