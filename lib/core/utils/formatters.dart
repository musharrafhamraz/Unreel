/// Number and string formatters
class Formatters {
  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  static String formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }

  static String formatPercent(double value, {int fractionDigits = 0}) {
    return '${value.toStringAsFixed(fractionDigits)}%';
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String formatAppId(String appId) {
    switch (appId) {
      case 'instagram':
        return 'Instagram';
      case 'youtube_shorts':
        return 'YouTube';
      case 'facebook_reels':
        return 'Facebook';
      case 'snapchat':
        return 'Snapchat';
      default:
        return capitalize(appId.replaceAll('_', ' '));
    }
  }
}