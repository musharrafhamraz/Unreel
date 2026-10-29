/// App settings model
class Settings {
  final int globalLimit;
  final Map<String, int> perAppLimits;
  final List<String> trackedApps;
  final bool blockingEnabled;
  final bool strictMode;
  final int snoozeMinutes;
  final int resetHour;
  final int warnAtPercent;
  final bool overlayMode;
  final String themeMode;
  final bool onboardingCompleted;

  const Settings({
    this.globalLimit = 100,
    this.perAppLimits = const {},
    this.trackedApps = const ['instagram', 'youtube_shorts', 'facebook_reels', 'snapchat'],
    this.blockingEnabled = true,
    this.strictMode = false,
    this.snoozeMinutes = 5,
    this.resetHour = 0,
    this.warnAtPercent = 80,
    this.overlayMode = false,
    this.themeMode = 'system',
    this.onboardingCompleted = false,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    final limitsRaw = json['perAppLimits'];
    final limits = <String, int>{};
    if (limitsRaw is Map) {
      limitsRaw.forEach((key, value) {
        limits[key.toString()] = _asInt(value);
      });
    }
    final trackedRaw = json['trackedApps'];
    final tracked = trackedRaw is List
        ? trackedRaw.map((e) => e.toString()).toList()
        : <String>['instagram', 'youtube_shorts', 'facebook_reels', 'snapchat'];

    return Settings(
      globalLimit: _asInt(json['globalLimit'], 100),
      perAppLimits: limits,
      trackedApps: tracked,
      blockingEnabled: _asBool(json['blockingEnabled'], true),
      strictMode: _asBool(json['strictMode'], false),
      snoozeMinutes: _asInt(json['snoozeMinutes'], 5),
      resetHour: _asInt(json['resetHour']),
      warnAtPercent: _asInt(json['warnAtPercent'], 80),
      overlayMode: _asBool(json['overlayMode'], false),
      themeMode: json['themeMode'] as String? ?? 'system',
      onboardingCompleted: _asBool(json['onboardingCompleted'], false),
    );
  }

  Map<String, dynamic> toJson() => {
        'globalLimit': globalLimit,
        'perAppLimits': perAppLimits,
        'trackedApps': trackedApps,
        'blockingEnabled': blockingEnabled,
        'strictMode': strictMode,
        'snoozeMinutes': snoozeMinutes,
        'resetHour': resetHour,
        'warnAtPercent': warnAtPercent,
        'overlayMode': overlayMode,
        'themeMode': themeMode,
        'onboardingCompleted': onboardingCompleted,
      };

  Settings copyWith({
    int? globalLimit,
    Map<String, int>? perAppLimits,
    List<String>? trackedApps,
    bool? blockingEnabled,
    bool? strictMode,
    int? snoozeMinutes,
    int? resetHour,
    int? warnAtPercent,
    bool? overlayMode,
    String? themeMode,
    bool? onboardingCompleted,
  }) {
    return Settings(
      globalLimit: globalLimit ?? this.globalLimit,
      perAppLimits: perAppLimits ?? this.perAppLimits,
      trackedApps: trackedApps ?? this.trackedApps,
      blockingEnabled: blockingEnabled ?? this.blockingEnabled,
      strictMode: strictMode ?? this.strictMode,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      resetHour: resetHour ?? this.resetHour,
      warnAtPercent: warnAtPercent ?? this.warnAtPercent,
      overlayMode: overlayMode ?? this.overlayMode,
      themeMode: themeMode ?? this.themeMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('$value') ?? fallback;
  }

  static bool _asBool(dynamic value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  int getEffectiveLimit(String appId) {
    final perAppLimit = perAppLimits[appId] ?? 0;
    return perAppLimit > 0 ? perAppLimit : globalLimit;
  }

  bool hasLimit(String appId) {
    return getEffectiveLimit(appId) > 0;
  }
}