/// Live count update from EventChannel
class LiveCount {
  final String day;
  final String appId;
  final int count;
  final int total;

  const LiveCount({
    required this.day,
    required this.appId,
    required this.count,
    required this.total,
  });

  factory LiveCount.fromJson(Map<String, dynamic> json) {
    return LiveCount(
      day: json['day'] as String,
      appId: json['appId'] as String,
      count: json['count'] as int,
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'appId': appId,
        'count': count,
        'total': total,
      };
}