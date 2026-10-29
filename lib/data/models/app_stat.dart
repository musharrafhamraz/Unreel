/// Per-app statistics
class AppStat {
  final String appId;
  final int count;
  final int seconds;

  const AppStat({
    required this.appId,
    required this.count,
    required this.seconds,
  });

  factory AppStat.fromJson(Map<String, dynamic> json) {
    return AppStat(
      appId: json['appId']?.toString() ?? '',
      count: json['count'] is num ? (json['count'] as num).round() : int.tryParse('${json['count']}') ?? 0,
      seconds: json['seconds'] is num ? (json['seconds'] as num).round() : int.tryParse('${json['seconds']}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'appId': appId,
        'count': count,
        'seconds': seconds,
      };

  AppStat copyWith({
    String? appId,
    int? count,
    int? seconds,
  }) {
    return AppStat(
      appId: appId ?? this.appId,
      count: count ?? this.count,
      seconds: seconds ?? this.seconds,
    );
  }
}