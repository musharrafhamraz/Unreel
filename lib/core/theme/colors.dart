import 'package:flutter/material.dart';

/// Light theme color palette
const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFE8682C),
  onPrimary: Colors.white,
  primaryContainer: Color(0xFFFFE2D0),
  onPrimaryContainer: Color(0xFF5A260F),
  secondary: Color(0xFF4C7C59),
  onSecondary: Colors.white,
  secondaryContainer: Color(0xFFE1F0E3),
  onSecondaryContainer: Color(0xFF183F24),
  tertiary: Color(0xFFF1A43A),
  onTertiary: Colors.white,
  tertiaryContainer: Color(0xFFFFF3CD),
  onTertiaryContainer: Color(0xFF78350F),
  error: Color(0xFFE11D48), // Danger rose
  onError: Colors.white,
  errorContainer: Color(0xFFFFE4E6),
  onErrorContainer: Color(0xFF9F1239),
  surface: Color(0xFFFFFCF8),
  onSurface: Color(0xFF2D211C),
  surfaceContainerHighest: Color(0xFFFFF6ED),
  onSurfaceVariant: Color(0xFF786960),
  outline: Color(0xFFEBDCD1),
  outlineVariant: Color(0xFFF7EDE5),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF34251E),
  onInverseSurface: Color(0xFFFFF6ED),
  inversePrimary: Color(0xFFFFB48B),
);

/// Dark theme color palette
const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFFFA36C),
  onPrimary: Color(0xFF55230C),
  primaryContainer: Color(0xFF743A1E),
  onPrimaryContainer: Color(0xFFFFE2D0),
  secondary: Color(0xFFA3D3A9),
  onSecondary: Color(0xFF183F24),
  secondaryContainer: Color(0xFF214B2B),
  onSecondaryContainer: Color(0xFFE1F0E3),
  tertiary: Color(0xFFFFCB73),
  onTertiary: Color(0xFF553400),
  tertiaryContainer: Color(0xFF664514),
  onTertiaryContainer: Color(0xFFFFE2B3),
  error: Color(0xFFFB7185),
  onError: Color(0xFF9F1239),
  errorContainer: Color(0xFF9F1239),
  onErrorContainer: Color(0xFFFFE4E6),
  surface: Color(0xFF281D18),
  onSurface: Color(0xFFFFF6ED),
  surfaceContainerHighest: Color(0xFF1D1511),
  onSurfaceVariant: Color(0xFFD6C0B2),
  outline: Color(0xFF5F4A3F),
  outlineVariant: Color(0xFF3B2A22),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFFFF6ED),
  onInverseSurface: Color(0xFF2D211C),
  inversePrimary: Color(0xFFE8682C),
);

/// Per-app accent colors
const Map<String, Color> appAccentColors = {
  'instagram': Color(0xFFE1306C),
  'youtube_shorts': Color(0xFFFF0000),
  'facebook_reels': Color(0xFF1877F2),
  'snapchat': Color(0xFFFFFC00),
};

/// App display names
const Map<String, String> appDisplayNames = {
  'instagram': 'Instagram Reels',
  'youtube_shorts': 'YouTube Shorts',
  'facebook_reels': 'Facebook Reels',
  'snapchat': 'Snapchat Spotlight',
};
