#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHRASE_FILE="${SCRIPT_DIR}/TWPhrases.txt"

usage() {
  cat <<'EOF'
Usage:
  ./tw-add.sh <source> [replacement]

Examples:
  ./tw-add.sh 臺灣
  ./tw-add.sh 臺灣 台灣

With only <source>, the script will try to ask `codex exec` for a suggested
Taiwan-usage replacement, then ask you to confirm or edit before appending.
EOF
}

if [ "$#" -lt 1 ]; then
  usage
  exit 1
fi

if [ ! -f "$PHRASE_FILE" ]; then
  echo "Could not find ${PHRASE_FILE}" >&2
  exit 1
fi

source_phrase="$1"
replacement="${2:-}"

if grep -Fq "^${source_phrase}\t" "$PHRASE_FILE"; then
  echo "Entry for '${source_phrase}' already exists in ${PHRASE_FILE}" >&2
  exit 1
fi

if [ -z "$replacement" ]; then
  suggestion=""
  if command -v codex >/dev/null 2>&1; then
    echo "Asking codex for a Taiwan-usage replacement..."
    suggestion="$(codex exec "Given the Traditional Chinese phrase '${source_phrase}', return the common Taiwan usage replacement as one plain line, no quotes or punctuation.")" || true
    suggestion="$(printf '%s\n' "$suggestion" | head -n1 | tr -d '\r')"
  fi

  if [ -n "$suggestion" ]; then
    read -r -p "Use suggestion '${suggestion}' for '${source_phrase}'? [Y/n/edit] " reply
    reply="${reply:-y}"
    case "$reply" in
      [Yy]*) replacement="$suggestion" ;;
      [Ee]*) read -r -p "Enter replacement: " replacement ;;
      *) echo "Aborted."; exit 1 ;;
    esac
  fi

  if [ -z "$replacement" ]; then
    read -r -p "Enter replacement for '${source_phrase}': " replacement
  fi
fi

if [ -z "$replacement" ]; then
  echo "No replacement provided; nothing to append." >&2
  exit 1
fi

printf '%s\t%s\n' "$source_phrase" "$replacement" >> "$PHRASE_FILE"
echo "Appended to ${PHRASE_FILE}: ${source_phrase} -> ${replacement}"
