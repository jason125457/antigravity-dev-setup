#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Antigravity Agent Harness - PreToolUse Guard
Enforces least privilege, credential protection, destructive command gating,
and universal GitHub remote write protection.
"""

import sys
import json
import os
import re

if sys.platform == "win32":
    import io
    sys.stdin = io.TextIOWrapper(sys.stdin.buffer, encoding="utf-8")
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

def main():
    try:
        # Zero-overhead bypass switch
        if os.environ.get("ANTIGRAVITY_HOOKS_DISABLED") == "1":
            print(json.dumps({"decision": "allow"}))
            return

        raw_input = sys.stdin.read()
        if not raw_input:
            print(json.dumps({"decision": "allow"}))
            return

        payload = json.loads(raw_input)
        tool_call = payload.get("toolCall", {})
        tool_name = tool_call.get("name", "")
        args = tool_call.get("args", {})

        # ---------------------------------------------------------
        # 1. Credential & Private Key Access Policy
        # ---------------------------------------------------------
        file_tools = {
            "read_file", "view_file", "write_file", "write_to_file",
            "replace_file_content", "multi_replace_file_content"
        }
        if tool_name in file_tools:
            target_path = (args.get("TargetFile") or args.get("AbsolutePath") or args.get("path") or "").replace("\\", "/").strip()
            filename = os.path.basename(target_path).lower()

            # Exception: .env.example / templates are completely safe to read and write
            if filename.endswith(".example") or filename.endswith(".sample") or filename.endswith(".template") or "example" in filename:
                print(json.dumps({"decision": "allow"}))
                return

            # Strict Deny: SSH private keys and certificates
            ssh_key_patterns = [
                "id_rsa", "id_ed25519", "id_ecdsa", "id_dsa"
            ]
            if any(k in filename for k in ssh_key_patterns) or (filename.endswith((".pem", ".key", ".pfx", ".p12", ".keystore")) and not filename.endswith(".pub")):
                print(json.dumps({
                    "decision": "deny",
                    "reason": f"Access to SSH private keys and certificate files is strictly denied: {filename}"
                }))
                return

            # Sensitive Credentials: .env, .npmrc, .git-credentials, token files
            sensitive_credential_files = [
                ".env", ".npmrc", ".git-credentials", "credentials.json",
                "service-account.json", "client_secret.json"
            ]
            is_sensitive = any(sf == filename or filename.startswith(".env.") for sf in sensitive_credential_files)
            if is_sensitive:
                if tool_name in {"read_file", "view_file"}:
                    print(json.dumps({
                        "decision": "force_ask",
                        "reason": f"Reading credential file requires explicit user confirmation: {filename}"
                    }))
                    return
                else:
                    print(json.dumps({
                        "decision": "deny",
                        "reason": f"Modifying or creating credential files directly is blocked: {filename}"
                    }))
                    return

        # ---------------------------------------------------------
        # 2. Shell Command Safety & Remote Git Write Gating
        # ---------------------------------------------------------
        if tool_name == "run_command":
            cmd = args.get("CommandLine", "").strip()
            cmd_lower = cmd.lower()

            # Universal GitHub/Git remote write guard
            git_write_patterns = [
                r"\bgit\s+push\b",
                r"\bgh\s+pr\s+create\b",
                r"\bgh\s+repo\s+create\b",
                r"\bgh\s+repo\s+delete\b",
                r"\bgh\s+release\s+create\b"
            ]
            if any(re.search(pat, cmd_lower) for pat in git_write_patterns):
                print(json.dumps({
                    "decision": "force_ask",
                    "reason": f"Remote Git/GitHub write operation requires explicit user authorization: {cmd}"
                }))
                return

            # Destructive local commands guard
            destructive_commands = [
                "rm ", "rmdir", "del ", "del /", "erase ", "rd /",
                "mkfs", "remove-item", "drop database", "drop table",
                "shutdown", "reboot"
            ]
            is_destructive = any(dc in cmd_lower for dc in destructive_commands)
            is_disk_format = bool(re.search(r"\bformat\s+[a-z]:", cmd_lower)) or ("format-volume" in cmd_lower)

            if is_destructive or is_disk_format:
                print(json.dumps({
                    "decision": "force_ask",
                    "reason": f"Potentially destructive command detected: {cmd}"
                }))
                return

        # ---------------------------------------------------------
        # 3. Universal GitHub MCP Write Tools Guard
        # ---------------------------------------------------------
        server = ""
        tool = ""
        if tool_name == "call_mcp_tool":
            server = args.get("ServerName", "").lower()
            tool = args.get("ToolName", "").lower()
        elif tool_name.startswith("mcp_"):
            parts = tool_name.split("_", 2)
            server = parts[1].lower() if len(parts) > 1 else ""
            tool = parts[2].lower() if len(parts) > 2 else ""

        if server == "github":
            github_write_tools = {
                "create_repository", "delete_repository", "create_pull_request",
                "create_branch", "create_or_update_file", "delete_file",
                "merge_pull_request", "update_pull_request_branch",
                "add_issue_comment", "create_issue"
            }
            if tool in github_write_tools:
                print(json.dumps({
                    "decision": "force_ask",
                    "reason": f"GitHub MCP write tool requires explicit user confirmation: {server}/{tool}"
                }))
                return

        # ---------------------------------------------------------
        # 4. Standard Non-Destructive Auto-Approve
        # ---------------------------------------------------------
        if server:
            print(json.dumps({
                "decision": "allow",
                "permissionOverrides": [f"mcp({server}/{tool})", f"mcp({server}/*)"]
            }))
            return

        print(json.dumps({"decision": "allow"}))

    except Exception:
        # Fail-safe: prompt user on unexpected errors
        print(json.dumps({"decision": "force_ask"}))

if __name__ == "__main__":
    main()
