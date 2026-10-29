import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/app_brand_icon.dart';
import '../../providers/settings_provider.dart';
import '../../providers/repository_provider.dart';

/// Onboarding screen - M1 skeleton
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Map<String, bool> _tracked = {
    'instagram': true,
    'youtube_shorts': true,
    'facebook_reels': false,
    'snapchat': false,
  };

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            // Page view
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildPage1(context),
                  _buildPage2(context),
                  _buildPage3(context),
                  _buildPage4(context),
                ],
              ),
            ),
            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (_currentPage < 3) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                      return;
                    }
                    await _completeOnboarding();
                  },
                  child: Text(_currentPage == 3 ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final repository = ref.read(scrollRepositoryProvider);
    final currentSettings = await repository.getSettings();
    
    final trackedApps = _tracked.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    await repository.updateSettings(
      currentSettings.copyWith(
        trackedApps: trackedApps,
        onboardingCompleted: true,
      ),
    );
    ref.invalidate(settingsProvider);

    if (context.mounted) {
      context.go('/dashboard');
    }
  }

  Widget _buildPage1(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.remove_red_eye_outlined,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to Unreel',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'See how much you really scroll through Reels, Shorts, and Spotlight each day.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPage2(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security_outlined,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'How It Works',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'We use Android\'s Accessibility feature to detect when a new reel appears. '
            'We never read your messages, passwords, or content. Nothing leaves your phone.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPage3(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apps_outlined,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Choose Apps to Track',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _AppToggleTile(
            appId: 'instagram',
            label: 'Instagram Reels',
            color: appAccentColors['instagram']!,
            value: _tracked['instagram']!,
            onChanged: (value) => setState(() => _tracked['instagram'] = value),
          ),
          _AppToggleTile(
            appId: 'youtube_shorts',
            label: 'YouTube Shorts',
            color: appAccentColors['youtube_shorts']!,
            value: _tracked['youtube_shorts']!,
            onChanged: (value) => setState(() => _tracked['youtube_shorts'] = value),
          ),
          _AppToggleTile(
            appId: 'facebook_reels',
            label: 'Facebook Reels',
            color: appAccentColors['facebook_reels']!,
            value: _tracked['facebook_reels']!,
            onChanged: (value) => setState(() => _tracked['facebook_reels'] = value),
          ),
          _AppToggleTile(
            appId: 'snapchat',
            label: 'Snapchat Spotlight',
            color: appAccentColors['snapchat']!,
            value: _tracked['snapchat']!,
            onChanged: (value) => setState(() => _tracked['snapchat'] = value),
          ),
        ],
      ),
    );
  }

  Widget _buildPage4(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Enable Permission',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'The next screen is the Unreel switch. Turn it on, then come back and tap Get Started. Android does not use a normal permission popup for this.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () async {
              try {
                await ref.read(scrollRepositoryProvider).openAccessibilitySettings();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open accessibility settings')),
                  );
                }
              }
            },
            icon: const Icon(Icons.settings_accessibility),
            label: const Text('Turn on counting'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppToggleTile extends StatelessWidget {
  final String appId;
  final String label;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AppToggleTile({
    required this.appId,
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          AppBrandIcon(appId: appId, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }
}