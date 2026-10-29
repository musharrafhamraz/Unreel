import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cognitive_task.dart';
import '../../data/services/csv_parser.dart';
import '../../providers/cognitive_tasks_provider.dart';
import '../utils/date_utils.dart' as app_date_utils;

/// A GitHub-style grid of Daily Cognitive Reset progress.
/// A day is empty when nothing was finished, and solid when every task was.
class ContributionGrid extends ConsumerWidget {
  const ContributionGrid({super.key});

  static const int _weeks = 16;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final tasksAsync = ref.watch(cognitiveTasksProvider);
    final logAsync = ref.watch(cognitiveCompletionLogProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: tasksAsync.when(
          data: (tasks) => logAsync.when(
            data: (log) => _grid(theme, colorScheme, todayDate, tasks, log),
            loading: () => _grid(theme, colorScheme, todayDate, tasks, const {}),
            error: (_, __) => _grid(theme, colorScheme, todayDate, tasks, const {}),
          ),
          loading: () => _grid(theme, colorScheme, todayDate, const [], const {}),
          error: (_, __) => _grid(theme, colorScheme, todayDate, const [], const {}),
        ),
      ),
    );
  }

  Widget _grid(
    ThemeData theme,
    ColorScheme colorScheme,
    DateTime todayDate,
    List<CognitiveTask> tasks,
    Map<String, List<String>> log,
  ) {
    final daysSinceSunday = todayDate.weekday % 7;
    final thisSunday = todayDate.subtract(Duration(days: daysSinceSunday));
    final startSunday = thisSunday.subtract(Duration(days: 7 * (_weeks - 1)));
    var finished = 0;
    var todayDone = 0;
    var todayDue = 0;
    for (var week = 0; week < _weeks; week++) {
      for (var weekday = 0; weekday < 7; weekday++) {
        final day = startSunday.add(Duration(days: week * 7 + weekday));
        if (day.isAfter(todayDate)) continue;
        final progress = _progress(day, tasks, log);
        finished += progress.done;
        if (_sameDay(day, todayDate)) {
          todayDone = progress.done;
          todayDue = progress.due;
        }
      }
    }

    const cell = 12.0;
    const gap = 3.0;
    final levels = _levels(colorScheme);
    final todayLabel = todayDue == 0 ? 'No tasks today' : '$todayDone of $todayDue tasks today';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          '$todayLabel · $finished finished in $_weeks weeks',
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    for (final label in const ['', 'M', '', 'W', '', 'F', ''])
                      SizedBox(
                        height: cell + gap,
                        width: 12,
                        child: Text(
                          label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 9,
                            height: 1.2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              for (var week = 0; week < _weeks; week++)
                Padding(
                  padding: const EdgeInsets.only(right: gap),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 16,
                        width: cell,
                        child: OverflowBox(
                          alignment: Alignment.centerLeft,
                          maxWidth: 36,
                          child: _monthLabel(theme, colorScheme, startSunday, week),
                        ),
                      ),
                      for (var weekday = 0; weekday < 7; weekday++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: gap),
                          child: _cell(
                            levels,
                            startSunday.add(Duration(days: week * 7 + weekday)),
                            todayDate,
                            tasks,
                            log,
                            cell,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('None', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(width: 6),
            for (final color in levels) ...[
              Container(
                width: cell,
                height: cell,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 3),
            ],
            Text('All done', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }

  _DayProgress _progress(DateTime day, List<CognitiveTask> tasks, Map<String, List<String>> log) {
    final due = CsvParserService.getTasksForDate(tasks, day);
    final doneIds = log[_dayKey(day)]?.toSet() ?? const {};
    final done = due.where((task) => doneIds.contains(task.id)).length;
    return _DayProgress(done, due.length);
  }

  Widget _monthLabel(ThemeData theme, ColorScheme colorScheme, DateTime startSunday, int week) {
    final day = startSunday.add(Duration(days: week * 7));
    final previous = week == 0 ? null : startSunday.add(Duration(days: (week - 1) * 7));
    if (previous != null && previous.month == day.month) return const SizedBox.shrink();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return Text(
      months[day.month - 1],
      style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 9),
    );
  }

  Widget _cell(
    List<Color> levels,
    DateTime day,
    DateTime todayDate,
    List<CognitiveTask> tasks,
    Map<String, List<String>> log,
    double size,
  ) {
    final future = day.isAfter(todayDate);
    final progress = future ? const _DayProgress(0, 0) : _progress(day, tasks, log);
    final color = future ? Colors.transparent : levels[_level(progress.done, progress.due)];
    final label = future
        ? ''
        : progress.due == 0
            ? '${app_date_utils.DateUtils.formatDay(_dayKey(day))}: no tasks'
            : '${app_date_utils.DateUtils.formatDay(_dayKey(day))}: ${progress.done} of ${progress.due} tasks';
    return Tooltip(
      message: label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  /// 0 is empty. Each further step is a more solid green, and finishing
  /// every task scheduled that day uses the strongest color.
  int _level(int done, int due) {
    if (done <= 0 || due <= 0) return 0;
    return (done / due * 4).ceil().clamp(1, 4);
  }

  List<Color> _levels(ColorScheme colorScheme) {
    final bright = colorScheme.brightness == Brightness.dark;
    if (bright) {
      return const [
        Color(0xFF2A3140),
        Color(0xFF0E4429),
        Color(0xFF006D32),
        Color(0xFF26A641),
        Color(0xFF39D353),
      ];
    }
    return const [
      Color(0xFFEBEDF0),
      Color(0xFF9BE9A8),
      Color(0xFF40C463),
      Color(0xFF30A14E),
      Color(0xFF216E39),
    ];
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _DayProgress {
  final int done;
  final int due;

  const _DayProgress(this.done, this.due);
}
