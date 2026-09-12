#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Antigravity Agent Harness - Stop Guard
Minimal non-blocking status reporter.
Never forces execution continue loops on dirty git state.
"""

import sys
import json
import os

def main():
    try:
        # Non-blocking stop handler
        print(json.dumps({"decision": "allow"}))
    except Exception:
        print(json.dumps({"decision": "allow"}))

if __name__ == "__main__":
    main()
