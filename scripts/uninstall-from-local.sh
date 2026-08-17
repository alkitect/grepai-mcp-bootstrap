#!/usr/bin/env bash
# Remove glue CLIs. Keep grepai unless --purge-grepai.
set -euo pipefail

BIN="${HOME}/.local/bin"
DATA_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/grepai-mcp-bootstrap"
PURGE_GREPAI=0

for arg in "$@"; do
  case "${arg}" in
    --purge-grepai) PURGE_GREPAI=1 ;;
    -h|--help)
      echo "Usage: $(basename "$0") [--purge-grepai]"
      echo "  Removes grepai-mcp-setup, grepai-watch-on-open, verify-grepai-mcp."
      echo "  Keeps ~/.local/bin/grepai unless --purge-grepai."
      echo "  Does not walk projects or edit .cursor/mcp.json."
      exit 0
      ;;
    *)
      echo "Unknown option: ${arg}" >&2
      exit 2
      ;;
  esac
done

rm -f "${BIN}/grepai-mcp-setup"
rm -f "${BIN}/grepai-watch-on-open"
rm -f "${BIN}/verify-grepai-mcp"
rm -rf "${DATA_DIR}"

if [[ "${PURGE_GREPAI}" -eq 1 ]]; then
  rm -f "${BIN}/grepai"
  echo "Removed glue CLIs and ${BIN}/grepai."
else
  echo "Removed glue CLIs. grepai binary kept (use --purge-grepai to delete it)."
fi
echo "Per-repo MCP keys: run grepai-mcp-setup --remove in each project (before uninstall)."
