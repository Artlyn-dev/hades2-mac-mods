#!/usr/bin/env bash
set -euo pipefail

# Restore Scripts + Game from vanilla-backup into the Steam install.

source "$(dirname "$0")/paths.sh"

if [[ ! -d "$BACKUP_ROOT/Scripts" || ! -d "$BACKUP_ROOT/Game" ]]; then
  echo "No backup at $BACKUP_ROOT. Run tools/backup-vanilla.sh first." >&2
  exit 1
fi

if [[ ! -d "$HADES2_CONTENT" ]]; then
  echo "Game Content not found: $HADES2_CONTENT" >&2
  exit 1
fi

rsync -a --delete "$BACKUP_ROOT/Scripts/" "$HADES2_CONTENT/Scripts/"
rsync -a --delete "$BACKUP_ROOT/Game/" "$HADES2_CONTENT/Game/"

echo "Restored Scripts and Game into:"
echo "  $HADES2_CONTENT"
echo "If that fails (permissions / Steam verify), use Steam → Hades II → Properties → Installed Files → Verify integrity."
