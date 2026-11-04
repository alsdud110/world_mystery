import 'dart:convert';
import 'dart:io';

import '../season_gen/history_dossier.dart';

/// The history gate for generators this repository does not run itself: a
/// sound from ElevenLabs (the `sound-effects` skill: Python, JavaScript or
/// its CLI), a picture from the image API called by hand. A file of a
/// historical season is made only once its facts are approved as they are
/// (`HistoryGate.forOutput`); any other file (a standard season's, a test,
/// anything else) is never stopped.
///
///     dart run tool/ai_agents/history_guard.dart <outputPath>...   # before making those files
///     dart run tool/ai_agents/history_guard.dart --hook            # a Claude Code PreToolUse hook (stdin)
///
/// `--hook` reads the hook's JSON, and for a Bash command that calls one of
/// those APIs ([apiCall]) checks every path it names. Run by
/// `history_guard_hook.sh` (`.claude/settings.json`), which lets every other
/// command through without starting Dart.
///
/// Exit codes: 0 nothing stands in the way; 2 stopped (the reason on
/// stderr: a hook's exit 2 stops the tool call before it runs); 64 usage.
Future<void> main(List<String> args) async {
  final root = Platform.environment['CLAUDE_PROJECT_DIR'] ?? '.';
  final List<String> blockers;
  if (args.length == 1 && args.single == '--hook') {
    final Object? json;
    try {
      json = jsonDecode(await stdin.transform(utf8.decoder).join());
    } on FormatException {
      stderr.writeln('history guard: the hook input is not JSON');
      exit(2);
    }
    final command = json is Map && json['tool_input'] is Map ? (json['tool_input'] as Map)['command'] : null;
    blockers = command is String ? HistoryGuard.command(command, root) : const [];
  } else if (args.isNotEmpty && !args.any((a) => a.startsWith('--'))) {
    blockers = [for (final a in args) ...HistoryGate.forOutput(root, a)];
  } else {
    stderr.writeln('usage: dart run tool/ai_agents/history_guard.dart <outputPath>... | --hook');
    exit(64);
  }
  if (blockers.isEmpty) exit(0);
  stderr.writeln('history guard: a file of a historical season whose facts are not approved as they are; nothing sent');
  for (final b in blockers) {
    stderr.writeln('  $b');
  }
  stderr.writeln('fix its history dossier first (planning/history_dossier.json) until its checks pass');
  exit(2);
}

abstract final class HistoryGuard {
  /// A call to a paid generator outside the repository's own tools.
  static final apiCall = RegExp(r'elevenlabs|text[-_]to[-_]sound|sound[-_]effects|api\.openai\.com/v1/images|images\.(generate|edit)\b', caseSensitive: false);

  static final _paths = [
    RegExp(r'(?:\./)?(?:assets|content_pipeline)/[A-Za-z0-9_./-]+'),
    RegExp(r'[A-Za-z0-9_./-]+\.(?:mp3|wav|ogg|m4a|aac|flac|opus|png|webp|jpe?g)\b', caseSensitive: false),
  ];

  /// What stops [command] (a shell command) from [root]: nothing unless it
  /// calls a paid generator ([apiCall]) and names a file of a historical
  /// season whose gate is shut.
  static List<String> command(String command, String root) {
    if (!apiCall.hasMatch(command)) return const [];
    final paths = {for (final p in _paths) ...p.allMatches(command).map((m) => m[0]!)};
    return {for (final p in paths) ...HistoryGate.forOutput(root, p)}.toList();
  }
}
