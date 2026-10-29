import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/scroll_repository.dart';
import '../data/models/daily_stat.dart';
import '../data/models/live_count.dart';
import '../data/models/app_stat.dart';
import 'repository_provider.dart';

/// Today's stats provider - combines initial load with live updates
final todayProvider = StreamProvider.autoDispose<DailyStat>((ref) async* {
  final repository = ref.watch(scrollRepositoryProvider);

  // Initial load
  DailyStat current = await repository.getToday();
  yield current;

  // Listen to live updates. A dropped channel should keep the loaded day.
  try {
  await for (final liveCount in repository.liveCountStream) {
    if (liveCount is LiveCount) {
      // Merge live update into current state
      final updatedPerApp = current.perApp.map((appStat) {
        if (appStat.appId == liveCount.appId) {
          return appStat.copyWith(count: appStat.count + liveCount.count);
        }
        return appStat;
      }).toList();

      // If app not in list, add it
      if (!updatedPerApp.any((a) => a.appId == liveCount.appId)) {
        updatedPerApp.add(AppStat(appId: liveCount.appId, count: liveCount.count, seconds: 0));
      }

      current = current.copyWith(
        total: liveCount.total,
        perApp: updatedPerApp,
      );
      yield current;
    }
  }
  } catch (_) {}
});