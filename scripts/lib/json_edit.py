#!/usr/bin/env python3
"""Strict-JSON merge/remove for Cursor MCP, OpenCode, and VS Code tasks."""
from __future__ import annotations

import json
import sys
from pathlib import Path

TASK_LABEL = "grepai: watch · background"
WATCH_TASK = {
    "label": TASK_LABEL,
    "type": "shell",
    "command": "grepai-watch-on-open",
    "args": ["${workspaceFolder}"],
    "detail": "Start grepai background watcher when this folder opens (if not already running).",
    "options": {
        "cwd": "${workspaceFolder}",
        "env": {"PATH": "${env:HOME}/.local/bin:${env:PATH}"},
    },
    "presentation": {
        "reveal": "never",
        "panel": "shared",
        "focus": False,
        "showReuseMessage": False,
        "close": True,
    },
    "runOptions": {"runOn": "folderOpen"},
}


def die_invalid(path: Path, exc: Exception) -> None:
    print(f"invalid JSON in {path}: {exc}", file=sys.stderr)
    sys.exit(2)


def load_obj(path: Path) -> dict:
    if not path.is_file():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        die_invalid(path, exc)
    if not isinstance(data, dict):
        print(f"invalid JSON in {path}: root must be an object", file=sys.stderr)
        sys.exit(2)
    return data


def dump(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def merge_mcp(path: Path, command: str) -> None:
    data = load_obj(path)
    servers = data.get("mcpServers")
    if servers is None:
        servers = {}
        data["mcpServers"] = servers
    if not isinstance(servers, dict):
        print(f"invalid JSON in {path}: mcpServers must be an object", file=sys.stderr)
        sys.exit(2)
    servers["grepai"] = {
        "command": command,
        "args": ["mcp-serve", "${workspaceFolder}"],
    }
    dump(path, data)
    print(f"Wrote {path}")


def merge_opencode(path: Path, binary: str, root: str) -> None:
    data = load_obj(path)
    mcp = data.get("mcp")
    if mcp is None:
        mcp = {}
        data["mcp"] = mcp
    if not isinstance(mcp, dict):
        print(f"invalid JSON in {path}: mcp must be an object", file=sys.stderr)
        sys.exit(2)
    mcp["grepai"] = {
        "type": "local",
        "enabled": True,
        "command": [binary, "mcp-serve", root],
    }
    dump(path, data)
    print(f"Wrote {path}")


def merge_task(path: Path) -> None:
    data = load_obj(path)
    if not data:
        data = {"version": "2.0.0", "tasks": []}
    if "version" not in data:
        data["version"] = "2.0.0"
    tasks = data.get("tasks")
    if tasks is None:
        tasks = []
        data["tasks"] = tasks
    if not isinstance(tasks, list):
        print(f"invalid JSON in {path}: tasks must be an array", file=sys.stderr)
        sys.exit(2)
    replaced = False
    for i, item in enumerate(tasks):
        if isinstance(item, dict) and item.get("label") == TASK_LABEL:
            tasks[i] = WATCH_TASK
            replaced = True
            break
    if not replaced:
        tasks.append(WATCH_TASK)
    dump(path, data)
    print(f"Wrote {path}")


def remove_mcp(path: Path) -> None:
    if not path.is_file():
        print(f"OK: no {path}")
        return
    data = load_obj(path)
    servers = data.get("mcpServers")
    if isinstance(servers, dict):
        servers.pop("grepai", None)
        if not servers:
            path.unlink()
            print(f"Removed {path} (no MCP servers left)")
            return
    dump(path, data)
    print(f"Wrote {path}")


def remove_opencode(path: Path) -> None:
    if not path.is_file():
        print(f"OK: no {path}")
        return
    data = load_obj(path)
    mcp = data.get("mcp")
    if isinstance(mcp, dict):
        mcp.pop("grepai", None)
        if not mcp:
            data.pop("mcp", None)
    dump(path, data)
    print(f"Wrote {path}")


def remove_task(path: Path) -> None:
    if not path.is_file():
        print(f"OK: no {path}")
        return
    data = load_obj(path)
    tasks = data.get("tasks")
    if isinstance(tasks, list):
        data["tasks"] = [
            t
            for t in tasks
            if not (isinstance(t, dict) and t.get("label") == TASK_LABEL)
        ]
    dump(path, data)
    print(f"Wrote {path}")


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(
            "usage: json_edit.py merge-mcp|merge-opencode|merge-task|"
            "remove-mcp|remove-opencode|remove-task FILE [args…]",
            file=sys.stderr,
        )
        return 2
    cmd = argv[0]
    path = Path(argv[1])
    if cmd == "merge-mcp":
        if len(argv) < 3:
            print("merge-mcp FILE COMMAND", file=sys.stderr)
            return 2
        merge_mcp(path, argv[2])
    elif cmd == "merge-opencode":
        if len(argv) < 4:
            print("merge-opencode FILE BINARY ROOT", file=sys.stderr)
            return 2
        merge_opencode(path, argv[2], argv[3])
    elif cmd == "merge-task":
        merge_task(path)
    elif cmd == "remove-mcp":
        remove_mcp(path)
    elif cmd == "remove-opencode":
        remove_opencode(path)
    elif cmd == "remove-task":
        remove_task(path)
    else:
        print(f"unknown command: {cmd}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
