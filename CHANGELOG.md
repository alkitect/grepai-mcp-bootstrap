# Changelog

## Unreleased

## 0.1.1 — 2026-09-14

- Docs: portal README (Install bootstrap → Wire your repo → Restart; bare mcp-serve warning; Issues help).

## 0.1.0 — 2026-08-17

- Initial public extract: `grepai-mcp-setup` glue for per-project Cursor MCP.
- Merge-only JSON for `.cursor/mcp.json`; optional `--opencode` and `--watch`.
- Git toplevel resolution; `--remove` in the current repo only.
- Pinned grepai download (`GREPAI_VERSION`); refuse overwrite unless `--force`.
- CI: stub grepai tmp-HOME ladder, versioning gate, no Ollama required.
