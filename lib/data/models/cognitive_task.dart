import 'package:freezed_annotation/freezed_annotation.dart';

part 'cognitive_task.freezed.dart';
part 'cognitive_task.g.dart';

/// Model for a cognitive reset task/habit from the CSV
@freezed
class CognitiveTask with _$CognitiveTask {
  const factory CognitiveTask({
    required String id,
    required String section,
    required String task,
    required String goal,
    required Map<String, bool> daysOfWeek, // Mon, Tue, Wed, etc.
    required DateTime createdAt,
    DateTime? completedAt,
    @Default(false) bool isCompletedToday,
  }) = _CognitiveTask;

  factory CognitiveTask.fromJson(Map<String, dynamic> json) =>
      _$CognitiveTaskFromJson(json);
}

/// Section groupings for tasks
enum CognitiveSection {
  morning('Morning (Awakening & Protection)'),
  afternoon('Afternoon (Mindful Work & AI)'),
  evening('Evening (Speech & Dopamine Fast)');

  const CognitiveSection(this.displayName);
  final String displayName;

  static CognitiveSection fromString(String value) {
    return CognitiveSection.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => CognitiveSection.morning,
    );
  }
}

/// Extension for getting today's day abbreviation
extension DayOfWeekExtension on DateTime {
  String get dayAbbreviation {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  bool get isWeekday => weekday >= 1 && weekday <= 5;
  bool get isWeekend => weekday >= 6 && weekday <= 7;
}