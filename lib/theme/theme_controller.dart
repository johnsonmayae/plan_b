import 'package:flutter/material.dart';

import 'app_themes.dart';

/// Theme presets.
///
/// - classic: your original/legacy color theme
/// - wood: warm wood look
/// - blackWhite: monochrome look
enum ThemePreset {
  classic,
  wood,
  blackWhite,
}

/// Simple controller so you can switch themes without third-party state mgmt.
class ThemeController extends ChangeNotifier {
  ThemePreset preset;
  ThemeMode mode;

  ThemeController({
    this.preset = ThemePreset.classic,
    this.mode = ThemeMode.system,
  });

  ThemeData get lightTheme {
    switch (preset) {
      case ThemePreset.classic:
        return AppThemes.classicLight;
      case ThemePreset.wood:
        return AppThemes.woodLight;
      case ThemePreset.blackWhite:
        return AppThemes.bwLight;
    }
  }

  ThemeData get darkTheme {
    switch (preset) {
      case ThemePreset.classic:
        return AppThemes.classicDark;
      case ThemePreset.wood:
        return AppThemes.woodDark;
      case ThemePreset.blackWhite:
        return AppThemes.bwDark;
    }
  }

  void setPreset(ThemePreset next) {
    if (preset == next) return;
    preset = next;
    notifyListeners();
  }

  void setMode(ThemeMode next) {
    if (mode == next) return;
    mode = next;
    notifyListeners();
  }
}

/// InheritedNotifier wrapper so any screen can do:
/// `final ctrl = ThemeControllerScope.of(context);`
class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ThemeControllerScope>();
    assert(scope != null, 'ThemeControllerScope not found in widget tree.');
    return scope!.notifier!;
  }
}