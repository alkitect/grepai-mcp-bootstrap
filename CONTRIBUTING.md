# Contributing

## README conventions

Public README required H2s (exact strings; enforced by `./scripts/ci-check.sh`):

```text
## What this does
## Who this is for
## Quick start
## Check it works
## Uninstall
## Limits & safety
## License
```

Put the beginner path (install / verify / uninstall) above limits. Do not put private monorepo paths or the token `SSOT` in README prose — say “release source” instead.

Also enforced by `./scripts/ci-check.sh`:

- `.github/FUNDING.yml` with `ko_fi: alkitect`
- README Ko-fi GitHub button (`githubbutton_sm.svg` → `ko-fi.com/alkitect`) under the tagline
- README soft tip containing `ko-fi.com/alkitect` (after License)
- README must not link Patreon or Buy Me a Coffee

Gate: `./scripts/ci-check.sh`.

## Versioning

First public tag is recorded in `docs/PUBLISH.md` (`First public tag:`). Default is **0.1.0**. Never copy another alkitect repo’s tag. Use `RC-BEFORE-1.0` in PUBLISH only for an intentional 0.9.x RC. After the first tag, bump from CHANGELOG Unreleased (`feat` → minor, `fix` → patch). Maintainers: `./scripts/ci-check.sh` must pass before tag.

## Bug reports

Please include:

- Distro
- `grepai version` and `GREPAI_BIN` if set
- Whether Cursor **MCP: Show Status** lists grepai tools
- The `grepai` block from `.cursor/mcp.json` (redact other servers)

## Behavior changes

If you change setup, merge, or watcher behavior, update [docs/IMPLEMENTATION.md](docs/IMPLEMENTATION.md).

Run before PR:

```bash
find scripts -type f \( -name '*.sh' -o -name 'grepai-mcp-setup' -o -name 'grepai-watch-on-open' -o -name 'verify-grepai-mcp' \) -print0 \
  | xargs -0 -r bash -n
./scripts/ci-check.sh
```

## Maintenance

After the first public tag, edit **this** repository only. Do not keep a second scripts tree elsewhere. A private host may keep a rollout helper that only calls `grepai-mcp-setup --watch` from PATH — it must not ship installers.

## Safety defaults

Do not add a global MCP installer. Do not overwrite a mismatched grepai binary without `--force`. Merge must refuse invalid JSON (exit 2).
