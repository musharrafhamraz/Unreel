import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../providers/today_provider.dart';
import '../../providers/tracked_apps_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/permission_provider.dart';
import '../../providers/repository_provider.dart';
import '../../providers/cognitive_tasks_provider.dart';
import '../../data/models/cognitive_task.dart';
import '../../data/native_bridge.dart';
import '../../data/services/notification_service.dart';
import '../../core/widgets/app_brand_icon.dart';
import '../../core/widgets/bottom_nav_bar.dart';
import '../../core/widgets/contribution_grid.dart';
import '../../core/widgets/setup_card.dart';

/// Dashboard screen - M1 skeleton with placeholder data
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleReminders();
    });
  }

  Future<void> _scheduleReminders() async {
    try {
      await ref.read(cognitiveTasksProvider.future);
      final allowed = await NotificationService().notificationsEnabled();
      if (!allowed) return;
      await ref.read(taskNotificationSchedulerProvider).scheduleTodaysTaskNotifications();
    } catch (e) {
      debugPrint('Could not schedule reminders: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(permissionProvider);
      ref.invalidate(setupStatusProvider);
      ref.invalidate(todayProvider);
      _scheduleReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final todayAsync = ref.watch(todayProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            title: const Text('Unreel'),
            centerTitle: false,
            floating: true,
            snap: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.go('/settings'),
              ),
            ],
          ),
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SetupCard(),
                const SizedBox(height: 16),

                // Hero card
                _HeroCard(
                  todayAsync: todayAsync,
                  settingsAsync: settingsAsync,
                ),
                const SizedBox(height: 16),

                // Cognitive Reset Progress
                _CognitiveResetProgress(),
                const SizedBox(height: 16),

                // Per-app cards
                _PerAppCards(todayAsync: todayAsync),
                const SizedBox(height: 16),

                const ContributionGrid(),
                const SizedBox(height: 16),

                // Widget prompt
                _WidgetPrompt(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 0),
    );
  }
}

/// Hero card with circular progress
class _HeroCard extends ConsumerWidget {
  final AsyncValue<dynamic> todayAsync;
  final AsyncValue<dynamic> settingsAsync;

  const _HeroCard({
    required this.todayAsync,
    required this.settingsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
            ),
            const SizedBox(height: 14),
            Text('Your attention, protected', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            // Circular progress
            todayAsync.when(
              data: (today) {
                final total = (today as dynamic).total ?? 0;
                final limit = settingsAsync.value?.globalLimit ?? 100;
                final hasLimit = limit > 0;
                final progress = hasLimit ? (total / limit).clamp(0.0, 1.0) : 0.0;
                final progressColor = hasLimit
                    ? (progress >= 1.0
                        ? colorScheme.error
                        : progress >= 0.8
                            ? colorScheme.tertiary
                            : colorScheme.primary)
                    : colorScheme.primary;

                return Column(
                  children: [
                    Text(
                      Formatters.formatNumber(total),
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'reels watched today',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (hasLimit) ...[
                      const SizedBox(height: 16),
                      Text(
                        '$total / $limit reels',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: progressColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '\u2248 ${app_date_utils.DateUtils.formatTime((today as dynamic).totalSeconds ?? 0)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 72,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => Column(
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 8),
                  Text('Error loading data', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Per-app breakdown cards
class _PerAppCards extends ConsumerWidget {
  final AsyncValue<dynamic> todayAsync;

  const _PerAppCards({required this.todayAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return todayAsync.when(
      data: (today) {
        final perApp = (today as dynamic).perApp as List<dynamic>? ?? [];
        if (perApp.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By App',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...perApp.map((app) => _AppCard(app: app)).toList(),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _AppCard extends StatelessWidget {
  final dynamic app;

  const _AppCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appId = app.appId as String;
    final count = app.count as int;
    final accentColor = appAccentColors[appId] ?? colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AppBrandIcon(appId: appId, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.formatAppId(appId),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count reels',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.formatNumber(count),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget prompt card
class _WidgetPrompt extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasWidget = ref.watch(widgetInstalledProvider).valueOrNull ?? false;

    if (hasWidget) return const SizedBox.shrink();

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.widgets_outlined, color: colorScheme.onPrimaryContainer, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add a widget to your home screen',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'See your reel count at a glance without opening the app',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () async {
                final repository = ref.read(scrollRepositoryProvider);
                final supported = await repository.isWidgetSupportedForPin();
                if (!context.mounted) return;
                if (!supported) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Widget pinning is not supported by this launcher')),
                  );
                  return;
                }
                await repository.requestPinWidget();
                ref.invalidate(widgetInstalledProvider);
              },
              child: const Text('Add Widget'),
            ),
          ],
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
    final colorScheme = theme.colorScheme;

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

/// Cognitive Reset Progress Section
class _CognitiveResetProgress extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final tasksAsync = ref.watch(cognitiveTasksProvider);
    final tasks = ref.watch(todaysCognitiveTasksProvider);
    final grouped = ref.watch(todaysCognitiveTasksGroupedProvider);
    final stats = ref.watch(todaysCognitiveStatsProvider);
    final completionAsync = ref.watch(cognitiveTaskCompletionProvider);

    if (tasksAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (tasksAsync.hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(Icons.notifications_active_outlined, color: colorScheme.primary),
              tooltip: 'Test notifications',
              onPressed: () => _sendTestNotification(context, const []),
            ),
          ),
          const _EmptyState(
            icon: Icons.error_outline,
            title: 'Could not read tasks',
            subtitle: 'The cognitive reset CSV could not be loaded. You can still send a test reminder.',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with overall progress
        Row(
          children: [
            Icon(Icons.psychology_outlined, color: colorScheme.primary, size: 24),
            const SizedBox(width: 12),
            Text(
              'Daily Cognitive Reset',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            _ProgressChip(
              completed: stats['completed'] as int,
              total: stats['total'] as int,
              percentage: (stats['percentage'] as double),
            ),
            const SizedBox(width: 8),
            // Test notification button
            IconButton(
              icon: Icon(Icons.notifications_active_outlined, color: colorScheme.primary),
              onPressed: () => _sendTestNotification(context, tasks),
              tooltip: 'Test notifications',
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Task list grouped by section
        tasks.isEmpty
            ? _EmptyState(
                icon: Icons.event_available_outlined,
                title: 'No tasks for today',
                subtitle: 'Check back tomorrow for your routine',
              )
            : Column(
                children: grouped.entries.map((entry) {
                  final section = entry.key;
                  final sectionTasks = entry.value;
                  return _SectionCard(
                    section: section,
                    tasks: sectionTasks,
                    completionAsync: completionAsync,
                  );
                }).toList(),
              ),
      ],
    );
  }
}

/// Post one system notification. The bell used to open a dialog, and that
/// dialog's dark scrim was the only thing that appeared.
Future<void> _sendTestNotification(BuildContext context, List<CognitiveTask> tasks) async {
  final messenger = ScaffoldMessenger.of(context);
  final errorColor = Theme.of(context).colorScheme.error;
  try {
    final sample = tasks.isEmpty ? null : tasks.first;
    await NotificationService().showImmediateNotification(
      id: 9000,
      title: 'Unreel test',
      body: sample == null
          ? 'Reminders are working. Pull down from the top of the screen.'
          : sample.task,
    );
    await NotificationService().scheduleTestNotification();
    messenger.showSnackBar(const SnackBar(
      content: Text('A second test is scheduled in about one minute. You can leave the app; battery restrictions may delay it.'),
    ));
  } on NotificationsDisabledException {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Notifications are off. Turn them on for Unreel, then try again.'),
      ),
    );
    try {
      await NativeBridge.openNotificationSettings();
    } catch (_) {}
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Could not send the test: $e'),
        backgroundColor: errorColor,
      ),
    );
  }
}

/// Progress chip showing completion percentage
class _ProgressChip extends StatelessWidget {
  final int completed;
  final int total;
  final double percentage;

  const _ProgressChip({
    required this.completed,
    required this.total,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progressColor = percentage >= 100 ? colorScheme.tertiary : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: progressColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: progressColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              value: total > 0 ? percentage / 100 : 0,
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(progressColor),
              backgroundColor: progressColor.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$completed / $total',
            style: theme.textTheme.labelMedium?.copyWith(
              color: progressColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section card for Morning/Afternoon/Evening tasks
class _SectionCard extends ConsumerWidget {
  final CognitiveSection section;
  final List<CognitiveTask> tasks;
  final AsyncValue<Map<String, bool>> completionAsync;

  const _SectionCard({
    required this.section,
    required this.tasks,
    required this.completionAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sectionColor = _getSectionColor(section, colorScheme);
    final completions = completionAsync.valueOrNull ?? {};

    final completedCount = tasks.where((t) => completions[t.id] == true).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: sectionColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_getSectionIcon(section), color: sectionColor, size: 22),
        ),
        title: Text(
          section.displayName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '$completedCount / ${tasks.length} completed',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: completedCount == tasks.length && tasks.isNotEmpty
            ? Icon(Icons.check_circle, color: colorScheme.tertiary, size: 22)
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: tasks.map((task) => _TaskTile(
                task: task,
                isCompleted: completions[task.id] == true,
                sectionColor: sectionColor,
                onToggle: (value) async {
                  await ref.read(cognitiveTaskCompletionProvider.notifier)
                      .toggleTaskCompletion(task.id, value ?? false);
                },
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSectionColor(CognitiveSection section, ColorScheme colorScheme) {
    switch (section) {
      case CognitiveSection.morning:
        return Colors.orange;
      case CognitiveSection.afternoon:
        return Colors.blue;
      case CognitiveSection.evening:
        return Colors.purple;
    }
  }

  IconData _getSectionIcon(CognitiveSection section) {
    switch (section) {
      case CognitiveSection.morning:
        return Icons.wb_sunny_outlined;
      case CognitiveSection.afternoon:
        return Icons.work_outline;
      case CognitiveSection.evening:
        return Icons.nights_stay_outlined;
    }
  }
}

/// Individual task tile with checkbox
class _TaskTile extends StatelessWidget {
  final CognitiveTask task;
  final bool isCompleted;
  final Color sectionColor;
  final ValueChanged<bool?> onToggle;

  const _TaskTile({
    required this.task,
    required this.isCompleted,
    required this.sectionColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          Transform.scale(
            scale: 1.1,
            child: Checkbox(
              value: isCompleted,
              onChanged: onToggle,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(color: sectionColor, width: 2),
              activeColor: sectionColor,
              checkColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 12),
          // Task content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.task,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted 
                        ? colorScheme.onSurfaceVariant 
                        : colorScheme.onSurface,
                  ),
                ),
                if (task.goal.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.goal,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state widget
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
