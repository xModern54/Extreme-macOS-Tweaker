#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_CATALOG="$PROJECT_ROOT/ExtremeMacTweaker/Resources/TweakCatalog.json"
EXTERNAL_DIRECTORY="$HOME/Library/Application Support/Tweaker"
EXTERNAL_CATALOG="$EXTERNAL_DIRECTORY/TweakCatalog.json"

case "${1:-}" in
  install|sync)
    mkdir -p "$EXTERNAL_DIRECTORY"
    /usr/bin/ditto "$SOURCE_CATALOG" "$EXTERNAL_CATALOG"
    echo "$EXTERNAL_CATALOG"
    ;;
  path)
    echo "$EXTERNAL_CATALOG"
    ;;
  validate)
    if command -v jq >/dev/null 2>&1; then
      jq empty "$SOURCE_CATALOG"
    elif command -v python3 >/dev/null 2>&1; then
      python3 -m json.tool "$SOURCE_CATALOG" >/dev/null
    else
      echo "Catalog validation requires jq or python3." >&2
      exit 69
    fi
    echo "complete"
    ;;
  *)
    echo "Usage: ./Catalog.sh {install|sync|path|validate}" >&2
    exit 64
    ;;
esac
