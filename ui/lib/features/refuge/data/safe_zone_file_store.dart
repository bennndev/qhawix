import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/safe_zone_config.dart';
import '../domain/safe_zone_engine.dart';
import '../domain/safe_zone_status.dart';
import 'safe_zone_mapper.dart';

/// Plain-file persistence shared by the UI isolate and background isolates.
///
/// A file is used instead of SharedPreferences because each isolate keeps its
/// own preferences cache; a flushed file write is visible to every isolate.
class SafeZoneFileStore {
  SafeZoneFileStore({Future<Directory> Function()? supportDirectory})
    : _supportDirectory =
          supportDirectory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _supportDirectory;

  static const configFile = 'safe_zone_config.json';
  static const runtimeFile = 'safe_zone_runtime.json';
  static const eventsFile = 'safe_zone_events.jsonl';
  static const maxEvents = 50;

  Future<File> _file(String name) async {
    final dir = await _supportDirectory();
    return File('${dir.path}/$name');
  }

  Future<Map<String, Object?>> _readMap(String name) async {
    final file = await _file(name);
    if (!await file.exists()) return {};
    try {
      return (jsonDecode(await file.readAsString()) as Map).cast<String, Object?>();
    } on Object {
      return {};
    }
  }

  Future<void> _writeMap(String name, Map<String, Object?> data) async {
    final file = await _file(name);
    await file.writeAsString(jsonEncode(data), flush: true);
  }

  Future<SafeZoneConfig?> loadConfig() async {
    final map = await _readMap(configFile);
    if (map.isEmpty) return null;
    return SafeZoneMapper.configFromWire(map);
  }

  Future<void> saveConfig(SafeZoneConfig config) async {
    await _writeMap(configFile, SafeZoneMapper.configToWire(config));
  }

  Future<SafeZoneRuntimeState> loadRuntime() async {
    final m = await _readMap(runtimeFile);
    return SafeZoneRuntimeState(
      awaySinceMillis: (m['awaySinceMillis'] as num?)?.toInt(),
      alertedThisEpisode: m['alertedThisEpisode'] as bool? ?? false,
      sentTodayEpisodes: (m['sentTodayEpisodes'] as num?)?.toInt() ?? 0,
      sentTodayLocalDate: m['sentTodayLocalDate'] as String? ?? '',
      countdownActive: m['countdownActive'] as bool? ?? false,
      countdownCancelled: m['countdownCancelled'] as bool? ?? false,
      autoStartConfirmed: m['autoStartConfirmed'] as bool? ?? false,
    );
  }

  Future<void> saveRuntime(SafeZoneRuntimeState state) async {
    await _writeMap(runtimeFile, {
      'awaySinceMillis': state.awaySinceMillis,
      'alertedThisEpisode': state.alertedThisEpisode,
      'sentTodayEpisodes': state.sentTodayEpisodes,
      'sentTodayLocalDate': state.sentTodayLocalDate,
      'countdownActive': state.countdownActive,
      'countdownCancelled': state.countdownCancelled,
      'autoStartConfirmed': state.autoStartConfirmed,
    });
  }

  Future<void> appendEvent(SafeZoneEvent event) async {
    final file = await _file(eventsFile);
    final line = jsonEncode(SafeZoneMapper.eventToWire(event));
    await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
    final lines = await file.readAsLines();
    if (lines.length > maxEvents) {
      final kept = lines.sublist(lines.length - maxEvents);
      await file.writeAsString('${kept.join('\n')}\n', flush: true);
    }
  }

  Future<List<SafeZoneEvent>> loadEvents() async {
    final file = await _file(eventsFile);
    if (!await file.exists()) return const [];
    final out = <SafeZoneEvent>[];
    for (final line in await file.readAsLines()) {
      if (line.trim().isEmpty) continue;
      try {
        out.add(
          SafeZoneMapper.eventFromWire(
            (jsonDecode(line) as Map).cast<String, Object?>(),
          ),
        );
      } on Object {
        // Skip corrupt lines.
      }
    }
    return out;
  }

  Future<SafeZoneEvent?> lastEvent() async {
    final events = await loadEvents();
    return events.isEmpty ? null : events.last;
  }
}
