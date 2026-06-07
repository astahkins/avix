import 'package:flutter/material.dart';

import 'screens/email_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(const AvixApp());
}

class AvixApp extends StatelessWidget {
  const AvixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avix',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const EmailScreen(),
      },
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AvixColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AvixColors.accent,
          secondary: AvixColors.accent,
          surface: AvixColors.background,
          onPrimary: AvixColors.text,
          onSecondary: AvixColors.text,
          onSurface: AvixColors.text,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AvixColors.text),
          bodyMedium: TextStyle(color: AvixColors.text),
          bodySmall: TextStyle(color: AvixColors.text),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AvixColors.accent,
            foregroundColor: AvixColors.text,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
