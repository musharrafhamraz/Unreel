import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/scroll_repository.dart';
import '../data/models/settings.dart';
import 'repository_provider.dart';

/// Settings provider
final settingsProvider = FutureProvider<Settings>((ref) async {
  final repository = ref.watch(scrollRepositoryProvider);
  return repository.getSettings();
});

/// Settings notifier for updating settings
final settingsNotifierProvider = AsyncNotifierProvider<SettingsNotifier, Settings>(() {
  return SettingsNotifier();
});

class SettingsNotifier extends AsyncNotifier<Settings> {
  @override
  Future<Settings> build() async {
    final repository = ref.watch(scrollRepositoryProvider);
    return repository.getSettings();
  }

  Future<void> updateSettings(Settings newSettings) async {
    state = const AsyncLoading();
    final repository = ref.watch(scrollRepositoryProvider);
    final success = await repository.updateSettings(newSettings);
    if (success) {
      state = AsyncData(newSettings);
    } else {
      state = AsyncError(Exception('Failed to update settings'), StackTrace.current);
    }
  }
}