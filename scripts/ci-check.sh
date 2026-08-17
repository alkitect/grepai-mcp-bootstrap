#!/usr/bin/env bash
# Release gate for grepai-mcp-bootstrap (local + CI).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

_p1='Python/'
_p2='Linux'
_p3='.cursor/plans'
_p4='topics/grepai-mcp-cursor'
_p5='Agent Arena'
FORBIDDEN_RE="${_p1}${_p2}|${_p3}|${_p4}|${_p5}"

hits="$(grep -rE "${FORBIDDEN_RE}" \
  --include='*.sh' --include='*.py' --include='*.md' --include='*.json' --include='*.example' . \
  --exclude-dir=.git --exclude-dir=__pycache__ \
  --exclude='ci-check.sh' 2>/dev/null || true)"
if [[ -n "${hits}" ]]; then
  echo "ci-check: forbidden path refs found:" >&2
  echo "${hits}" >&2
  exit 1
fi

if grep -rE '/home/USER' --include='*.md' . --exclude-dir=.git --exclude='ci-check.sh' >/dev/null 2>&1; then
  echo "ci-check: public markdown must not contain host home paths" >&2
  grep -rE '/home/USER' --include='*.md' . --exclude-dir=.git --exclude='ci-check.sh' >&2 || true
  exit 1
fi

REQUIRED_H2=(
  "## What this does"
  "## Who this is for"
  "## Quick start"
  "## Check it works"
  "## Uninstall"
  "## Limits & safety"
  "## License"
)
for h in "${REQUIRED_H2[@]}"; do
  grep -qFx "${h}" README.md || { echo "ci-check: README missing H2: ${h}" >&2; exit 1; }
done
if grep -qE '\bSSOT\b' README.md; then
  echo "ci-check: README must not use SSOT; say release source" >&2
  exit 1
fi

[[ -f .github/FUNDING.yml ]] || { echo "ci-check: missing .github/FUNDING.yml" >&2; exit 1; }
grep -qE '^[[:space:]]*ko_fi:[[:space:]]*alkitect[[:space:]]*$' .github/FUNDING.yml \
  || { echo "ci-check: .github/FUNDING.yml must set ko_fi: alkitect" >&2; exit 1; }
grep -qF 'ko-fi.com/alkitect' README.md \
  || { echo "ci-check: README must include Ko-fi tip link ko-fi.com/alkitect" >&2; exit 1; }
grep -qF 'ko-fi.com/img/githubbutton_sm.svg' README.md \
  || { echo "ci-check: README must include Ko-fi GitHub button (githubbutton_sm.svg)" >&2; exit 1; }
if grep -qiE 'patreon\.com|buymeacoffee\.com' README.md; then
  echo "ci-check: README must not link Patreon or Buy Me a Coffee" >&2
  exit 1
fi

[[ ! -e scripts/rollout-grepai-watch-tasks.sh ]] \
  || { echo "ci-check: public tree must not ship rollout-grepai-watch-tasks.sh" >&2; exit 1; }

grep -q 'GREPAI_VERSION' scripts/install-to-local.sh \
  || { echo "ci-check: install-to-local.sh must pin GREPAI_VERSION" >&2; exit 1; }

grep -qF '${workspaceFolder}' examples/cursor-mcp.json.example \
  || { echo "ci-check: example MCP JSON must contain \${workspaceFolder}" >&2; exit 1; }

if grep -qE 'Recommended:.*mcp-serve[[:space:]]*$' README.md; then
  echo "ci-check: README must not recommend bare mcp-serve" >&2
  exit 1
fi
grep -q 'bare mcp-serve' README.md \
  || { echo "ci-check: README must warn against global bare mcp-serve" >&2; exit 1; }

if [[ -f docs/PUBLISH.md ]] && grep -qF 'RC-BEFORE-1.0' docs/PUBLISH.md; then
  :
else
  if [[ -f CHANGELOG.md ]] && grep -qE '^## 0\.9\.0' CHANGELOG.md; then
    echo "ci-check: CHANGELOG ## 0.9.0 is not the default first tag" >&2
    exit 1
  fi
  for _vf in docs/PUBLISH.md README.md; do
    if [[ -f "${_vf}" ]] && grep -qE 'v0\.9\.0' "${_vf}"; then
      echo "ci-check: ${_vf} mentions v0.9.0 without RC-BEFORE-1.0" >&2
      exit 1
    fi
  done
fi
grep -qF 'First public tag: v0.1.0' docs/PUBLISH.md \
  || { echo "ci-check: docs/PUBLISH.md must record First public tag: v0.1.0" >&2; exit 1; }

if git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    && git describe --tags --abbrev=0 >/dev/null 2>&1; then
  _tag="$(git describe --tags --abbrev=0)"
  _tag="${_tag#v}"
  _first="$(awk '/^## [0-9]+\.[0-9]+\.[0-9]+/{ sub(/^## /,""); sub(/ .*/,""); print; exit }' CHANGELOG.md)"
  if [[ -n "${_first}" && "${_first}" != "${_tag}" ]]; then
    echo "ci-check: CHANGELOG first dated section ${_first} != git describe ${_tag}" >&2
    exit 1
  fi
fi

find scripts -type f \( -name '*.sh' -o -name 'grepai-mcp-setup' -o -name 'grepai-watch-on-open' -o -name 'verify-grepai-mcp' -o -name 'stub-grepai' \) -print0 \
  | xargs -0 -r bash -n
python3 -m py_compile scripts/lib/json_edit.py

tmp="$(mktemp -d)"
cleanup() { rm -rf "${tmp}"; }
trap cleanup EXIT
export HOME="${tmp}"
export XDG_CONFIG_HOME="${tmp}/.config"
export XDG_STATE_HOME="${tmp}/.local/state"
export XDG_DATA_HOME="${tmp}/.local/share"
export PATH="${tmp}/.local/bin:${PATH}"
mkdir -p "${tmp}/.local/bin"
install -m0755 "${ROOT}/scripts/test/stub-grepai" "${tmp}/.local/bin/grepai"
export GREPAI_BIN="${tmp}/.local/bin/grepai"

"${ROOT}/scripts/install-to-local.sh" --skip-download
test -x "${tmp}/.local/bin/grepai-mcp-setup"
test -x "${tmp}/.local/bin/grepai-watch-on-open"
test -x "${tmp}/.local/bin/verify-grepai-mcp"

fix="${tmp}/fixture"
mkdir -p "${fix}/subdir" "${fix}/.cursor" "${fix}/.vscode"
git -C "${fix}" init -q
git -C "${fix}" config user.email 'ci@example.test'
git -C "${fix}" config user.name 'ci'
cat > "${fix}/.cursor/mcp.json" <<'EOF'
{
  "mcpServers": {
    "other": {
      "command": "true",
      "args": []
    }
  }
}
EOF
cat > "${fix}/.vscode/tasks.json" <<'EOF'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "keep-me",
      "type": "shell",
      "command": "true"
    }
  ]
}
EOF
git -C "${fix}" add -A
git -C "${fix}" commit -qm 'fixture'

(cd "${fix}/subdir" && grepai-mcp-setup --watch)
python3 - <<PY
import json
from pathlib import Path
root = Path("${fix}")
mcp = json.loads((root / ".cursor/mcp.json").read_text())
assert "other" in mcp["mcpServers"], mcp
assert "grepai" in mcp["mcpServers"], mcp
args = mcp["mcpServers"]["grepai"]["args"]
assert args == ["mcp-serve", "\${workspaceFolder}"], args
cmd = mcp["mcpServers"]["grepai"]["command"]
assert cmd.endswith("/grepai"), cmd
gitignore = (root / ".gitignore").read_text()
assert ".grepai/" in gitignore
tasks = json.loads((root / ".vscode/tasks.json").read_text())
labels = [t.get("label") for t in tasks["tasks"]]
assert "keep-me" in labels, labels
watch = next(t for t in tasks["tasks"] if t.get("label", "").startswith("grepai: watch"))
assert watch["command"] == "grepai-watch-on-open", watch
assert "scripts/grepai-watch-on-open.sh" not in json.dumps(watch)
print("cursor merge ok")
PY
grep -q '.grepai/' "${fix}/.gitignore"
test -f "${fix}/.grepai/config.yaml"

cat > "${fix}/opencode.json" <<'EOF'
{
  "default_agent": "keep",
  "extra": true,
  "mcp": {
    "keep": {"type": "local", "enabled": true, "command": ["true"]}
  }
}
EOF
(cd "${fix}" && grepai-mcp-setup --opencode)
python3 - <<PY
import json
from pathlib import Path
data = json.loads(Path("${fix}/opencode.json").read_text())
assert data["default_agent"] == "keep"
assert data["extra"] is True
assert "keep" in data["mcp"]
assert "grepai" in data["mcp"]
print("opencode merge ok")
PY

bad="${fix}/.cursor/mcp.json"
cp "${bad}" "${bad}.bak"
printf '{not-json' > "${bad}"
set +e
(cd "${fix}" && grepai-mcp-setup --watch)
rc=$?
set -e
[[ "${rc}" -eq 2 ]] || { echo "ci-check: expected exit 2 on invalid JSON, got ${rc}" >&2; exit 1; }
cmp -s "${bad}" <(printf '{not-json') || { echo "ci-check: invalid JSON file was rewritten" >&2; exit 1; }
mv "${bad}.bak" "${bad}"

(cd "${fix}" && verify-grepai-mcp)
(cd "${fix}" && grepai-mcp-setup --watch)

(cd "${fix}" && grepai-mcp-setup --remove --watch)
python3 - <<PY
import json
from pathlib import Path
root = Path("${fix}")
mcp = json.loads((root / ".cursor/mcp.json").read_text())
assert "grepai" not in mcp.get("mcpServers", {}), mcp
assert "other" in mcp["mcpServers"]
tasks = json.loads((root / ".vscode/tasks.json").read_text())
labels = [t.get("label") for t in tasks["tasks"]]
assert "keep-me" in labels
assert not any(str(l).startswith("grepai: watch") for l in labels)
print("remove ok")
PY
(cd "${fix}" && grepai-mcp-setup --remove --watch)

"${ROOT}/scripts/uninstall-from-local.sh"
test ! -e "${tmp}/.local/bin/grepai-mcp-setup"
test ! -e "${tmp}/.local/bin/grepai-watch-on-open"
test ! -e "${tmp}/.local/bin/verify-grepai-mcp"
test -x "${tmp}/.local/bin/grepai"

echo "ci-check: OK"
