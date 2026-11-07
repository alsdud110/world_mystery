#!/bin/sh
# Brings every worktree up to origin/main after a push. Fast-forward only:
# one with its own commits or conflicting edits is left alone and reported.
git fetch -q origin main || { echo "sync: fetch failed"; exit 0; }
git worktree list --porcelain | sed -n 's/^worktree //p' | while IFS= read -r w; do
  if git -C "$w" merge -q --ff-only origin/main 2>/dev/null; then
    echo "sync: $w $(git -C "$w" rev-parse --short HEAD)"
  else
    echo "sync: SKIPPED $w"
  fi
done
