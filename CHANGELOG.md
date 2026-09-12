# Changelog

All notable changes to the `antigravity-dev-setup` environment will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.0.0-rc1] - 2026-09-12

### Added
- **Core MCP Servers (7 Servers)**:
  - `serena`: Codebase AST navigation and symbol reference via `uvx git+https://github.com/oraios/serena`.
  - `context7`: Third-party library documentation via `https://mcp.context7.com/mcp`.
  - `playwright`: Headless browser testing and DOM validation via `@playwright/mcp@0.0.80`.
  - `github`: Remote repo and PR review toolset via `https://api.githubcopilot.com/mcp/`.
  - `chrome-devtools`: CDP network and console diagnostics via `chrome-devtools-mcp@1.9.0`.
  - `semgrep`: SAST security scanning via `semgrep@1.177.0`.
  - `docling`: 100% offline structured document intelligence via `docling-mcp==3.2.0`.
- **Plugins & Frameworks**:
  - `obra/superpowers` v6.3.0 for structured planning, TDD, and agentic workflows.
- **Document Intelligence CLI Tools**:
  - `markitdown` 0.1.7 (with `[all]`) for fast offline Office-to-Markdown conversion.
  - `mineru` 3.4.5 (pipeline mode with `transformers==4.57.6` and `six`) for local deep OCR and figure cropping.
- **Enterprise Safety**:
  - Pure `CurrentUser` scope installation.
  - Zero elevation / no Administrator rights required.
  - Preserves system proxy, antivirus, and PowerShell ExecutionPolicy settings.
  - Safe JSON configuration merge with automatic timestamped backups.
- **Testing & Verification**:
  - `verify.ps1` 11-point health check script.
  - `install.ps1` with `-DryRun`, `-InstallDocumentTools`, and `-NonInteractive` flags.

### Security
- Comprehensive audit passed: 0 credentials, 0 hardcoded personal user paths, 0 customer documents.
- Mandatory local-only policy for confidential documents and customer data.
