#!/usr/bin/env bash

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: ./Scripts/Deploy.sh \"commit message\"" >&2
  exit 64
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="$PROJECT_ROOT/.build/DerivedData/Build/Products/Release/Tweaker.app"
COMMIT_MESSAGE="$*"

cd "$PROJECT_ROOT"

if [[ ! -d .git ]]; then
  echo "Git repository is not initialized." >&2
  exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "Built application not found. Run ./Scripts/Build.sh first." >&2
  exit 1
fi

pkill -x ExtremeMacTweaker >/dev/null 2>&1 || true
pkill -x Tweaker >/dev/null 2>&1 || true
open -na "$APP_PATH"

git add -A

if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "$COMMIT_MESSAGE"
fi

current_branch="$(git branch --show-current)"
if [[ -z "$current_branch" ]]; then
  echo "Cannot deploy from a detached HEAD." >&2
  exit 1
fi

git push --set-upstream origin "$current_branch"
echo "complete"
