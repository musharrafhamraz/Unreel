import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/repository_provider.dart';
import '../../core/widgets/bottom_nav_bar.dart';

/// History screen - M1 skeleton
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _selectedRange = 0; // 0 = 7 days, 1 = 30 days

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Range selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('7 Days')),
                ButtonSegment(value: 1, label: Text('30 Days')),
              ],
              selected: {_selectedRange},
              onSelectionChanged: (selection) {
                setState(() => _selectedRange = selection.first);
              },
            ),
          ),
          // Chart
          Expanded(
            child: _buildChart(context),
          ),
          // Day list
          _buildDayList(context),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildChart(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final days = _selectedRange == 0 ? 7 : 30;
    final endDay = app_date_utils.DateUtils.getCurrentLogicalDayString();
    final startDay = app_date_utils.DateUtils.getDayKeyDaysAgo(days - 1);

    return FutureBuilder(
      future: ref.read(scrollRepositoryProvider).getRange(startDay, endDay),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: colorScheme.primary));
        }

        final data = snapshot.data as List<Map<String, dynamic>>;
        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  'No data yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start scrolling reels to see your history',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }

        // Process data for chart
        final dailyTotals = <String, int>{};
        for (final entry in data) {
          final day = entry['day'] as String;
          final count = entry['count'] as int;
          dailyTotals[day] = (dailyTotals[day] ?? 0) + count;
        }

        // Create spots for all days in range
        final spots = <FlSpot>[];
        for (int i = 0; i < days; i++) {
          final dayKey = app_date_utils.DateUtils.getDayKeyDaysAgo(days - 1 - i);
          final count = dailyTotals[dayKey] ?? 0;
          spots.add(FlSpot(i.toDouble(), count.toDouble()));
        }

        final maxY = spots.isNotEmpty ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) : 10.0;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY / 4).ceilToDouble(),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= days) return const SizedBox.shrink();
                      final dayKey = app_date_utils.DateUtils.getDayKeyDaysAgo(days - 1 - value.toInt());
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          app_date_utils.DateUtils.formatDay(dayKey).split(', ')[0], // Just day name
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (maxY / 4).ceilToDouble(),
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        Formatters.formatNumber(value.toInt()),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (days - 1).toDouble(),
              minY: 0,
              maxY: maxY > 0 ? maxY : 10,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.3),
                        colorScheme.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final dayKey = app_date_utils.DateUtils.getDayKeyDaysAgo(days - 1 - spot.x.toInt());
                      return LineTooltipItem(
                        '${app_date_utils.DateUtils.formatDay(dayKey)}\n${Formatters.formatNumber(spot.y.toInt())} reels',
                        theme.textTheme.bodySmall?.copyWith(color: colorScheme.onInverseSurface) ?? const TextStyle(),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final days = _selectedRange == 0 ? 7 : 30;
    final endDay = app_date_utils.DateUtils.getCurrentLogicalDayString();
    final startDay = app_date_utils.DateUtils.getDayKeyDaysAgo(days - 1);

    return FutureBuilder(
      future: ref.read(scrollRepositoryProvider).getRange(startDay, endDay),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final data = snapshot.data as List<Map<String, dynamic>>;
        final dailyMap = <String, List<Map<String, dynamic>>>{};
        for (final entry in data) {
          final day = entry['day'] as String;
          dailyMap.putIfAbsent(day, () => []).add(entry);
        }

        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Daily Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: days,
                  itemBuilder: (context, index) {
                    final dayKey = app_date_utils.DateUtils.getDayKeyDaysAgo(days - 1 - index);
                    final entries = dailyMap[dayKey] ?? [];
                    final total = entries.fold<int>(0, (sum, e) => sum + (e['count'] as int));
                    final totalSeconds = entries.fold<int>(0, (sum, e) => sum + (e['seconds'] as int));

                    if (total == 0) return const SizedBox.shrink();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            Formatters.formatNumber(total),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(app_date_utils.DateUtils.formatDay(dayKey)),
                        subtitle: Text('${app_date_utils.DateUtils.formatTime(totalSeconds)}'),
                        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                        onTap: () {
                          // TODO: Show day detail bottom sheet
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}