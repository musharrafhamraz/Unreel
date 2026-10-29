import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollcount/data/services/notification_service.dart';
import 'package:scrollcount/providers/cognitive_tasks_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  var exact = false;
  var rejectExact = false;
  setUp(() {
    calls.clear();
    exact = false;
    rejectExact = false;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('scrollcount/methods'), (call) async => 'Asia/Karachi');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'initialize') return true;
      if (call.method == 'areNotificationsEnabled') return true;
      if (call.method == 'canScheduleExactNotifications') return exact;
      if (call.method == 'pendingNotificationRequests') return <dynamic>[];
      if (call.method == 'zonedSchedule' && rejectExact) {
        rejectExact = false;
        throw PlatformException(code: 'exact_alarms_not_permitted');
      }
      return null;
    });
  });
  tearDown(() { debugDefaultTargetPlatformOverride = null; });
  test('routine registers seven unique alarms in the device zone without cancelling first', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(taskNotificationSchedulerProvider).scheduleTodaysTaskNotifications();
    final alarms = calls.where((c) => c.method == 'zonedSchedule').map((c) => c.arguments as Map).toList();
    expect(alarms, hasLength(7));
    expect(alarms.map((a) => a['id']).toSet(), hasLength(7));
    expect(alarms.every((a) => a['timeZoneName'] == 'Asia/Karachi'), isTrue);
    expect(calls.where((c) => c.method == 'cancel'), isEmpty);
  });
  test('revoked exact-alarm permission retries with an inexact alarm', () async {
    exact = true;
    rejectExact = true;
    await NotificationService().scheduleDailyReminder();
    final alarms = calls.where((c) => c.method == 'zonedSchedule').toList();
    expect(alarms, hasLength(2));
    expect(alarms.first.arguments['platformSpecifics']['scheduleMode'], 'exactAllowWhileIdle');
    expect(alarms.last.arguments['platformSpecifics']['scheduleMode'], 'inexactAllowWhileIdle');
  });
  test('delayed test uses the alarm path and does not repeat daily', () async {
    await NotificationService().scheduleTestNotification();
    final alarm = calls.singleWhere((c) => c.method == 'zonedSchedule').arguments as Map;
    expect(alarm['id'], 9001);
    expect(alarm.containsKey('matchDateTimeComponents'), isFalse);
  });
}
