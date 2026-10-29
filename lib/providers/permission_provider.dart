import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/notification_service.dart';
import 'repository_provider.dart';

/// Permission state
enum PermissionStatus { unknown, granted, denied, permanentlyDenied }

/// What the user still needs to turn on
class SetupStatus {
  final bool countingOn;
  final bool bubbleOn;
  final bool remindersOn;

  const SetupStatus({
    required this.countingOn,
    required this.bubbleOn,
    required this.remindersOn,
  });

  bool get ready => countingOn && bubbleOn && remindersOn;
}

final setupStatusProvider = FutureProvider.autoDispose<SetupStatus>((ref) async {
  final repository = ref.watch(scrollRepositoryProvider);
  final counting = await repository.isAccessibilityEnabled();
  final bubble = await repository.canDrawOverlays();
  var reminders = false;
  try {
    reminders = await NotificationService().notificationsEnabled();
  } catch (_) {
    reminders = false;
  }
  return SetupStatus(countingOn: counting, bubbleOn: bubble, remindersOn: reminders);
});

/// Permission provider - tracks accessibility service status
final permissionProvider = StreamProvider.autoDispose<PermissionStatus>((ref) async* {
  final repository = ref.watch(scrollRepositoryProvider);
  
  // Initial check
  final enabled = await repository.isAccessibilityEnabled();
  yield enabled ? PermissionStatus.granted : PermissionStatus.denied;

  // TODO: In a real implementation, we'd listen to system broadcasts
  // For now, we'll just yield the initial state
  // The app will re-check on resume via WidgetsBindingObserver
});