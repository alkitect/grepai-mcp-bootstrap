# grepai MCP bootstrap

Wire [grepai](https://github.com/yoanbernabeu/grepai) as a per-project MCP server for Cursor so local semantic search survives a restart.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/alkitect)

## What this does

Cursor’s global MCP spawn often runs `grepai mcp-serve` with no project path. The server then logs that no workspace was found and exposes **zero tools**.

This kit installs a small CLI that initializes a local grepai index and **merges** a working Cursor MCP entry into your repo: `mcp-serve` plus `${workspaceFolder}`. An optional folder-open task restarts the index watcher after reboot.

**Safe by default:** JSON is merged, not replaced. Watcher and OpenCode wiring are opt-in. Install does not overwrite a different grepai binary unless you pass `--force`.

## Who this is for

- **In:** developers using Cursor (Cline, Kilo, and Roo inherit the same project MCP file) who want local semantic search without a paid codebase index
- **In:** Ubuntu/Linux with Ollama and the `nomic-embed-text` embedder
- **Not for:** a replacement for grepai itself; Hermes Desktop MCP; Cursor’s paid index; machines without Ollama (the index will not build)

## Quick start

```bash
git clone https://github.com/alkitect/grepai-mcp-bootstrap.git
cd grepai-mcp-bootstrap
./scripts/install-to-local.sh
cd /path/to/YOUR_REPO
grepai-mcp-setup
```

Restart Cursor, then **MCP: Show Status** and confirm grepai is connected.

**What you installed:** `grepai-mcp-setup`, `grepai-watch-on-open`, and `verify-grepai-mcp` in `~/.local/bin`, plus a pinned grepai release tarball from yoanbernabeu/grepai unless one already matches the pin.

**Stay safe before enabling:** do **not** add grepai to `~/.cursor/mcp.json` with **bare mcp-serve** (no project path — zero tools). The per-project file must pass `${workspaceFolder}` as the MCP argument. Add `--watch` only after verify looks good.

**Needs:** Linux, `git`, `python3`, `curl`. Ollama with `nomic-embed-text` pulled (`ollama pull nomic-embed-text`). Cursor with MCP enabled.

## Check it works

Glue is installed when `verify-grepai-mcp` exits 0 from your git repo (Ollama and Cursor are warnings, not failures). User success is Cursor **MCP: Show Status** listing grepai tools and a first search hitting the local index.

```bash
cd /path/to/YOUR_REPO
verify-grepai-mcp
```

- If verify fails on `${workspaceFolder}`: re-run `grepai-mcp-setup` from the git repo (not a random folder).
- If MCP shows zero tools: remove any global grepai MCP entry and restart Cursor.

Maintainers: `./scripts/ci-check.sh`.

## Uninstall

```bash
cd /path/to/YOUR_REPO
grepai-mcp-setup --remove
# optional: --watch and/or --opencode if you enabled those
cd /path/to/grepai-mcp-bootstrap
./scripts/uninstall-from-local.sh
```

`--purge-grepai` also deletes `~/.local/bin/grepai`. Uninstall does not walk every project.

## Configure

Cursor-only is the happy path. OpenCode uses a different file and an **absolute** repo path:

```bash
grepai-mcp-setup --opencode
```

Keep the index watcher alive after reboot (Cursor/VS Code `folderOpen` task; enable automatic tasks when prompted):

```bash
grepai-mcp-setup --watch
```

Already have grepai: `./scripts/install-to-local.sh --skip-download`. Point at another binary with `GREPAI_BIN`. Overwrite a mismatched pin with `--force`.

Ask agents to call `grepai_search` (and `grepai_trace_*`) before grepping blindly.

## How it works

Machine install copies the glue CLIs. Per-project setup resolves the git toplevel, runs `grepai init`, gitignores `.grepai/`, and upserts `mcpServers.grepai` with an absolute `command` and literal `${workspaceFolder}` in `args`. OpenCode gets `mcp.grepai` with an absolute path. The watcher task calls `grepai-watch-on-open` from `~/.local/bin`, not a copy inside your repo.

## Limits & safety

This writes JSON under the current git repo and can download a grepai binary into `~/.local/bin`.

- **Platform:** Linux; Cursor MCP; optional OpenCode. Hermes is out of scope.
- **Kill-switch:** `grepai-mcp-setup --remove` in the repo, then `./scripts/uninstall-from-local.sh`.
- **Defaults:** merge-only strict JSON (comments are dropped on write); no global MCP installer; watcher opt-in.
- **Tradeoffs:** you still depend on upstream grepai releases and a local embedder. A terminal that is not inside the git work tree will exit 2.
- This GitHub repo is the release source for tagged releases and public docs — see [CONTRIBUTING.md](CONTRIBUTING.md)

## License

MIT — see [LICENSE](LICENSE) (alkitect glue scripts). The downloaded grepai binary remains [yoanbernabeu/grepai](https://github.com/yoanbernabeu/grepai) under that project’s license. Pin: `GREPAI_VERSION` in `install-to-local.sh`.

Optional tip jar: [ko-fi.com/alkitect](https://ko-fi.com/alkitect)
