#!/bin/bash
# Setup Git hooks for unicefData repository
# Run once after cloning: ./scripts/setup-hooks.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_SRC="$SCRIPT_DIR/git-hooks"
HOOKS_DST="$REPO_ROOT/.git/hooks"

echo "Installing Git hooks..."

if [ -d "$HOOKS_SRC" ]; then
    cp "$HOOKS_SRC/post-checkout" "$HOOKS_DST/post-checkout"
    cp "$HOOKS_SRC/post-checkout" "$HOOKS_DST/post-merge"
    chmod +x "$HOOKS_DST/post-checkout" "$HOOKS_DST/post-merge"
    echo "Installed: post-checkout, post-merge"
else
    echo "ERROR: $HOOKS_SRC not found"
    exit 1
fi

echo "Running initial fixture unpack..."
cd "$REPO_ROOT"
"$HOOKS_DST/post-checkout"

echo "Done!"
