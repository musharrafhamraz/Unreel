import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../data/models/cognitive_task.dart';
import '../native_bridge.dart';

/// Thrown when Android will not show a notification for this app.
class NotificationsDisabledException implements Exception {
  @override
  String toString() => 'Notifications are turned off for Unreel';
}

/// Local reminders for the cognitive reset tasks.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _icon = '@drawable/ic_stat_notify';
  static const String _alertsChannelId = 'scrollcount_alerts';
  static const String _alertsChannelName = 'Unreel reminders';
  static const String _alertsChannelDescription = 'Task reminders and the test button';

  /// Prepare the plugin. Does not ask for permission; that needs a visible screen.
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(await NativeBridge.getTimeZone()));

    const androidSettings = AndroidInitializationSettings(_icon);
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// True when the app is allowed to post notifications.
  /// [request] shows the Android 13 permission dialog.
  Future<bool> notificationsEnabled({bool request = false}) async {
    await initialize();
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    if (await android.areNotificationsEnabled() == true) return true;
    if (!request) return false;
    return await android.requestNotificationsPermission() ?? false;
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Next local calendar occurrence, preserving daylight-saving rules.
  tz.TZDateTime _nextLocal(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var wall = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!wall.isAfter(now)) {
      wall = tz.TZDateTime(tz.local, now.year, now.month, now.day + 1, hour, minute);
    }
    return wall;
  }

  Future<void> refreshTimeZone() async {
    await initialize();
    tz.setLocalLocation(tz.getLocation(await NativeBridge.getTimeZone()));
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final exact = await android?.canScheduleExactNotifications() ?? false;
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
    required String payload,
    DateTimeComponents? repeat = DateTimeComponents.time,
  }) async {
    Future<void> submit(AndroidScheduleMode mode) => _notifications.zonedSchedule(
      id,
      title,
      body,
      when,
      details,
      androidScheduleMode: mode,
      matchDateTimeComponents: repeat,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
    try {
      await submit(await _scheduleMode());
    } on PlatformException catch (e) {
      if (e.code != 'exact_alarms_not_permitted') rethrow;
      await submit(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  AndroidNotificationDetails _androidDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
    StyleInformation? styleInformation,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: _icon,
      styleInformation: styleInformation,
    );
  }

  /// Schedule daily reminder for cognitive reset tasks
  Future<void> scheduleDailyReminder({
    int hour = 8,
    int minute = 0,
    String title = 'Cognitive Reset Reminder',
    String body = 'Time for your daily cognitive reset routine!',
  }) async {
    await initialize();

    final details = NotificationDetails(
      android: _androidDetails(
        channelId: _alertsChannelId,
        channelName: _alertsChannelName,
        channelDescription: _alertsChannelDescription,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _schedule(
      id: 1001,
      title: title,
      body: body,
      when: _nextLocal(hour, minute),
      details: details,
      payload: 'cognitive_reset_daily',
    );
  }

  /// Schedule section-specific reminders (morning, afternoon, evening)
  Future<void> scheduleSectionReminders() async {
    await initialize();

    const sections = [
      (id: 1002, hour: 7, minute: 0, title: 'Morning Awakening', body: 'Start your screen-free buffer & brain dump'),
      (id: 1003, hour: 13, minute: 0, title: 'Afternoon Focus', body: '10-min independent think & focus block'),
      (id: 1004, hour: 19, minute: 0, title: 'Evening Wind-down', body: 'Read aloud 15 min & digital curfew'),
    ];

    for (final section in sections) {
      await _scheduleSectionReminder(
        id: section.id,
        hour: section.hour,
        minute: section.minute,
        title: section.title,
        body: section.body,
      );
    }
  }

  Future<void> _scheduleSectionReminder({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {

    final details = NotificationDetails(
      android: _androidDetails(
        channelId: _alertsChannelId,
        channelName: _alertsChannelName,
        channelDescription: _alertsChannelDescription,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _schedule(
      id: id,
      title: title,
      body: body,
      when: _nextLocal(hour, minute),
      details: details,
      payload: 'cognitive_reset_section_$id',
    );
  }

  /// Show a notification immediately. Asks for permission if it is still off.
  Future<void> showImmediateNotification({
    int id = 9999,
    String title = 'Test Notification',
    String body = 'This is a test',
  }) async {
    final allowed = await notificationsEnabled(request: true);
    if (!allowed) throw NotificationsDisabledException();

    final shown = await NativeBridge.showTestNotification(id: id, title: title, body: body);
    if (!shown) throw NotificationsDisabledException();
  }

  Future<void> cancelAll() async {
    await initialize();
    await _notifications.cancelAll();
  }

  /// Exercises the same Android alarm receiver as daily reminders.
  Future<void> scheduleTestNotification() async {
    if (!await notificationsEnabled(request: true)) throw NotificationsDisabledException();
    await _schedule(
      id: 9001,
      title: 'Scheduled reminder test',
      body: 'This notification was delivered by the reminder scheduler.',
      when: tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1)),
      details: NotificationDetails(android: _androidDetails(
        channelId: _alertsChannelId,
        channelName: _alertsChannelName,
        channelDescription: _alertsChannelDescription,
      )),
      payload: 'scheduled_test',
      repeat: null,
    );
  }

  Future<void> cancel(int id) async {
    await initialize();
    await _notifications.cancel(id);
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await initialize();
    return _notifications.pendingNotificationRequests();
  }

  /// Schedule a notification for a specific task
  Future<void> scheduleTaskReminder({
    required int id,
    required int hour,
    required int minute,
    required CognitiveTask task,
    int? weekday,
  }) async {
    await initialize();

    final title = _buildTaskNotificationTitle(task);
    final body = _buildTaskNotificationBody(task);
    final details = NotificationDetails(
      android: _androidDetails(
        channelId: _alertsChannelId,
        channelName: _alertsChannelName,
        channelDescription: _alertsChannelDescription,
        styleInformation: BigTextStyleInformation(body, contentTitle: title),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    var when = _nextLocal(hour, minute);
    if (weekday != null) {
      while (when.weekday != weekday) {
        when = tz.TZDateTime(tz.local, when.year, when.month, when.day + 1, hour, minute);
      }
    }
    await _schedule(
      id: id,
      title: title,
      body: body,
      when: when,
      details: details,
      payload: 'cognitive_reset_task_${task.id}',
      repeat: weekday == null ? DateTimeComponents.time : DateTimeComponents.dayOfWeekAndTime,
    );
  }

  String _buildTaskNotificationTitle(CognitiveTask task) {
    final sectionIcon = _getSectionIcon(task.section);
    return '$sectionIcon ${task.task}';
  }

  String _buildTaskNotificationBody(CognitiveTask task) {
    final sectionName = _getShortSectionName(task.section);
    final goal = task.goal.isNotEmpty ? '\n\n${task.goal}' : '';
    return '$sectionName$goal';
  }

  String _getSectionIcon(String section) {
    if (section.contains('Morning')) return '🌅';
    if (section.contains('Afternoon')) return '☀️';
    if (section.contains('Evening')) return '🌙';
    return '📝';
  }

  String _getShortSectionName(String section) {
    if (section.contains('Morning')) return 'Morning Routine';
    if (section.contains('Afternoon')) return 'Afternoon Focus';
    if (section.contains('Evening')) return 'Evening Wind-down';
    return 'Daily Task';
  }
}
