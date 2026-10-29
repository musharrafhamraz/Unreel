import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Completed cognitive-reset task ids, keyed by calendar day (yyyy-MM-dd).
class CognitiveCompletionStore {
  static Future<void> _tail = Future.value();

  static String dayKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String todayKey() => dayKey(DateTime.now());

  static Future<Map<String, List<String>>> read() async {
    final file = await _file();
    if (!await file.exists()) return {};
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return {};
      return decoded.map((key, value) {
        final ids = value is List ? value.map((e) => e.toString()).toList() : <String>[];
        return MapEntry(key.toString(), ids);
      });
    } catch (_) {
      return {};
    }
  }

  static Future<void> writeDay(String day, Iterable<String> completedIds) {
    final next = _tail.then((_) => _writeDay(day, completedIds.toList()));
    _tail = next.catchError((_) {});
    return next;
  }

  static Future<void> _writeDay(String day, List<String> completedIds) async {
    final all = await read();
    if (completedIds.isEmpty) {
      all.remove(day);
    } else {
      all[day] = completedIds;
    }
    final file = await _file();
    await file.writeAsString(jsonEncode(all));
  }

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/cognitive_completions.json');
  }
}
