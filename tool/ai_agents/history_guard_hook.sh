#!/bin/sh
# Claude Code PreToolUse hook (Bash): a command calling a paid sound or image
# generator outside this repository's tools goes to history_guard.dart, which
# stops it (exit 2) when it would make a file of a historical season whose
# facts are not approved. Every other command passes without starting Dart.
input=$(cat)
printf '%s' "$input" | grep -qiE 'elevenlabs|text[-_]to[-_]sound|sound[-_]effects|api\.openai\.com/v1/images|images\.(generate|edit)' || exit 0
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 2
printf '%s' "$input" | dart run tool/ai_agents/history_guard.dart --hook
code=$?
# A guard that could not run stops the call it was asked about.
[ "$code" -eq 0 ] && exit 0
exit 2
