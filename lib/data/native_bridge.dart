import 'dart:async';

import 'package:flutter/services.dart';
import '../data/models/daily_stat.dart';
import '../data/models/settings.dart';
import '../data/models/live_count.dart';
import '../data/models/tracked_app_info.dart';

/// Platform channel bridge to native Android code
class NativeBridge {
  static Future<String> getTimeZone() async =>
      await _methodChannel.invokeMethod<String>('getTimeZone') ?? 'UTC';
  static const MethodChannel _methodChannel = MethodChannel('scrollcount/methods');
  static const EventChannel _eventChannel = EventChannel('scrollcount/live');

  /// Check if accessibility service is enabled
  static Future<bool> isAccessibilityEnabled() async {
    try {
      return await _methodChannel.invokeMethod<bool>('isAccessibilityEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open the Unreel accessibility switch
  static Future<void> openAccessibilitySettings() async {
    await _methodChannel.invokeMethod('openAccessibilitySettings');
  }

  /// Whether the count bubble is allowed to draw over other apps
  static Future<bool> canDrawOverlays() async {
    try {
      return await _methodChannel.invokeMethod<bool>('canDrawOverlays') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open the display-over-apps switch for this app
  static Future<void> openOverlaySettings() async {
    await _methodChannel.invokeMethod('openOverlaySettings');
  }

  /// Open this app's notification settings
  static Future<void> openNotificationSettings() async {
    await _methodChannel.invokeMethod('openNotificationSettings');
  }

  /// Launcher icon for a tracked app, as PNG bytes
  static Future<Uint8List?> getAppIcon(String appId) async {
    try {
      final result = await _methodChannel.invokeMethod<Uint8List>('getAppIcon', {
        'appId': appId,
      });
      if (result == null || result.isEmpty) return null;
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Post a real system notification, not an in-app banner
  static Future<bool> showTestNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    return await _methodChannel.invokeMethod<bool>('showTestNotification', {
      'id': id,
      'title': title,
      'body': body,
    }) ?? false;
  }

  /// Get today's stats
  static Future<DailyStat> getToday() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('getToday');
      if (result == null) {
        return DailyStat(day: '', total: 0, totalSeconds: 0, perApp: []);
      }
      return DailyStat.fromJson(Map<String, dynamic>.from(result));
    } catch (_) {
      return DailyStat(day: '', total: 0, totalSeconds: 0, perApp: []);
    }
  }

  /// Get stats for a date range
  static Future<List<Map<String, dynamic>>> getRange(String startDay, String endDay) async {
    try {
      final result = await _methodChannel.invokeMethod<List<dynamic>>('getRange', {
        'startDay': startDay,
        'endDay': endDay,
      });
      if (result == null) return [];
      return result.whereType<Map>().map((e) {
        final map = Map<String, dynamic>.from(e);
        map['count'] = _asInt(map['count']);
        map['seconds'] = _asInt(map['seconds']);
        return map;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get all settings
  static Future<Settings> getSettings() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('getSettings');
      if (result == null) return Settings();
      return Settings.fromJson(Map<String, dynamic>.from(result));
    } catch (_) {
      return Settings();
    }
  }

  /// Update settings
  static Future<bool> updateSettings(Settings settings) async {
    try {
      return await _methodChannel.invokeMethod<bool>('updateSettings', settings.toJson()) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Get tracked apps info
  static Future<List<TrackedAppInfo>> getTrackedApps() async {
    try {
      final result = await _methodChannel.invokeMethod<List<dynamic>>('getTrackedApps');
      if (result == null) return [];
      return result.whereType<Map>().map((e) => TrackedAppInfo.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  /// Export data as CSV
  static Future<String> exportCsv() async {
    try {
      return await _methodChannel.invokeMethod<String>('exportCsv') ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Clear all data
  static Future<bool> clearAllData() async {
    try {
      return await _methodChannel.invokeMethod<bool>('clearAllData') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open battery optimization settings
  static Future<void> openBatterySettings() async {
    try {
      await _methodChannel.invokeMethod('openBatterySettings');
    } catch (_) {}
  }

  /// Request notification permission (Android 13+)
  static Future<bool> requestNotificationPermission() async {
    try {
      return await _methodChannel.invokeMethod<bool>('requestNotificationPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Check if widget pinning is supported
  static Future<bool> isWidgetSupportedForPin() async {
    try {
      return await _methodChannel.invokeMethod<bool>('isWidgetSupportedForPin') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Request to pin widget
  static Future<bool> requestPinWidget() async {
    try {
      return await _methodChannel.invokeMethod<bool>('requestPinWidget') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Check if widget is added
  static Future<bool> isWidgetAdded() async {
    try {
      return await _methodChannel.invokeMethod<bool>('isWidgetAdded') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Force widget refresh
  static Future<void> refreshWidgets() async {
    try {
      await _methodChannel.invokeMethod('refreshWidgets');
    } catch (_) {}
  }

  /// Open the native limit block screen.
  static Future<bool> previewBlockScreen() async {
    try {
      return await _methodChannel.invokeMethod<bool>('previewBlockScreen') ?? false;
    } catch (_) {
      return false;
    }
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('$value') ?? 0;
  }

  /// Stream of live count updates
  static Stream<LiveCount> get liveCountStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      return LiveCount.fromJson(Map<String, dynamic>.from(event as Map));
    });
  }
}
