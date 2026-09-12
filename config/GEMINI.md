# Antigravity Development Rules

Development projects are primarily located under:
G:\Google Antigravity\

Each child directory under this folder must be treated as an independent project.
Never treat the entire `G:\Google Antigravity\` directory as a single codebase.
Do not modify files outside the currently active project unless explicitly requested.

---

# Automatic Project Bootstrap
Whenever a coding project is opened, perform lightweight project initialization quietly:
1. **Detect project root**: Treat the opened workspace as project root.
2. **Serena**: Check availability and activate project if not already activated.
3. **Inspect metadata**: Check README, package.json, pyproject.toml, git status before reading code.
4. **Project GEMINI.md**: Create concise project-level GEMINI.md only if missing and established.

---

# Core Tool Coordination Principles

## 1. Serena (Symbol Navigation First)
- Prioritize Serena for symbol lookup, references, callers/callees, code navigation, and dependency tracing.
- Do not fall back to large-scale full-text search when Serena can accomplish the task directly.

## 2. Context7 (Version-Sensitive 3rd-Party Docs)
- Use Context7 ONLY when working with third-party libraries, SDKs, APIs, or frameworks where documentation may be version-sensitive, or unfamiliar package behavior.
- Do not invoke Context7 when internal project code or standard stable language features are sufficient.

## 3. Playwright & Chrome DevTools (Layered Web/UI Verification)
- Prioritize Playwright for web/UI verification (navigation, DOM snapshot, console logs, screenshots).
- Use Chrome DevTools only when Playwright cannot explain an error, or when CDP, Network payloads, Performance traces, or memory debugging are specifically required.

## 4. Semgrep (Targeted Scan & Strict Terminology)
- Run Semgrep after actual code modifications, prioritizing changed files.
- Never describe "0 findings" as "0 vulnerabilities" or "0 defects"; state accurately: "0 findings from scanned ruleset".

## 5. GitHub MCP (Explicit Authorization for Write Operations)
- Read operations (get_me, list_commits, status) may be used for inspection.
- Write operations (push, PR, issue creation, reviews) require explicit user request or task mandate.

---

# Document Intelligence & Parsing Rules

## 1. Tool Selection Hierarchy
- **Docling (Default)**: Primary parser for PDF, DOCX, PPTX, XLSX, table recognition, and structured Markdown/JSON.
- **MarkItDown (CLI Fast Fallback)**: Use for quick CLI text extraction and rapid Office-to-Markdown conversion.
- **MinerU Local (Secondary Deep Parser)**: Use only when Docling produces insufficient quality on complex scanned PDFs, intricate formulas, or requires visual image/chart element cropping.

## 2. Security & Data Privacy (Strict Local Processing)
- Sensitive data (confidential technical reports, firewall/WAF logs, internal IPs, vulnerability scan reports, customer data) must be processed 100% locally.
- Never use MinerU Flash, MinerU Cloud, Azure Document Intelligence, or third-party Cloud Document APIs.
- If any tool might send document content to external servers, STOP and clearly notify the user.

## 3. Cross-Validation
- Document extraction outputs are not infallible; critical numerical metrics in charts/tables must be cross-verified against original pages.
