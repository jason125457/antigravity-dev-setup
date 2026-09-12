# Antigravity Agent Harness Guidelines

This document establishes standard operating procedures for Permission Profiles, Lifecycle Hooks, and Planning Tiering across Antigravity development workspaces.

---

## 1. Permission Profile & Sandboxing Strategy

Antigravity 2.0 provides granular tool execution policies. The recommended standard setting is:

### Recommended Default: `Proceed in Sandbox`
- **Why**: Replaces unconditional `Always Proceed` with an isolated execution container, shielding host system configurations while allowing fluid local development.
- **Access Boundary Matrix**:

| Operation Category | Default Action | Technical Enforcement |
| :--- | :---: | :--- |
| **In-workspace Read / Edit** | `Allow` | Executed directly or within sandbox |
| **Out-of-workspace Write** | `Ask` | PreToolUse Guard prompt |
| **Destructive Commands** (`rm -rf`, `format`, `drop`) | `Force Ask` | PreToolUse Guard mandatory confirmation |
| **Git Push & Remote Branch Creation** | `Force Ask` | PreToolUse Guard universal intercept |
| **GitHub MCP Write Tools** (`create_repo`, `PR`) | `Force Ask` | PreToolUse Guard universal intercept |
| **Credentials Read** (`.env`, `credentials.json`) | `Force Ask` | PreToolUse Guard sensitive check |
| **Credentials Write / Delete** | `Deny` | PreToolUse Guard hard block |
| **SSH Private Keys & Certificates** (`id_rsa`, `*.pem`)| `Deny` | PreToolUse Guard hard block |
| **Safe Templates** (`.env.example`) | `Allow` | PreToolUse Guard whitelisted |

---

## 2. Planning & Artifact Strategy

To prevent context window bloat and unnecessary conversational latency, tasks are triaged into three strict tiers:

```
[ Incoming Task ]
       │
       ▼
 規模為單一檔案 / 局部小幅度修改 / 確定已知 Bug？
  ├── 是 ──> [ Tier 1: Direct Mode ]
  │          直接實作與驗證，不生成 implementation_plan.md
  │
  └── 否 ──> 涉及跨多個模組、新功能增加或架構擴充？
       │
       ▼
 屬於已知熟悉架構的多檔案功能？
  ├── 是 ──> [ Tier 2: Planning Mode ]
  │          產出簡明 implementation_plan.md，使用者核准後執行
  │
  └── 否 ──> 涉及重大架構重構、破壞性變更或陌生專案探索？
             └── [ Tier 3: Planning + Artifact Review Mode ]
                 深入設計、逐步 Review Checkpoint，並更新 walkthrough.md
```

---

## 3. Lifecycle Hooks Architecture

Hooks execute synchronously at specific agent lifecycle events:
- **PreToolUse (`pre_tool_guard.py`)**: Safety gate protecting credentials, blocking dangerous operations, and requiring confirmation for remote Git writes.
- **PostToolUse (`post_tool_guard.py`)**: Lightweight format integrity check (< 1ms). Checks JSON parse and verifies zero UTF-8 BOM introduction. Never runs heavy builds on edit.
- **Stop (`stop_guard.py`)**: Clean termination without trapping the agent in execution continue loops.
- **Fast Bypass Switch**: Set `ANTIGRAVITY_HOOKS_DISABLED=1` to disable all hooks instantly.
