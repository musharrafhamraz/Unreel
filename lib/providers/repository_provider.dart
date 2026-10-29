import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/scroll_repository.dart';

/// Repository provider
final scrollRepositoryProvider = Provider<ScrollRepository>((ref) {
  return ScrollRepository();
});

/// Whether a home-screen widget is already pinned.
final widgetInstalledProvider = FutureProvider<bool>((ref) async {
  return ref.watch(scrollRepositoryProvider).isWidgetAdded();
});