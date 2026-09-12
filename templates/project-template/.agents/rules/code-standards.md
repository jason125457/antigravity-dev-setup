---
trigger: model_decision
description: Code quality, testing standards, and minimal-change pair programming conventions.
---

# Code Standards & Quality Guidelines

1. **Minimal Surgical Changes**:
   - Focus edits strictly on the problem domain. Avoid unnecessary refactoring of surrounding code.
2. **Preserve Coding Style**:
   - Maintain established formatting, linting rules, naming conventions, and docstrings.
3. **Verification Before Completion**:
   - Always run the project's local test suite before considering an implementation complete.
4. **Clean Commits**:
   - Keep the working tree clean. Never commit `.env`, `.backup`, or debug logs.
