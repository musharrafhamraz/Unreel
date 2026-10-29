import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'providers/cognitive_tasks_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  try {
    // The task list is loaded asynchronously. Scheduling before that future
    // finishes reads an empty list and never registers the task names.
    await container.read(cognitiveTasksProvider.future);
    final scheduler = container.read(taskNotificationSchedulerProvider);
    await scheduler.scheduleTodaysTaskNotifications();
  } catch (e) {
    debugPrint('Could not schedule cognitive task reminders: $e');
  } finally {
    container.dispose();
  }

  runApp(const ProviderScope(child: App()));
}