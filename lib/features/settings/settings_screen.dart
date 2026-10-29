import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/repository_provider.dart';
import '../../core/theme/typography.dart';
import '../../data/models/tracked_app_info.dart';
import '../../providers/tracked_apps_provider.dart';
import '../../core/widgets/app_brand_icon.dart';
import '../../core/widgets/bottom_nav_bar.dart';
import '../../core/widgets/setup_card.dart';

/// Settings screen - M1 skeleton
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SetupCard(),
              const SizedBox(height: 16),
              // Widget section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.widgets_outlined, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Home Screen Widget',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a widget to see your reel count at a glance',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final repository = ref.read(scrollRepositoryProvider);
                          final supported = await repository.isWidgetSupportedForPin();
                          if (supported) {
                            await repository.requestPinWidget();
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Widget pinning not supported by your launcher')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Widget'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Theme section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.palette_outlined, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Theme',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.brightness_auto),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode),
                          ),
                        ],
                        selected: {_themeMode(settings.themeMode)},
                        onSelectionChanged: (selection) async {
                          final mode = switch (selection.first) {
                            ThemeMode.light => 'light',
                            ThemeMode.dark => 'dark',
                            ThemeMode.system => 'system',
                          };
                          final ok = await ref.read(scrollRepositoryProvider).updateSettings(
                                settings.copyWith(themeMode: mode),
                              );
                          if (ok) ref.invalidate(settingsProvider);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reset hour section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule_outlined, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Day Reset Hour',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Time when the daily count resets (0 = midnight)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('Reset at: ', style: theme.textTheme.bodyMedium),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: settings.resetHour,
                            items: List.generate(24, (h) {
                              return DropdownMenuItem(
                                value: h,
                                child: Text('${h.toString().padLeft(2, '0')}:00'),
                              );
                            }),
                            onChanged: (value) async {
                              if (value == null) return;
                              final ok = await ref.read(scrollRepositoryProvider).updateSettings(
                                    settings.copyWith(resetHour: value),
                                  );
                              if (ok) ref.invalidate(settingsProvider);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tracked Apps section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.apps_outlined, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Apps to Track',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select which apps to monitor for Reels/Shorts',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ref.watch(trackedAppsProvider).when(
                        data: (trackedApps) {
                          return Column(
                            children: trackedApps.map((app) => _TrackedAppTile(
                              app: app,
                              isTracked: settings.trackedApps.contains(app.appId),
                              onChanged: (value) async {
                                final updatedTracked = List<String>.from(settings.trackedApps);
                                if (value) {
                                  if (!updatedTracked.contains(app.appId)) updatedTracked.add(app.appId);
                                } else {
                                  updatedTracked.remove(app.appId);
                                }
                                final ok = await ref.read(scrollRepositoryProvider).updateSettings(
                                  settings.copyWith(trackedApps: updatedTracked),
                                );
                                if (ok) ref.invalidate(settingsProvider);
                              },
                            )).toList(),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => Text('Error loading apps', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Data section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.storage_outlined, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Data',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: Icon(Icons.download_outlined, color: colorScheme.primary),
                        title: const Text('Export CSV'),
                        subtitle: const Text('Export all data as CSV file'),
                        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                        onTap: () async {
                          final repository = ref.read(scrollRepositoryProvider);
                          final csv = await repository.exportCsv();
                          if (!mounted) return;
                          final lines = csv.trim().split(RegExp(r'\r?\n')).where((line) => line.trim().isNotEmpty);
                          if (lines.length <= 1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No count history to export yet')),
                            );
                            return;
                          }
                          await Share.share(csv, subject: 'Unreel export');
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.delete_outline, color: colorScheme.error),
                        title: const Text('Clear All Data'),
                        subtitle: const Text('Permanently delete all count history'),
                        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                        onTap: () => _showClearDataDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Battery optimization help
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.battery_alert_outlined, color: colorScheme.tertiary),
                          const SizedBox(width: 12),
                          Text(
                            'Battery Optimization',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Some devices aggressively kill background services. If counting stops working, try these steps.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          final repository = ref.read(scrollRepositoryProvider);
                          repository.openBatterySettings();
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Open Battery Settings'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Privacy section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.privacy_tip_outlined, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Privacy',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unreel uses Android Accessibility Service only to detect reel screens and count videos. '
                        'No screen content, messages, or personal data is collected, stored, or transmitted. '
                        'The app works fully offline with no internet permission.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // About section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            'About',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: Icon(Icons.description_outlined, color: colorScheme.primary),
                        title: const Text('How Detection Works'),
                        subtitle: const Text('Learn how we count reels'),
                        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                        onTap: () {
                          showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('How Detection Works'),
                              content: const Text(
                                'Unreel watches for reel, shorts, and spotlight screens using the Android accessibility service. '
                                'It counts a new video when the screen changes, and it does not read messages, passwords, or post content. '
                                'Counts stay on this phone.',
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                              ],
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.article_outlined, color: colorScheme.primary),
                        title: const Text('README'),
                        subtitle: const Text('Setup and limitations documentation'),
                        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                        onTap: () {
                          showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Setup'),
                              content: const Text(
                                '1. Turn on Unreel in Android accessibility settings.\n'
                                '2. Choose which apps to track.\n'
                                '3. Set a daily limit if you want a block screen.\n'
                                '4. Disable battery optimization so counting continues in the background.\n\n'
                                'The counter only works while the accessibility service stays enabled.',
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Unreel v1.0.0\nBuilt with Flutter & Kotlin',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        error: (_, __) => Center(
          child: Text('Error loading settings', style: theme.textTheme.bodyMedium),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 3),
    );
  }

  ThemeMode _themeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _showClearDataDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your reel count history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repository = ref.read(scrollRepositoryProvider);
      final success = await repository.clearAllData();
      if (success) {
        ref.invalidate(settingsProvider);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'All data cleared' : 'Failed to clear data'),
          ),
        );
      }
    }
  }
}

/// Tracked app tile for settings
class _TrackedAppTile extends StatelessWidget {
  final TrackedAppInfo app;
  final bool isTracked;
  final ValueChanged<bool> onChanged;

  const _TrackedAppTile({
    required this.app,
    required this.isTracked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = appAccentColors[app.appId] ?? colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          AppBrandIcon(appId: app.appId, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              app.displayName,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: isTracked,
            onChanged: onChanged,
            activeThumbColor: accentColor,
          ),
        ],
      ),
    );
  }
}
