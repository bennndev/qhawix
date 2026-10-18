import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path_provider/path_provider.dart';

/// Plain-file persistence shared by the UI isolate and background isolates.
/// A file is used instead of shared_preferences because each isolate keeps its
/// own SharedPreferences cache; a file append is visible to all of them at once.
class SpikeStore {
  static Future<File> _file(String name) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$name');
  }

  static String get isolateName => Isolate.current.debugName ?? 'unnamed';

  static Future<void> log(String event) async {
    final f = await _file('spike_log.txt');
    final line = '${DateTime.now().toIso8601String()}|$isolateName|'
        '${event.replaceAll('\n', ' ')}\n';
    await f.writeAsString(line, mode: FileMode.append, flush: true);
  }

  static Future<List<String>> readLog() async {
    final f = await _file('spike_log.txt');
    if (!await f.exists()) return [];
    return (await f.readAsLines()).reversed.toList();
  }

  static Future<void> clearLog() async {
    final f = await _file('spike_log.txt');
    if (await f.exists()) await f.delete();
  }

  static Future<Map<String, dynamic>> readJson(String name) async {
    final f = await _file(name);
    if (!await f.exists()) return {};
    try {
      return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static Future<void> writeJson(String name, Map<String, dynamic> data) async {
    final f = await _file(name);
    await f.writeAsString(jsonEncode(data), flush: true);
  }

  static Future<void> delete(String name) async {
    final f = await _file(name);
    if (await f.exists()) await f.delete();
  }
}
