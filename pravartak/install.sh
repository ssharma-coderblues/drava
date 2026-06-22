#!/usr/bin/env bash
#
# install.sh — Pravartak convenience installer (spec §6.1).
#
# The CANONICAL install is a manual copy:
#     git clone https://github.com/vesta-platform/pravartak.git /tmp/pravartak-lib
#     cp -r /tmp/pravartak-lib/pravartak ./your-project/
#
# This script is the curl convenience wrapper. It does exactly the same thing: download the
# library archive, extract it, and place the pravartak/ directory in the current directory.
# Nothing else — no daemons, no global config, no shell hooks. It is intentionally short so
# it can be audited at a glance before being piped to a shell.
#
# Usage:
#   curl -sSL https://pravartak.vesta-platform.dev/install.sh | bash
#   curl -sSL https://pravartak.vesta-platform.dev/install.sh | bash -s -- 0.2.0
#   PRAVARTAK_SRC=/path/to/pravartak-lib bash install.sh      # offline: copy from a checkout
#
# Environment:
#   PRAVARTAK_VERSION   version to install (default: latest). Overridden by the first arg.
#   PRAVARTAK_BASE_URL  release host (default: https://pravartak.vesta-platform.dev).
#   PRAVARTAK_SRC       path to a local pravartak library checkout; if set, copy from it
#                       instead of downloading (for offline use and testing).
#   PRAVARTAK_FORCE     set to 1 to overwrite an existing pravartak/ in the current directory.

set -euo pipefail

VERSION="${1:-${PRAVARTAK_VERSION:-latest}}"
BASE_URL="${PRAVARTAK_BASE_URL:-https://pravartak.vesta-platform.dev}"
DEST="$PWD"
LIB="pravartak"

die() { printf 'pravartak install: %s\n' "$1" >&2; exit 1; }

# Refuse to clobber an existing install unless explicitly forced.
if [ -e "$DEST/$LIB" ] && [ "${PRAVARTAK_FORCE:-0}" != "1" ]; then
  die "$DEST/$LIB already exists. Use /pravartak-upgrade to change versions, or set PRAVARTAK_FORCE=1 to overwrite."
fi

# Copy the pravartak/ subdirectory out of a source tree into the destination.
install_from_dir() {
  local src="$1"
  [ -d "$src/$LIB" ] || die "no $LIB/ directory found in $src"
  rm -rf "${DEST:?}/$LIB"
  cp -R "$src/$LIB" "$DEST/$LIB"
}

if [ -n "${PRAVARTAK_SRC:-}" ]; then
  # Offline / test mode: copy from a local checkout.
  printf 'pravartak install: copying from local source %s\n' "$PRAVARTAK_SRC"
  install_from_dir "$PRAVARTAK_SRC"
else
  # Download + extract the release archive, then copy pravartak/ out of it.
  command -v tar >/dev/null 2>&1 || die "tar is required"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  archive="$tmp/pravartak.tar.gz"
  url="$BASE_URL/releases/$VERSION.tar.gz"
  printf 'pravartak install: downloading %s\n' "$url"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$archive" || die "download failed: $url"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$archive" "$url" || die "download failed: $url"
  else
    die "need curl or wget to download (or set PRAVARTAK_SRC for a local install)"
  fi
  tar -xzf "$archive" -C "$tmp" || die "extract failed"
  # The archive may contain pravartak/ at its root, or nested one level under a top dir
  # (e.g. pravartak-0.2.0/pravartak/). Locate the pravartak/ directory either way.
  srcdir=""
  if [ -d "$tmp/$LIB" ]; then
    srcdir="$tmp"
  else
    for d in "$tmp"/*/; do
      [ -d "$d$LIB" ] && { srcdir="${d%/}"; break; }
    done
  fi
  [ -n "$srcdir" ] || die "could not locate $LIB/ in the downloaded archive"
  install_from_dir "$srcdir"
fi

# Make the Claude adapter's /scaffold available before .claude/commands/ exists
# (bootstrap; see commands/scaffold.md). Other runtimes invoke the scaffold skill directly.
if [ -f "$DEST/$LIB/commands/scaffold.md" ]; then
  mkdir -p "$DEST/.claude/commands"
  cp "$DEST/$LIB/commands/scaffold.md" "$DEST/.claude/commands/scaffold.md"
fi

ver="$(cat "$DEST/$LIB/VERSION" 2>/dev/null || printf '%s' "$VERSION")"
cat <<EOF

Pravartak installed (${ver}) into ${DEST}/${LIB}

Next steps:
  1. Choose an interactive runtime for scaffold:
       Claude: run /scaffold
       Codex/other: read pravartak/skills/scaffold/SKILL.md and execute it
  2. After scaffold, begin architect review with the assigned review runtime.
  3. Do not launch autonomous execution until architect review is complete.

The library lives in ${LIB}/ (versioned — do not edit). Upgrade later with /pravartak-upgrade.
EOF
