#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Antigravity Agent Harness - PostToolUse Guard
Ultra-lightweight syntax & BOM integrity check (< 1ms).
Never runs heavy builds or tests on edit.
"""

import sys
import json
import os

def main():
    try:
        # Zero-overhead bypass switch
        if os.environ.get("ANTIGRAVITY_HOOKS_DISABLED") == "1":
            print(json.dumps({}))
            return

        raw_input = sys.stdin.read()
        if not raw_input:
            print(json.dumps({}))
            return

        payload = json.loads(raw_input)
        tool_call = payload.get("toolCall", {})
        tool_name = tool_call.get("name", "")
        args = tool_call.get("args", {})

        # Fast integrity check on edited files
        if tool_name in {"write_file", "write_to_file", "replace_file_content"}:
            target_file = args.get("TargetFile") or args.get("AbsolutePath")
            if target_file and os.path.exists(target_file):
                # 1. BOM check (read first 3 bytes)
                try:
                    with open(target_file, "rb") as f:
                        header = f.read(3)
                        if header == b"\xef\xbb\xbf":
                            sys.stderr.write(f"[WARN] File contains UTF-8 BOM: {target_file}\n")
                except Exception:
                    pass

                # 2. JSON syntax check (if json file)
                if target_file.lower().endswith(".json"):
                    try:
                        with open(target_file, "r", encoding="utf-8") as f:
                            json.load(f)
                    except Exception as err:
                        sys.stderr.write(f"[SYNTAX ERROR] Invalid JSON in {target_file}: {err}\n")

    except Exception:
        pass

    # PostToolUse always returns {}
    print(json.dumps({}))

if __name__ == "__main__":
    main()
