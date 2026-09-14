# grepai MCP bootstrap

Wire [grepai](https://github.com/yoanbernabeu/grepai) as a per-project MCP server for Cursor so local semantic search survives a restart.

[Quick start](#quick-start) · [Releases](https://github.com/alkitect/grepai-mcp-bootstrap/releases) · [License](#license)

Latest release notes: [CHANGELOG.md](CHANGELOG.md) and [GitHub Releases](https://github.com/alkitect/grepai-mcp-bootstrap/releases). A plain `git clone` follows the default branch tip unless you check out a tag; prefer a tagged release for day-to-day use.

## What this does

Cursor's global MCP spawn often runs `grepai mcp-serve` with no project path. The server then logs that no workspace was found and exposes zero tools.

This kit installs a small CLI that initializes a local grepai index and merges a working Cursor MCP entry into your repo: `mcp-serve` plus `${workspaceFolder}`. An optional folder-open task restarts the index watcher after reboot.

Safe by default: JSON is merged, not replaced. Watcher and OpenCode wiring are opt-in. Install does not overwrite a different grepai binary unless you pass `--force`.

## Who this is for

This is for developers using Cursor (Cline, Kilo, and Roo inherit the same project MCP file) who want local semantic search without a paid codebase index, on Ubuntu/Linux with Ollama and the `nomic-embed-text` embedder.

It is not a replacement for grepai itself, Hermes Desktop MCP, Cursor's paid index, or machines without Ollama (the index will not build).

## Quick start

Machine install copies glue CLIs into `~/.local/bin` and may download a pinned grepai release. Per-project setup runs in each git repo you care about. MCP means Model Context Protocol: Cursor loads tools from a local server. `${workspaceFolder}` is Cursor's placeholder for the open project root so grepai knows which tree to index.

Then: [Install bootstrap](#install-bootstrap) → [Wire your repo](#wire-your-repo) → [Restart Cursor / MCP status](#restart-cursor--mcp-status).

### Install bootstrap

Needs: Linux, `git`, `python3`, `curl`. Ollama with `nomic-embed-text` pulled (`ollama pull nomic-embed-text`). Cursor with MCP enabled.

Stable path: clone or download a release tag from [Releases](https://github.com/alkitect/grepai-mcp-bootstrap/releases), then run the install script. Tip of the default branch is fine for contributors.

```bash
git clone https://github.com/alkitect/grepai-mcp-bootstrap.git
cd grepai-mcp-bootstrap
# optional: git checkout vX.Y.Z   # pin to a release tag
./scripts/install-to-local.sh
```

That installs `grepai-mcp-setup`, `grepai-watch-on-open`, and `verify-grepai-mcp` in `~/.local/bin`, plus a pinned grepai tarball unless one already matches the pin.

### Wire your repo

Do not add grepai to `~/.cursor/mcp.json` with bare mcp-serve and no project path: that yields zero tools. The per-project file must pass `${workspaceFolder}` as the MCP argument.

```bash
cd /path/to/YOUR_REPO
grepai-mcp-setup
```

Setup resolves the git toplevel, runs `grepai init`, gitignores `.grepai/`, and upserts `mcpServers.grepai` with an absolute `command` and literal `${workspaceFolder}` in `args`. Add `--watch` only after verify looks good.

### Restart Cursor / MCP status

Restart Cursor, then open MCP: Show Status and confirm grepai is connected with tools listed. User success is a first search hitting the local index.

## Check it works

Glue is installed when `verify-grepai-mcp` exits 0 from your git repo (Ollama and Cursor are warnings, not failures). User success is Cursor MCP: Show Status listing grepai tools and a search that hits the local index.

<details>
<summary>Optional confirmation</summary>

```bash
cd /path/to/YOUR_REPO
verify-grepai-mcp
```

If verify fails on `${workspaceFolder}`, re-run `grepai-mcp-setup` from the git repo (not a random folder). If MCP shows zero tools, remove any global grepai MCP entry and restart Cursor.

Maintainers: `./scripts/ci-check.sh`.

</details>

Questions or a stuck install: open a GitHub [Issue](https://github.com/alkitect/grepai-mcp-bootstrap/issues) or see [CONTRIBUTING.md](CONTRIBUTING.md).

## Support my work

Tip jar for the next desktop fix. Or a coffee so the next script stays boring on purpose.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/alkitect/?hidefeed=true&widget=true&embed=true)

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

Cursor-only is the happy path. OpenCode uses a different file and an absolute repo path:

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

- Platform: Linux; Cursor MCP; optional OpenCode. Hermes is out of scope.
- Kill-switch: `grepai-mcp-setup --remove` in the repo, then `./scripts/uninstall-from-local.sh`.
- Defaults: merge-only strict JSON (comments are dropped on write); no global MCP installer; watcher opt-in.
- Tradeoffs: you still depend on upstream grepai releases and a local embedder. A terminal that is not inside the git work tree will exit 2.
- This GitHub repo is the release source for tagged releases and public docs. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE) (alkitect glue scripts). The downloaded grepai binary remains [yoanbernabeu/grepai](https://github.com/yoanbernabeu/grepai) under that project's license. Pin: `GREPAI_VERSION` in `install-to-local.sh`.

Optional tip jar: [ko-fi.com/alkitect](https://ko-fi.com/alkitect/?hidefeed=true&widget=true&embed=true)
