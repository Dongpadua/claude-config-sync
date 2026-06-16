#!/bin/bash
# Shell wrapper for upload-draft.py
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python "$SCRIPT_DIR/upload-draft.py" "$@"
