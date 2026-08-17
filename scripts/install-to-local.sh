#!/usr/bin/env bash
# Install glue CLIs to ~/.local/bin and optionally download pinned grepai.
# Usage: install-to-local.sh [--skip-download] [--force]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="${HOME}/.local/bin"
DATA_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/grepai-mcp-bootstrap"
GREPAI_VERSION="${GREPAI_VERSION:-v0.35.0}"
DEST_GREPAI="${BIN}/grepai"
SKIP_DOWNLOAD=0
FORCE=0

for arg in "$@"; do
  case "${arg}" in
    --skip-download) SKIP_DOWNLOAD=1 ;;
    --force) FORCE=1 ;;
    -h|--help)
      echo "Usage: $(basename "$0") [--skip-download] [--force]"
      echo "  Installs grepai-mcp-setup, grepai-watch-on-open, verify-grepai-mcp."
      echo "  Downloads pinned grepai (${GREPAI_VERSION}) unless --skip-download."
      echo "  Refuses to overwrite a different grepai version unless --force."
      exit 0
      ;;
    *)
      echo "Unknown option: ${arg}" >&2
      exit 2
      ;;
  esac
done

mkdir -p "${BIN}" "${DATA_DIR}"
install -m0755 "${ROOT}/scripts/grepai-mcp-setup" "${BIN}/grepai-mcp-setup"
install -m0755 "${ROOT}/scripts/grepai-watch-on-open" "${BIN}/grepai-watch-on-open"
install -m0755 "${ROOT}/scripts/verify-grepai-mcp" "${BIN}/verify-grepai-mcp"
install -m0644 "${ROOT}/scripts/lib/json_edit.py" "${DATA_DIR}/json_edit.py"
echo "Installed glue to ${BIN} and ${DATA_DIR}"

download_grepai() {
  local arch os tarball url tmp
  arch="$(uname -m)"
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  case "${arch}" in
    x86_64) arch="amd64" ;;
    aarch64) arch="arm64" ;;
    *)
      echo "Unsupported architecture: ${arch}" >&2
      exit 2
      ;;
  esac
  tarball="grepai_${GREPAI_VERSION#v}_${os}_${arch}.tar.gz"
  url="https://github.com/yoanbernabeu/grepai/releases/download/${GREPAI_VERSION}/${tarball}"
  tmp="$(mktemp -d)"
  echo "Downloading ${url} ..."
  if ! curl -fsSL "${url}" -o "${tmp}/${tarball}"; then
    rm -rf "${tmp}"
    echo "Download failed. Check GREPAI_VERSION (${GREPAI_VERSION}) and network." >&2
    exit 2
  fi
  tar -xzf "${tmp}/${tarball}" -C "${tmp}"
  install -m0755 "${tmp}/grepai" "${DEST_GREPAI}"
  rm -rf "${tmp}"
  echo "Installed ${DEST_GREPAI} (${GREPAI_VERSION})"
  "${DEST_GREPAI}" version
}

installed_version() {
  local out
  out="$("${DEST_GREPAI}" version 2>/dev/null || true)"
  printf '%s' "${out}"
}

if [[ -n "${GREPAI_BIN:-}" && "${GREPAI_BIN}" != "${DEST_GREPAI}" ]]; then
  if [[ ! -x "${GREPAI_BIN}" ]]; then
    echo "GREPAI_BIN is not executable: ${GREPAI_BIN}" >&2
    exit 2
  fi
  echo "Using existing GREPAI_BIN=${GREPAI_BIN} (did not clobber ${DEST_GREPAI})"
elif [[ "${SKIP_DOWNLOAD}" -eq 1 ]]; then
  if [[ -n "${GREPAI_BIN:-}" && -x "${GREPAI_BIN}" ]]; then
    echo "Skipped download; GREPAI_BIN=${GREPAI_BIN}"
  elif [[ -x "${DEST_GREPAI}" ]]; then
    echo "Skipped download; keeping ${DEST_GREPAI}"
  else
    echo "No grepai binary and --skip-download set." >&2
    exit 2
  fi
else
  if [[ -x "${DEST_GREPAI}" ]]; then
    have="$(installed_version)"
    if printf '%s' "${have}" | grep -qF "${GREPAI_VERSION#v}"; then
      echo "Keeping ${DEST_GREPAI} (matches pin ${GREPAI_VERSION})"
    elif [[ "${FORCE}" -eq 1 ]]; then
      echo "Overwriting ${DEST_GREPAI} with pin ${GREPAI_VERSION} (--force)"
      download_grepai
    else
      echo "Existing grepai version does not match pin ${GREPAI_VERSION}:" >&2
      echo "  ${have}" >&2
      echo "Re-run with --force to overwrite, or set GREPAI_BIN to another path." >&2
      exit 2
    fi
  else
    download_grepai
  fi
fi

echo "Next: cd /path/to/YOUR_REPO && grepai-mcp-setup"
echo "Needs: Ollama with nomic-embed-text. Do not use a global bare mcp-serve MCP entry."
