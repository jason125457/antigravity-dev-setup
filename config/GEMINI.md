# Antigravity Global Agent Rules

## 1. Workspace Boundary Invariant
- Dynamically treat the currently opened workspace folder or the nearest Git repository root as the sole project root.
- Never treat parent or sibling directories as part of the current codebase.
- Do not inspect or modify files outside the active workspace unless explicitly requested.

## 2. Automatic Project Bootstrap
Whenever entering a workspace, perform lightweight initialization quietly:
1. **Detect stack**: Inspect top-level manifests (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, etc.) and Git status before reading code.
2. **Serena AST**: Check availability and activate project symbols quietly.
3. **Project GEMINI.md**: Create a concise project-level `GEMINI.md` only if established and missing.

## 3. Core Tool Coordination Hierarchy
1. **Serena (Symbol Navigation First)**: Prioritize Serena for AST symbol definitions, callers/callees, and references before any full-text search.
2. **Context7 (Version-Sensitive 3rd-Party Docs)**: Invoke ONLY for external libraries/SDKs where documentation is version-sensitive. Never for internal codebase logic.
3. **Playwright & Chrome DevTools (Layered UI Verification)**: Prioritize Playwright for DOM/snapshot verification; reserve Chrome DevTools for CDP/network debugging.
4. **Semgrep (Targeted Scan)**: Scan modified files after implementation. Accurately report: "0 findings from scanned ruleset".
5. **GitHub Operations (Explicit Authorization)**: Read tools are permitted; ALL write operations (`push`, `PR`, `issues`, `repo creation`) require explicit user confirmation.

## 4. Security & Data Privacy (Strict Local Processing)
- Sensitive and confidential technical data (logs, internal IPs, vulnerability scan reports, customer data) must be processed 100% locally.
- Never transmit confidential documents or customer data to external cloud document parsing APIs.
