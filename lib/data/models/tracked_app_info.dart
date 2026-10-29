/// Tracked app info from native side
class TrackedAppInfo {
  final String appId;
  final String displayName;
  final String packageName;
  final bool installed;
  final bool detectionConfigured;

  const TrackedAppInfo({
    required this.appId,
    required this.displayName,
    required this.packageName,
    required this.installed,
    required this.detectionConfigured,
  });

  factory TrackedAppInfo.fromJson(Map<String, dynamic> json) {
    return TrackedAppInfo(
      appId: json['appId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      packageName: json['packageName']?.toString() ?? '',
      installed: json['installed'] == true,
      detectionConfigured: json['detectionConfigured'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'appId': appId,
        'displayName': displayName,
        'packageName': packageName,
        'installed': installed,
        'detectionConfigured': detectionConfigured,
      };
}