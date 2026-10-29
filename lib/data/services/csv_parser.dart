import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import '../models/cognitive_task.dart';

/// Service to parse and manage cognitive reset tasks from CSV
class CsvParserService {
  static const String _csvAssetPath = 'assets/cognitive_reset_tracker.csv';

  /// Parse the CSV asset file and return a list of CognitiveTask objects
  static Future<List<CognitiveTask>> parseCognitiveTasks() async {
    try {
      final csvString = await rootBundle.loadString(_csvAssetPath);
      return _parseCsvString(csvString);
    } catch (e, stack) {
      debugPrint('Cognitive CSV parse failed: $e\n$stack');
      rethrow;
    }
  }

  /// Parse CSV string into list of CognitiveTask objects.
  ///
  /// csv 6 defaults to CRLF. This asset uses LF, so the default converter
  /// keeps every task on one row and the name list stays empty.
  static List<CognitiveTask> _parseCsvString(String csvString) {
    final normalized = csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final List<List<dynamic>> rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(normalized);
    if (rows.length < 2) return [];

    // First row is header
    final headers = rows[0].map((e) => e.toString().trim()).toList();
    final tasks = <CognitiveTask>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < headers.length) continue;

      final task = _parseRow(headers, row);
      if (task != null) {
        tasks.add(task);
      }
    }

    return tasks;
  }

  /// Parse a single row into a CognitiveTask
  static CognitiveTask? _parseRow(List<String> headers, List<dynamic> row) {
    try {
      final section = _getValue(headers, row, 'Time / Section');
      final taskName = _getValue(headers, row, 'Daily Habit / Task');
      final goal = _getValue(headers, row, 'Goal / Focus');

      if (section.isEmpty || taskName.isEmpty) return null;

      // Parse days of week columns
      final daysOfWeek = <String, bool>{};
      final dayColumns = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (final day in dayColumns) {
        final value = _getValue(headers, row, day).trim().toLowerCase();
        daysOfWeek[day] = value.isNotEmpty && value != 'false' && value != '0';
      }

      // Generate unique ID from task name
      final id = taskName
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '_')
          .replaceAll(RegExp(r'_+'), '_');

      return CognitiveTask(
        id: id,
        section: section,
        task: taskName,
        goal: goal,
        daysOfWeek: daysOfWeek,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  static String _getValue(List<String> headers, List<dynamic> row, String header) {
    final index = headers.indexOf(header);
    if (index >= 0 && index < row.length) {
      return row[index]?.toString().trim() ?? '';
    }
    return '';
  }

  /// Check if a task is scheduled for today
  static bool isTaskForToday(CognitiveTask task, DateTime date) {
    final dayAbbr = date.dayAbbreviation;
    return task.daysOfWeek[dayAbbr] == true;
  }

  /// Get tasks scheduled for a specific date
  static List<CognitiveTask> getTasksForDate(List<CognitiveTask> tasks, DateTime date) {
    return tasks.where((task) => isTaskForToday(task, date)).toList();
  }

  /// Get tasks grouped by section for a specific date
  static Map<CognitiveSection, List<CognitiveTask>> getTasksGroupedBySection(
    List<CognitiveTask> tasks,
    DateTime date,
  ) {
    final tasksForDate = getTasksForDate(tasks, date);
    final grouped = <CognitiveSection, List<CognitiveTask>>{};

    for (final task in tasksForDate) {
      final section = CognitiveSection.fromString(task.section);
      grouped.putIfAbsent(section, () => []).add(task);
    }

    return grouped;
  }

  /// Calculate completion stats for a date
  static Map<String, dynamic> calculateCompletionStats(
    List<CognitiveTask> tasks,
    DateTime date,
  ) {
    final tasksForDate = getTasksForDate(tasks, date);
    if (tasksForDate.isEmpty) {
      return {
        'total': 0,
        'completed': 0,
        'percentage': 0.0,
        'bySection': <String, Map<String, int>>{},
      };
    }

    int completed = 0;
    final bySection = <String, Map<String, int>>{};

    for (final task in tasksForDate) {
      final section = task.section;
      bySection.putIfAbsent(section, () => {'total': 0, 'completed': 0});
      bySection[section]!['total'] = bySection[section]!['total']! + 1;
      if (task.isCompletedToday) {
        completed++;
        bySection[section]!['completed'] = bySection[section]!['completed']! + 1;
      }
    }

    return {
      'total': tasksForDate.length,
      'completed': completed,
      'percentage': tasksForDate.isEmpty ? 0.0 : (completed / tasksForDate.length) * 100,
      'bySection': bySection,
    };
  }
}