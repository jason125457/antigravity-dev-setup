---
name: project-bootstrap
description: Standard autonomous project onboarding and environment initialization. Use when entering or initializing a new or existing codebase to detect technology stack, check git and package manifests, verify Serena AST readiness, and scaffold workspace rules.
---

# Project Bootstrap Workflow

Autonomous, lightweight, and stack-adaptive project onboarding runbook for Google Antigravity.

## Workflow Phases

### Phase 1: Dynamic Workspace & Stack Detection
1. **Determine Project Root**:
   - Resolve current workspace root via active Git root or current working directory.
   - Never assume parent directories or sibling folders are part of this project.
2. **Inspect Manifests (Lightweight)**:
   - Node.js / Web: `package.json`, `tsconfig.json`, `pnpm-lock.yaml`, `yarn.lock`
   - Python: `pyproject.toml`, `requirements.txt`, `setup.py`
   - Go: `go.mod`
   - Rust: `Cargo.toml`
3. **Inspect Git Health**:
   - Check `git status` to verify branch, staged files, and unstaged modifications before editing.

### Phase 2: Symbol & AST Activation
1. **Activate Serena**:
   - Verify Serena MCP availability.
   - If project symbols are not active, invoke `activate_project` quietly.
   - Indexing runs in the background; do not block normal read actions.

### Phase 3: Workspace Scaffold (.agents/)
1. **Scaffold Directory Structure (if missing)**:
   - Ensure `.agents/rules/` exists for progressive rules.
   - If project is missing a project-level `GEMINI.md` and is established, generate a concise (~30 lines) project instruction file containing:
     - Project Purpose
     - Tech Stack & Commands (`build`, `test`)
     - Key Directories
     - Project-specific Constraints

### Phase 4: Baseline Verification
1. Run the project's native test or typecheck command (e.g. `npm test` or `pytest`) to establish a clean starting baseline.
2. Report readiness to the user concisely.
