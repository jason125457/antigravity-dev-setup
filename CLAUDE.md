# antigravity-dev-setup：Claude Code 工作規則

Google Antigravity 開發環境的 Windows 一鍵還原包（PowerShell）：`install.ps1` 安裝、`verify.ps1` 健檢，另有 hooks、skills、設定範本。
設計見 `docs/ARCHITECTURE.md`、`docs/HARNESS-GUIDELINES.md`、`docs/TOOL-WORKFLOW.md`。

## 不能違反

- 版本一律釘死：本機 MCP、外掛、CLI 都鎖定驗證過的版本號或 commit，不用 `@latest` 或浮動分支。
- README 以實際運作中的環境為準：升級任何元件，要在使用者電腦實測通過後，同時更新安裝腳本、README 的版本表、`verify.ps1` 與 `CHANGELOG.md`。沒有實測過的版本不寫進去。
- 只在 CurrentUser 範圍安裝，不要求系統管理員權限，不動系統 Proxy、防毒與 ExecutionPolicy。
- 寫入使用者設定前先備份（`scripts/backup-existing-config.ps1`），JSON 用合併的，不整檔覆蓋。
- 這個 repo 是公開的：只提交 `*.template.json`；真正的 `mcp_config.json`、PAT、`.env`、客戶文件都不提交。
- 敏感文件解析只走本機（Docling、MinerU），範本與文件裡不加第三方雲端文件解析 API。

## 驗收

- 腳本是 PowerShell 5.1 相容的 Windows 腳本，雲端 Linux session 跑不了：只能做靜態檢查，並明講「未在 Windows 實測」。
- 在使用者電腦上：`.\verify.ps1` 全數通過才算完成。

## 慣例

- `CHANGELOG.md` 採 Keep a Changelog 格式與語意化版本。
- commit：英文 Conventional Commits。
- 這裡的 `config/GEMINI.md`、`templates/` 是給 Antigravity 用的範本，改它們不會影響 Claude Code 的行為。
