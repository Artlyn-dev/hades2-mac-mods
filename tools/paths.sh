# Shared paths for Hades II (native macOS Steam).
# shellcheck shell=bash

HADES2_APP="${HADES2_APP:-$HOME/Library/Application Support/Steam/steamapps/common/Hades II/Hades II.app}"
HADES2_CONTENT="${HADES2_CONTENT:-$HADES2_APP/Contents/Resources/Content}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_ROOT="${HADES2_BACKUP_ROOT:-$REPO_ROOT/vanilla-backup}"
