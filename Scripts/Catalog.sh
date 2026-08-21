#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESOURCES="$PROJECT_ROOT/ExtremeMacTweaker/Resources"
SOURCE_CATALOG="$RESOURCES/TweakCatalog.json"
SOURCE_CATALOG_27="$RESOURCES/TweakCatalog.27.json"
EXTERNAL_DIRECTORY="$HOME/Library/Application Support/Tweaker"
EXTERNAL_CATALOG="$EXTERNAL_DIRECTORY/TweakCatalog.json"
EXTERNAL_CATALOG_27="$EXTERNAL_DIRECTORY/TweakCatalog.27.json"

validate_json() {
  local file="$1"
  if command -v jq >/dev/null 2>&1; then
    jq empty "$file"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool "$file" >/dev/null
  else
    echo "Catalog validation requires jq or python3." >&2
    exit 69
  fi
}

case "${1:-}" in
  install|sync)
    mkdir -p "$EXTERNAL_DIRECTORY"
    /usr/bin/ditto "$SOURCE_CATALOG" "$EXTERNAL_CATALOG"
    /usr/bin/ditto "$SOURCE_CATALOG_27" "$EXTERNAL_CATALOG_27"
    echo "$EXTERNAL_CATALOG"
    echo "$EXTERNAL_CATALOG_27"
    ;;
  path)
    echo "$EXTERNAL_CATALOG"
    echo "$EXTERNAL_CATALOG_27"
    ;;
  validate)
    validate_json "$SOURCE_CATALOG"
    validate_json "$SOURCE_CATALOG_27"
    echo "complete"
    ;;
  *)
    echo "Usage: ./Scripts/Catalog.sh {install|sync|path|validate}" >&2
    exit 64
    ;;
esac
