import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/cognitive_completion_store.dart';
import '../data/services/csv_parser.dart';
import '../data/models/cognitive_task.dart';
import '../data/services/notification_service.dart';

/// Provider for all cognitive tasks from CSV
final cognitiveTasksProvider = FutureProvider<List<CognitiveTask>>((ref) async {
  return CsvParserService.parseCognitiveTasks();
});

/// Provider for today's cognitive tasks
final todaysCognitiveTasksProvider = Provider<List<CognitiveTask>>((ref) {
  final tasksAsync = ref.watch(cognitiveTasksProvider);
  final today = DateTime.now();
  
  return tasksAsync.maybeWhen(
    data: (tasks) => CsvParserService.getTasksForDate(tasks, today),
    orElse: () => [],
  );
});

/// Provider for today's tasks grouped by section
final todaysCognitiveTasksGroupedProvider = Provider<Map<CognitiveSection, List<CognitiveTask>>>((ref) {
  final tasksAsync = ref.watch(cognitiveTasksProvider);
  final today = DateTime.now();
  
  return tasksAsync.maybeWhen(
    data: (tasks) => CsvParserService.getTasksGroupedBySection(tasks, today),
    orElse: () => {},
  );
});

/// Provider for today's completion stats
final todaysCognitiveStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final tasksAsync = ref.watch(cognitiveTasksProvider);
  final today = DateTime.now();
  
  return tasksAsync.maybeWhen(
    data: (tasks) => CsvParserService.calculateCompletionStats(tasks, today),
    orElse: () => {
      'total': 0,
      'completed': 0,
      'percentage': 0.0,
      'bySection': <String, Map<String, int>>{},
    },
  );
});

/// Provider for scheduling task notifications
final taskNotificationSchedulerProvider = Provider<TaskNotificationScheduler>((ref) {
  return TaskNotificationScheduler(ref);
});

/// Service to schedule one notification per task
class TaskNotificationScheduler {
  final Ref _ref;
  final NotificationService _notificationService = NotificationService();

  TaskNotificationScheduler(this._ref);

  static Future<void>? _inFlight;

  /// Schedule notifications for all tasks due today
  Future<void> scheduleTodaysTaskNotifications() async {
    if (_inFlight != null) return _inFlight!;
    final operation = _scheduleAll();
    _inFlight = operation;
    try { await operation; } finally { _inFlight = null; }
  }

  Future<void> _scheduleAll() async {
    final tasks = await _ref.read(cognitiveTasksProvider.future);
    await _notificationService.refreshTimeZone();
    final desiredIds = <int>{};

    // Schedule one notification per task. The offset is how far into that
    // part of the day this task sits, so a 10-minute task is not followed
    // two minutes later.
    final seenInSection = <String, int>{};
    for (var taskIndex = 0; taskIndex < tasks.length; taskIndex++) {
      final task = tasks[taskIndex];
      final indexInSection = seenInSection[task.section] ?? 0;
      seenInSection[task.section] = indexInSection + 1;
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final daily = days.every((day) => task.daysOfWeek[day] == true);
      for (var weekday = 1; weekday <= 7; weekday++) {
        if (!daily && task.daysOfWeek[days[weekday - 1]] != true) continue;
        final id = 20000 + taskIndex * 7 + weekday - 1;
        desiredIds.add(id);
        await _scheduleTaskNotification(task, indexInSection, id, daily ? null : weekday);
        if (daily) break;
      }
    }
    // Replace first, then remove obsolete alarms so a failed update retains reminders.
    final pending = await _notificationService.getPendingNotifications();
    for (final request in pending) {
      if ((request.payload?.startsWith('cognitive_reset_task_') == true ||
          (request.id >= 2000 && request.id < 3000)) && !desiredIds.contains(request.id)) {
        await _notificationService.cancel(request.id);
      }
    }
  }

  /// Schedule a single task notification at the appropriate time
  Future<void> _scheduleTaskNotification(CognitiveTask task, int indexInSection, int notificationId, int? weekday) async {
    final sectionTime = _getSectionTime(task.section);
    final offsets = _offsetsFor(task.section);
    final extraMinutes = indexInSection < offsets.length
        ? offsets[indexInSection]
        : offsets.last + (indexInSection - offsets.length + 1) * 60;
    final totalMinutes = sectionTime.hour * 60 + sectionTime.minute + extraMinutes;
    final hour = (totalMinutes ~/ 60) % 24;
    final minute = totalMinutes % 60;

    await _notificationService.scheduleTaskReminder(
      id: notificationId,
      hour: hour,
      minute: minute,
      task: task,
      weekday: weekday == null ? null : (weekday - 1 + totalMinutes ~/ 1440) % 7 + 1,
    );
  }

  /// Minutes after the section start for each task, in CSV order.
  /// Morning buffer is 30–60 minutes, the think block is 10, the focus
  /// block is 25, and reading aloud is 15, so the next reminder waits
  /// until that work can actually be finished. The screen curfew is later.
  List<int> _offsetsFor(String section) {
    switch (section) {
      case 'Morning (Awakening & Protection)':
        return [0, 60];
      case 'Afternoon (Mindful Work & AI)':
        return [0, 45];
      case 'Evening (Speech & Dopamine Fast)':
        return [0, 60, 150];
      default:
        return [0, 60, 120];
    }
  }

  /// Get the base time for a section
  _SectionTime _getSectionTime(String section) {
    switch (section) {
      case 'Morning (Awakening & Protection)':
        return _SectionTime(hour: 7, minute: 0); // 7:00 AM
      case 'Afternoon (Mindful Work & AI)':
        return _SectionTime(hour: 13, minute: 0); // 1:00 PM
      case 'Evening (Speech & Dopamine Fast)':
        return _SectionTime(hour: 19, minute: 0); // 7:00 PM
      default:
        return _SectionTime(hour: 9, minute: 0);
    }
  }

  /// Reschedule all notifications (call when tasks change or daily)
  Future<void> rescheduleAll() async {
    await scheduleTodaysTaskNotifications();
  }
}

class _SectionTime {
  final int hour;
  final int minute;
  _SectionTime({required this.hour, required this.minute});
}

/// Notifier for managing task completion state locally
class CognitiveTaskNotifier extends AsyncNotifier<Map<String, bool>> {
  @override
  Future<Map<String, bool>> build() async {
    final saved = await CognitiveCompletionStore.read();
    final ids = saved[CognitiveCompletionStore.todayKey()] ?? const [];
    return {for (final id in ids) id: true};
  }

  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    final currentState = state.value ?? {};
    final newState = Map<String, bool>.from(currentState);
    newState[taskId] = isCompleted;
    await _persist(newState);
    state = AsyncData(newState);
  }

  Future<void> markAllCompleted(List<CognitiveTask> tasks) async {
    final currentState = state.value ?? {};
    final newState = Map<String, bool>.from(currentState);
    for (final task in tasks) {
      newState[task.id] = true;
    }
    await _persist(newState);
    state = AsyncData(newState);
  }

  Future<void> resetToday() async {
    await _persist(const {});
    state = const AsyncData({});
  }

  Future<void> _persist(Map<String, bool> completions) {
    final done = completions.entries.where((entry) => entry.value).map((entry) => entry.key);
    return CognitiveCompletionStore.writeDay(CognitiveCompletionStore.todayKey(), done);
  }
}

/// Completed task ids for every saved day. Refreshes when today changes.
final cognitiveCompletionLogProvider = FutureProvider<Map<String, List<String>>>((ref) async {
  ref.watch(cognitiveTaskCompletionProvider);
  return CognitiveCompletionStore.read();
});

final cognitiveTaskCompletionProvider = 
    AsyncNotifierProvider<CognitiveTaskNotifier, Map<String, bool>>(CognitiveTaskNotifier.new);
