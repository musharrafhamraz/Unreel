import 'app_stat.dart';

/// Daily statistics model
class DailyStat {
  final String day;
  final int total;
  final int totalSeconds;
  final List<AppStat> perApp;

  const DailyStat({
    required this.day,
    required this.total,
    required this.totalSeconds,
    required this.perApp,
  });

  factory DailyStat.fromJson(Map<String, dynamic> json) {
    final perApp = <AppStat>[];
    final raw = json['perApp'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          perApp.add(AppStat.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return DailyStat(
      day: json['day']?.toString() ?? '',
      total: _asInt(json['total']),
      totalSeconds: _asInt(json['totalSeconds']),
      perApp: perApp,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('$value') ?? 0;
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'total': total,
        'totalSeconds': totalSeconds,
        'perApp': perApp.map((e) => e.toJson()).toList(),
      };

  DailyStat copyWith({
    String? day,
    int? total,
    int? totalSeconds,
    List<AppStat>? perApp,
  }) {
    return DailyStat(
      day: day ?? this.day,
      total: total ?? this.total,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      perApp: perApp ?? this.perApp,
    );
  }
}