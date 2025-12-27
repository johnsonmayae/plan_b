// lib/theme/theme_controller.dart
import 'package:flutter/material.dart';

import 'app_themes.dart';

enum ThemePreset { classic, wood, blackWhite }

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
        return AppThemes.light(AppThemeId.classic);
      case ThemePreset.wood:
        return AppThemes.light(AppThemeId.wood);
      case ThemePreset.blackWhite:
        return AppThemes.light(AppThemeId.bw);
    }
  }

  ThemeData get darkTheme {
    switch (preset) {
      case ThemePreset.classic:
        return AppThemes.dark(AppThemeId.classic);
      case ThemePreset.wood:
        return AppThemes.dark(AppThemeId.wood);
      case ThemePreset.blackWhite:
        return AppThemes.dark(AppThemeId.bw);
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

/// InheritedNotifier wrapper so any widget can read the theme controller.
class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    super.key,
    required ThemeController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeControllerScope>();
    assert(scope != null, 'ThemeControllerScope not found in widget tree');
    return scope!.notifier!;
  }
}