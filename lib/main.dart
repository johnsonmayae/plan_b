// lib/main.dart
import 'package:flutter/material.dart';

import 'theme/theme_controller.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeController _theme = ThemeController();

  @override
  Widget build(BuildContext context) {
    return ThemeControllerScope(
      controller: _theme,
      child: AnimatedBuilder(
        animation: _theme,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Plan B',
            theme: _theme.lightTheme,
            darkTheme: _theme.darkTheme,
            themeMode: _theme.mode,
            home: const HomeScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/how-to-play') {
                return MaterialPageRoute<void>(
                  builder: (_) => const _HowToPlayPlaceholder(),
                  settings: settings,
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

class _HowToPlayPlaceholder extends StatelessWidget {
  const _HowToPlayPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('How to Play')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Hook your real How-To-Play screen to the /how-to-play route when ready.',
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}