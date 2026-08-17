# Publish notes

Before tag: README must pass `./scripts/ci-check.sh` (required H2s + README ban tokens + Ko-fi `FUNDING.yml` / tip link). See [CONTRIBUTING.md](../CONTRIBUTING.md) § README conventions.

First public tag: v0.1.0

Default first tag is 0.1.0. Never copy another alkitect repo’s tag. Use `RC-BEFORE-1.0` in this file only for an intentional 0.9.x RC.

```bash
./scripts/ci-check.sh
git tag -a v0.1.0 -m "v0.1.0"
git push origin main
git push origin v0.1.0
```

Repo URL: `https://github.com/alkitect/grepai-mcp-bootstrap`

## GitHub About

| Field | Value |
|-------|--------|
| Description | Wire grepai as a per-project MCP server for Cursor and OpenCode without a paid codebase index |
| Website | _(empty — tip via README Ko-fi badge)_ |
| Topics | `grepai`, `mcp`, `cursor`, `opencode`, `ollama`, `semantic-search`, `linux` |

```bash
gh repo edit alkitect/grepai-mcp-bootstrap \
  --description "Wire grepai as a per-project MCP server for Cursor and OpenCode without a paid codebase index" \
  --homepage "" \
  --add-topic grepai --add-topic mcp --add-topic cursor \
  --add-topic opencode --add-topic ollama --add-topic semantic-search --add-topic linux
```

Sidebar (manual if shown): Releases ✓ · Packages ✗ · Deployments ✗
