# Antigravity AI Agent Environment Architecture

本架構旨在提供標準化、可攜式（Portable）且高度重視資料隱私（100% 本機離線處理）的 Windows AI Agent 協作開發環境。

---

## 1. 系統架構全景

```
[ Antigravity Host (IDE / Agent CLI) ]
 │
 ├── [ Global Configuration: ~/.gemini/config/ ]
 │    ├── GEMINI.md                  <-- 全域協作規範與工具調用準則
 │    └── mcp_config.json            <-- 7 大核心 MCP 服務定義
 │
 ├── [ Core MCP Servers (常駐 stdio / SSE) ]
 │    ├── 1. serena (uvx)            <-- AST 語法級 Symbol 定位與呼叫鏈
 │    ├── 2. context7 (HTTP)         <-- 版本敏感之第三方 API / Framework 即時文件
 │    ├── 3. playwright (npx)        <-- 前端 Web / UI 行為、DOM Snapshot 與畫面截圖
 │    ├── 4. github (HTTP)           <-- 遠端代碼庫檢索（寫入需明確授權）
 │    ├── 5. chrome-devtools (npx)   <-- 深度網路封包、CDP 協議與 Console 除錯
 │    ├── 6. semgrep (CLI / uv tool) <-- 修改後程式碼靜態安全與規則庫掃描
 │    └── 7. docling (uvx)           <-- 本機高精度多格式文件結構化解析 (PDF/DOCX/XLSX/PPTX)
 │
 ├── [ Plugins & Skills ]
 │    └── obra/superpowers           <-- 官方工作流插件 (TDD、代碼審查、規劃與除錯)
 │
 └── [ Optional Document Intelligence CLIs (隨選按需) ]
      ├── MarkItDown (uv tool)       <-- 輕量極速 Office / 文本轉 Markdown (備援)
      └── MinerU Local (uv tool)     <-- 本地深度視覺模型與跨頁表格/印鑑/圖表裁切 (進階)
```

---

## 2. 目錄路徑規範

- **使用者設定目錄**: `$env:USERPROFILE\.gemini\config`
  - `mcp_config.json`: 本機真實運作之 MCP 配置（含使用者本地 GitHub PAT）。
  - `GEMINI.md`: 全域規範。
  - `plugins/superpowers`: Git clone 自官方儲存庫。
  - `backups/`: 自動備份歷史設定（依執行時間戳記隔離）。
- **專案總目錄**: `G:\Google Antigravity\`
  - 每個子資料夾視為獨立專案，嚴禁將根目錄作為單一 codebase。

---

## 3. 安全與隱私保護邊界 (Privacy Boundary)

1. **零憑證入庫 (No Secrets in Git)**:
   - 範本 `mcp_config.template.json` 僅保留 `YOUR_GITHUB_PAT` 佔位符。
   - `install.ps1` 提示使用者輸入 PAT 並直接寫入本機 `mcp_config.json`。
   - `.gitignore` 嚴格過濾 `mcp_config.json`、`*.backup*`、`*.env*` 與 `secrets/`。
2. **敏感資料本機處理 (100% Offline Document Parsing)**:
   - 內部機密文件、系統 IP、防火牆記錄、弱掃日誌嚴禁上傳任何 Cloud API。
   - Docling 強制啟用 `DOCLING_MCP_CONVERSION_MODE=local`。
   - MarkItDown 嚴禁附加 `--use-docintel` 或 `--use-cu` 外部端點。
   - MinerU 僅使用本機 `-b pipeline` 模式，禁止使用 Cloud / Flash 模式。
