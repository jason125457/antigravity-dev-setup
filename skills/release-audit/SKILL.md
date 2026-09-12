---
name: release-audit
description: Pre-release hygiene, secret leak scanning, and integrity audit. Use before tagging a release, creating a pull request, or publishing code to audit working tree cleanliness, scan for leaked credentials, run Semgrep on changed files, and verify UTF-8 without BOM encoding.
---

# Release Audit Checklist & Workflow

Supplementary security and integrity checklist to be run prior to tagging, releasing, or pushing code. (Complements Superpowers verification workflows without duplicating review/finishing branches).

## Audit Procedures

### 1. Secret & Credential Leak Scan
- Check staged and untracked files:
  `git status --porcelain`
- Verify that no private keys or credential files are present in the git tree:
  - Blocked patterns: `.env` (except `.env.example`), `id_rsa`, `id_ed25519`, `*.pem`, `*.key`, `credentials.json`, `service-account.json`
- Scan staged diffs for accidental tokens:
  Check for `ghp_`, `github_pat_`, Bearer tokens, or private key headers.

### 2. Targeted Semgrep Security Scan
- Run Semgrep specifically against files modified or added in this release.
- Enforce strict reporting terminology: never state '0 vulnerabilities' or '0 defects'; report accurately: '0 findings from scanned ruleset'.

### 3. Encoding & BOM Verification
- Verify that all newly modified `.json`, `.md`, and `.ps1` files are UTF-8 without BOM.

### 4. Workspace Hygiene & Temporary Files
- Inspect working tree for dangling temporary artifacts:
  - `*.bak`, `*.backup`, `scratch/`, test coverage dumps, or debug logs.
- Confirm `.gitignore` properly excludes local machine configs (e.g. `mcp_config.json`, `.serena/`).

### 5. Final Audit Verdict
- Present a concise audit pass/fail matrix to the user before completing the turn.
