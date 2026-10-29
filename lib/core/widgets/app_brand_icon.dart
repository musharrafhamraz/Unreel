import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../data/native_bridge.dart';
import '../theme/colors.dart';

/// The installed app's launcher icon. A drawn mark is used only until that
/// icon arrives, or when the app is not installed.
class AppBrandIcon extends StatefulWidget {
  final String appId;
  final double size;

  const AppBrandIcon({super.key, required this.appId, this.size = 40});

  @override
  State<AppBrandIcon> createState() => _AppBrandIconState();
}

class _AppBrandIconState extends State<AppBrandIcon> {
  static final Map<String, Uint8List?> _cache = {};
  late Future<Uint8List?> _icon;

  @override
  void initState() {
    super.initState();
    _icon = _load(widget.appId);
  }

  @override
  void didUpdateWidget(AppBrandIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appId != widget.appId) {
      _icon = _load(widget.appId);
    }
  }

  static Future<Uint8List?> _load(String appId) {
    if (_cache.containsKey(appId)) return Future.value(_cache[appId]);
    return NativeBridge.getAppIcon(appId).then((bytes) {
      _cache[appId] = bytes;
      return bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.size * 0.22);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: FutureBuilder<Uint8List?>(
        future: _icon,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes != null) {
            return ClipRRect(
              borderRadius: radius,
              child: Image.memory(bytes, width: widget.size, height: widget.size, fit: BoxFit.cover, gaplessPlayback: true),
            );
          }
          return ClipRRect(
            borderRadius: radius,
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _BrandMarkPainter(widget.appId),
            ),
          );
        },
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  final String appId;

  _BrandMarkPainter(this.appId);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.width * 0.22);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), Paint()..color = _background);

    switch (appId) {
      case 'instagram':
        _camera(canvas, size);
      case 'youtube_shorts':
        _play(canvas, size);
      case 'facebook_reels':
        _people(canvas, size);
      case 'snapchat':
        _ghost(canvas, size);
      default:
        break;
    }
  }

  Color get _background {
    switch (appId) {
      case 'instagram':
        return const Color(0xFFE1306C);
      case 'youtube_shorts':
        return const Color(0xFFFF0000);
      case 'facebook_reels':
        return const Color(0xFF1877F2);
      case 'snapchat':
        return const Color(0xFFFFFC00);
      default:
        return appAccentColors[appId] ?? const Color(0xFF4F46E5);
    }
  }

  void _camera(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07;
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, size.width * 0.22, paint);
    canvas.drawCircle(center, size.width * 0.08, Paint()..color = Colors.white);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: size.width * 0.62, height: size.width * 0.62),
        Radius.circular(size.width * 0.16),
      ),
      paint,
    );
  }

  void _play(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.38, size.height * 0.28)
      ..lineTo(size.width * 0.72, size.height * 0.5)
      ..lineTo(size.width * 0.38, size.height * 0.72)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  void _people(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.38), size.width * 0.12, paint);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.4), size.width * 0.1, paint);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.38, size.height * 0.68), width: size.width * 0.32, height: size.width * 0.22),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.64, size.height * 0.68), width: size.width * 0.26, height: size.width * 0.18),
      paint,
    );
  }

  void _ghost(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF111827);
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.22, size.height * 0.42, size.width * 0.5, size.height * 0.22)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.4, size.width * 0.74, size.height * 0.72)
      ..lineTo(size.width * 0.64, size.height * 0.64)
      ..lineTo(size.width * 0.54, size.height * 0.74)
      ..lineTo(size.width * 0.44, size.height * 0.64)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.46), size.width * 0.035, Paint()..color = const Color(0xFFFFFC00));
    canvas.drawCircle(Offset(size.width * 0.58, size.height * 0.46), size.width * 0.035, Paint()..color = const Color(0xFFFFFC00));
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) => oldDelegate.appId != appId;
}
