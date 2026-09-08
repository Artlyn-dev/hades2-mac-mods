#!/usr/bin/env bash
set -euo pipefail

# Copy vanilla Scripts + Game out of the .app so we can restore without reinstalling.

source "$(dirname "$0")/paths.sh"

if [[ ! -d "$HADES2_CONTENT/Scripts" ]]; then
  echo "Game Content not found: $HADES2_CONTENT" >&2
  exit 1
fi

mkdir -p "$BACKUP_ROOT"

rsync -a --delete "$HADES2_CONTENT/Scripts/" "$BACKUP_ROOT/Scripts/"
rsync -a --delete "$HADES2_CONTENT/Game/" "$BACKUP_ROOT/Game/"

{
  echo "source=$HADES2_CONTENT"
  echo "backed_up_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "scripts_files=$(find "$BACKUP_ROOT/Scripts" -type f | wc -l | tr -d ' ')"
  echo "game_files=$(find "$BACKUP_ROOT/Game" -type f | wc -l | tr -d ' ')"
  if [[ -f "$HADES2_CONTENT/packagever" ]]; then
    echo "packagever=$(cat "$HADES2_CONTENT/packagever")"
  fi
} > "$BACKUP_ROOT/MANIFEST.txt"

echo "Backup written to $BACKUP_ROOT"
cat "$BACKUP_ROOT/MANIFEST.txt"
