import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/scroll_repository.dart';
import '../data/models/tracked_app_info.dart';
import 'repository_provider.dart';

/// Tracked apps provider
final trackedAppsProvider = FutureProvider<List<TrackedAppInfo>>((ref) async {
  final repository = ref.watch(scrollRepositoryProvider);
  return repository.getTrackedApps();
});