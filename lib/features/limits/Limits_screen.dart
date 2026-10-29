import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/settings_provider.dart';
import '../../providers/repository_provider.dart';
import '../../data/models/settings.dart';
import '../../core/widgets/app_brand_icon.dart';
import '../../core/widgets/bottom_nav_bar.dart';

/// Limits screen - M1 skeleton
class LimitsScreen extends ConsumerStatefulWidget {
  const LimitsScreen({super.key});

  @override
  ConsumerState<LimitsScreen> createState() => _LimitsScreenState();
}

class _LimitsScreenState extends ConsumerState<LimitsScreen> {
  bool _hydrated = false;
  late Settings _settings;
  late int _globalLimit;
  late Map<String, int> _perAppLimits;
  late bool _blockingEnabled;
  late bool _strictMode;
  late int _snoozeMinutes;
  late int _warnAtPercent;
  late bool _overlayMode;

  @override
  void initState() {
    super.initState();
    _settings = Settings();
    _globalLimit = 100;
    _perAppLimits = {};
    _blockingEnabled = true;
    _strictMode = false;
    _snoozeMinutes = 5;
    _warnAtPercent = 80;
    _overlayMode = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Limits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) {
          if (!_hydrated) {
            _hydrated = true;
            _settings = settings;
            _globalLimit = settings.globalLimit;
            _perAppLimits = Map.from(settings.perAppLimits);
            _blockingEnabled = settings.blockingEnabled;
            _strictMode = settings.strictMode;
            _snoozeMinutes = settings.snoozeMinutes;
            _warnAtPercent = settings.warnAtPercent;
            _overlayMode = settings.overlayMode;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Global limit
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Daily Global Limit',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _globalLimit.toDouble(),
                              min: 0,
                              max: 500,
                              divisions: 50,
                              label: _globalLimit == 0 ? 'Unlimited' : '$_globalLimit reels',
                              onChanged: (value) {
                                setState(() => _globalLimit = value.round());
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: _globalLimit.toString(),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                labelText: 'Reels',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onChanged: (value) {
                                final parsed = int.tryParse(value);
                                if (parsed != null && parsed >= 0 && parsed <= 500) {
                                  setState(() => _globalLimit = parsed);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      // Preset buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [0, 50, 100, 150, 200].map((preset) {
                          return FilterChip(
                            label: Text(preset == 0 ? 'Off' : '$preset'),
                            selected: _globalLimit == preset,
                            onSelected: (selected) {
                              if (selected) setState(() => _globalLimit = preset);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Per-app limits
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.apps_outlined, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Per-App Limits',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Override global limit for specific apps (0 = use global)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...appDisplayNames.entries.map((entry) {
                        final appId = entry.key;
                        final label = entry.value;
                        final color = appAccentColors[appId]!;
                        final limit = _perAppLimits[appId] ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  AppBrandIcon(appId: appId, size: 28),
                                  const SizedBox(width: 12),
                                  Text(label, style: theme.textTheme.bodyMedium),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Slider(
                                      value: limit.toDouble(),
                                      min: 0,
                                      max: 500,
                                      divisions: 50,
                                      activeColor: color,
                                      label: limit == 0 ? 'Global' : '$limit reels',
                                      onChanged: (value) {
                                        setState(() {
                                          _perAppLimits[appId] = value.round();
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 60,
                                    child: TextFormField(
                                      initialValue: limit.toString(),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                      onChanged: (value) {
                                        final parsed = int.tryParse(value);
                                        if (parsed != null && parsed >= 0 && parsed <= 500) {
                                          setState(() {
                                            _perAppLimits[appId] = parsed;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Blocking settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.block_outlined, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Blocking',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Block when limit reached'),
                        subtitle: const Text('Exit reels screen and show limit overlay'),
                        value: _blockingEnabled,
                        onChanged: (value) => setState(() => _blockingEnabled = value),
                        activeColor: colorScheme.primary,
                      ),
                      SwitchListTile(
                        title: const Text('Strict mode'),
                        subtitle: const Text('Cannot change limit until next day'),
                        value: _strictMode,
                        onChanged: (value) => setState(() => _strictMode = value),
                        activeColor: colorScheme.primary,
                      ),
                      SwitchListTile(
                        title: const Text('Allow snooze'),
                        subtitle: Text('Snooze for $_snoozeMinutes minutes when blocked'),
                        value: true,
                        onChanged: (value) {},
                        activeColor: colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Snooze duration: ', style: theme.textTheme.bodyMedium),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: _snoozeMinutes,
                            items: [1, 5, 10, 15, 30].map((m) {
                              return DropdownMenuItem(value: m, child: Text('$m min'));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) setState(() => _snoozeMinutes = value);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Warning settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_outlined, color: colorScheme.tertiary),
                          const SizedBox(width: 12),
                          Text(
                            'Warnings',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('Warn at: ', style: theme.textTheme.bodyMedium),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: _warnAtPercent,
                            items: [50, 60, 70, 80, 90].map((p) {
                              return DropdownMenuItem(value: p, child: Text('$p%'));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) setState(() => _warnAtPercent = value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Overlay mode'),
                        subtitle: const Text('Show overlay instead of full-screen block'),
                        value: _overlayMode,
                        onChanged: (value) => setState(() => _overlayMode = value),
                        activeColor: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Preview button
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final shown = await ref.read(scrollRepositoryProvider).previewBlockScreen();
                      if (!shown && mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Could not open the block screen')),
                        );
                      }
                    },
                    icon: const Icon(Icons.preview_outlined),
                    label: const Text('Preview Block Screen'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              FilledButton(
                onPressed: _saveSettings,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text('Save Settings'),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        error: (_, __) => Center(
          child: Text('Error loading settings', style: theme.textTheme.bodyMedium),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 2),
    );
  }

  Future<void> _saveSettings() async {
    final newSettings = Settings(
      globalLimit: _globalLimit,
      perAppLimits: _perAppLimits,
      trackedApps: _settings.trackedApps,
      blockingEnabled: _blockingEnabled,
      strictMode: _strictMode,
      snoozeMinutes: _snoozeMinutes,
      resetHour: _settings.resetHour,
      warnAtPercent: _warnAtPercent,
      overlayMode: _overlayMode,
      themeMode: _settings.themeMode,
      onboardingCompleted: _settings.onboardingCompleted,
    );

    final repository = ref.read(scrollRepositoryProvider);
    final success = await repository.updateSettings(newSettings);
    if (success) ref.invalidate(settingsProvider);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Settings saved')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Failed to save settings')),
      );
    }
  }
}

/// Bottom navigation bar
class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Icons.timer_outlined),
          selectedIcon: Icon(Icons.timer),
          label: 'Limits',
        ),
        NavigationDestination(
          icon: Icon(Icons.apps_outlined),
          selectedIcon: Icon(Icons.apps),
          label: 'Apps',
        ),
      ],
    );
  }
}