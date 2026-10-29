import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/tracked_apps_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/repository_provider.dart';
import '../../core/widgets/app_brand_icon.dart';
import '../../core/widgets/bottom_nav_bar.dart';

/// Apps screen - M1 skeleton
class AppsScreen extends ConsumerWidget {
  const AppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trackedAppsAsync = ref.watch(trackedAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: trackedAppsAsync.when(
        data: (apps) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                            'Tracked Apps',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enable or disable tracking for each app. Detection status shows if the app\'s UI patterns are configured.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...apps.map((app) {
                final tracked = ref.watch(settingsProvider).maybeWhen(
                      data: (settings) => settings.trackedApps.contains(app.appId),
                      orElse: () => false,
                    );
                return _AppTile(
                  app: app,
                  tracked: tracked,
                  onChanged: (value) => _setTracked(ref, app.appId, value),
                );
              }),
              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        error: (_, __) => Center(
          child: Text('Error loading apps', style: theme.textTheme.bodyMedium),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 3),
    );
  }
}

Future<void> _setTracked(WidgetRef ref, String appId, bool enabled) async {
  final settings = ref.read(settingsProvider).valueOrNull;
  if (settings == null) return;
  final apps = List<String>.from(settings.trackedApps);
  if (enabled) {
    if (!apps.contains(appId)) apps.add(appId);
  } else {
    apps.remove(appId);
  }
  final ok = await ref.read(scrollRepositoryProvider).updateSettings(settings.copyWith(trackedApps: apps));
  if (ok) ref.invalidate(settingsProvider);
}

class _AppTile extends StatelessWidget {
  final dynamic app;
  final bool tracked;
  final ValueChanged<bool> onChanged;

  const _AppTile({
    required this.app,
    required this.tracked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appId = app.appId as String;
    final displayName = app.displayName as String;
    final packageName = app.packageName as String;
    final installed = app.installed as bool;
    final detectionConfigured = app.detectionConfigured as bool;
    final accentColor = appAccentColors[appId] ?? colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AppBrandIcon(appId: appId, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          displayName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!installed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Not installed',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          detectionConfigured ? Icons.check_circle : Icons.warning_amber,
                          size: 14,
                          color: detectionConfigured ? colorScheme.secondary : colorScheme.tertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          detectionConfigured ? 'Detection configured' : 'Detection not configured',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: detectionConfigured ? colorScheme.secondary : colorScheme.tertiary,
                          ),
                        ),
                        if (packageName.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Text(
                            packageName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: tracked,
                onChanged: onChanged,
                activeThumbColor: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom navigation bar
class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Icons.timer_outlined),
          selectedIcon: Icon(Icons.timer),
          label: 'Limits',
        ),
        NavigationDestination(
          icon: Icon(Icons.apps_outlined),
          selectedIcon: Icon(Icons.apps),
          label: 'Apps',
        ),
      ],
    );
  }
}