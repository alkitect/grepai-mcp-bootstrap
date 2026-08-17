# Implementation

Glue around the upstream [grepai](https://github.com/yoanbernabeu/grepai) CLI. This repo does not vendor grepai source.

## Machine vs project

1. `install-to-local.sh` copies `grepai-mcp-setup`, `grepai-watch-on-open`, and `verify-grepai-mcp` to `~/.local/bin`, and `json_edit.py` under `~/.local/share/grepai-mcp-bootstrap/`. It downloads a pinned grepai tarball (`GREPAI_VERSION`) unless `--skip-download`. A different installed version is refused unless `--force`. `GREPAI_BIN` pointing elsewhere is never clobbered.
2. `grepai-mcp-setup` must run inside a git work tree. It uses `git rev-parse --show-toplevel` (not the current directory).

## Cursor MCP

Merge `mcpServers.grepai` only:

- `command`: absolute path of `GREPAI_BIN` at setup time
- `args`: `["mcp-serve", "${workspaceFolder}"]` as a **literal** string (Cursor expands it)

Global `~/.cursor/mcp.json` with bare `mcp-serve` and no path is the documented failure mode (zero tools). This kit does not write that file.

## OpenCode

`--opencode` merges `mcp.grepai` only (`type: local`, absolute binary + absolute repo root). Other keys stay.

## Watcher

`--watch` upserts a VS Code/Cursor task labeled `grepai: watch · background`. The command is `grepai-watch-on-open` on PATH (`${env:HOME}/.local/bin`). The wrapper is not copied into the consumer repo. It always exits 0 (folderOpen must stay green) and can insert `T` into an old `last_index_time` value.

## Remove and uninstall

`grepai-mcp-setup --remove` edits the current git toplevel only. `uninstall-from-local.sh` removes glue binaries; `--purge-grepai` also removes `~/.local/bin/grepai`.

## JSON

Strict JSON only. Invalid files exit 2 with no write. A successful merge rewrites the file (comments are lost).

## Verify

`verify-grepai-mcp` fails if the project MCP file is missing `${workspaceFolder}`. Ollama, Cursor CLI, and the watcher task are WARN unless `--strict`. CI uses a stub `grepai` and must pass without Ollama.
