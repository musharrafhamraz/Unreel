import '../data/models/daily_stat.dart';
import '../data/models/settings.dart';
import '../data/models/tracked_app_info.dart';
import 'native_bridge.dart';

/// Repository for scroll count data
class ScrollRepository {
  /// Get today's stats
  Future<DailyStat> getToday() async {
    return NativeBridge.getToday();
  }

  /// Get stats for a date range
  Future<List<Map<String, dynamic>>> getRange(String startDay, String endDay) async {
    return NativeBridge.getRange(startDay, endDay);
  }

  /// Get all settings
  Future<Settings> getSettings() async {
    return NativeBridge.getSettings();
  }

  /// Update settings
  Future<bool> updateSettings(Settings settings) async {
    return NativeBridge.updateSettings(settings);
  }

  /// Get tracked apps info
  Future<List<TrackedAppInfo>> getTrackedApps() async {
    return NativeBridge.getTrackedApps();
  }

  /// Export data as CSV
  Future<String> exportCsv() async {
    return NativeBridge.exportCsv();
  }

  /// Clear all data
  Future<bool> clearAllData() async {
    return NativeBridge.clearAllData();
  }

  /// Check if accessibility service is enabled
  Future<bool> isAccessibilityEnabled() async {
    return NativeBridge.isAccessibilityEnabled();
  }

  /// Open accessibility settings
  Future<void> openAccessibilitySettings() async {
    return NativeBridge.openAccessibilitySettings();
  }

  /// Whether the count bubble can draw over other apps
  Future<bool> canDrawOverlays() async {
    return NativeBridge.canDrawOverlays();
  }

  /// Open the display-over-apps switch
  Future<void> openOverlaySettings() async {
    return NativeBridge.openOverlaySettings();
  }

  /// Open this app's notification settings
  Future<void> openNotificationSettings() async {
    return NativeBridge.openNotificationSettings();
  }

  /// Open battery settings
  Future<void> openBatterySettings() async {
    return NativeBridge.openBatterySettings();
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    return NativeBridge.requestNotificationPermission();
  }

  /// Check if widget pinning is supported
  Future<bool> isWidgetSupportedForPin() async {
    return NativeBridge.isWidgetSupportedForPin();
  }

  /// Request to pin widget
  Future<bool> requestPinWidget() async {
    return NativeBridge.requestPinWidget();
  }

  /// Check if widget is added
  Future<bool> isWidgetAdded() async {
    return NativeBridge.isWidgetAdded();
  }

  /// Force widget refresh
  Future<void> refreshWidgets() async {
    return NativeBridge.refreshWidgets();
  }

  /// Open the native limit block screen.
  Future<bool> previewBlockScreen() async {
    return NativeBridge.previewBlockScreen();
  }

  /// Stream of live count updates
  Stream<dynamic> get liveCountStream => NativeBridge.liveCountStream;
}