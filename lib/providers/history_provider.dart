import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/scroll_repository.dart';
import 'repository_provider.dart';

/// History provider for 7/30 day range
final historyProvider = FutureProvider.family<List<Map<String, dynamic>>, ({String startDay, String endDay})>(
  (ref, params) async {
    final repository = ref.watch(scrollRepositoryProvider);
    return repository.getRange(params.startDay, params.endDay);
  },
);