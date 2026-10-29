import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/notification_service.dart';
import '../../providers/cognitive_tasks_provider.dart';
import '../../providers/permission_provider.dart';
import '../../providers/repository_provider.dart';

/// The two switches Unreel needs, each opening the exact settings page.
class SetupCard extends ConsumerStatefulWidget {
  const SetupCard({super.key});

  @override
  ConsumerState<SetupCard> createState() => _SetupCardState();
}

class _SetupCardState extends ConsumerState<SetupCard> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(setupStatusProvider);
    }
  }

  Future<void> _openCounting() async {
    try {
      await ref.read(scrollRepositoryProvider).openAccessibilitySettings();
    } catch (_) {
      _showFailed('Could not open the counting switch');
    }
  }

  Future<void> _openBubble() async {
    try {
      await ref.read(scrollRepositoryProvider).openOverlaySettings();
    } catch (_) {
      _showFailed('Could not open display permission');
    }
  }

  Future<void> _allowReminders() async {
    try {
      final allowed = await NotificationService().notificationsEnabled(request: true);
      if (!allowed) {
        await ref.read(scrollRepositoryProvider).openNotificationSettings();
        _showFailed('Turn notifications on for Unreel, then come back');
        return;
      }
      await ref.read(cognitiveTasksProvider.future);
      await ref.read(taskNotificationSchedulerProvider).scheduleTodaysTaskNotifications();
      ref.invalidate(setupStatusProvider);
    } catch (_) {
      _showFailed('Could not turn on reminders');
    }
  }

  void _showFailed(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = ref.watch(setupStatusProvider);

    return status.when(
      data: (setup) {
        if (setup.ready) return const SizedBox.shrink();
        final title = !setup.countingOn
            ? 'Turn counting on'
            : !setup.bubbleOn
                ? 'One more step'
                : 'Allow reminders';
        final body = !setup.countingOn
            ? 'Android turns counting off after an update. The next screen is the Unreel switch. Turn it on, then come back.'
            : !setup.bubbleOn
                ? 'Allow the brain bubble to appear over Reels. Android will show one switch for Unreel.'
                : 'Task reminders need notification permission. If Android already asked, the next screen is Unreel’s notification switch.';
        return Card(
          color: setup.countingOn ? colorScheme.secondaryContainer : colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(body, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                if (!setup.countingOn)
                  FilledButton.icon(
                    onPressed: _openCounting,
                    icon: const Icon(Icons.settings_accessibility),
                    label: const Text('Turn on counting'),
                  ),
                if (!setup.bubbleOn) ...[
                  if (!setup.countingOn) const SizedBox(height: 8),
                  setup.countingOn
                      ? FilledButton.icon(
                          onPressed: _openBubble,
                          icon: const Icon(Icons.picture_in_picture_alt_outlined),
                          label: const Text('Show count on screen'),
                        )
                      : OutlinedButton.icon(
                          onPressed: _openBubble,
                          icon: const Icon(Icons.picture_in_picture_alt_outlined),
                          label: const Text('Show count on screen'),
                        ),
                ],
                if (!setup.remindersOn) ...[
                  if (!setup.countingOn || !setup.bubbleOn) const SizedBox(height: 8),
                  setup.countingOn && setup.bubbleOn
                      ? FilledButton.icon(
                          onPressed: _allowReminders,
                          icon: const Icon(Icons.notifications_active_outlined),
                          label: const Text('Allow reminders'),
                        )
                      : OutlinedButton.icon(
                          onPressed: _allowReminders,
                          icon: const Icon(Icons.notifications_active_outlined),
                          label: const Text('Allow reminders'),
                        ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
