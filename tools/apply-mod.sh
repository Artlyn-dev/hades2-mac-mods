#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/paths.sh"
export HADES2_SCRIPTS="$HADES2_CONTENT/Scripts"
python3 "$(dirname "$0")/apply-mod.py" "$@"
