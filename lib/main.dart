import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'screens/auth/auth_wrapper.dart';
import 'core/app_settings.dart';
import 'core/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<double>(
          valueListenable: AppSettings.fontScale,
          builder: (context, fontScale, _) {
            return ValueListenableBuilder<Locale>(
              valueListenable: AppSettings.locale,
              builder: (context, locale, _) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,

                  // 🌍 LANGUE
                  locale: locale,
                  supportedLocales: const [
                    Locale('fr'),
                    Locale('en'),
                  ],
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],

                  // 🌗 THÈMES
                  themeMode: themeMode,
                  theme: _lightTheme(),
                  darkTheme: _darkTheme(),

                  // 🔤 TAILLE TEXTE GLOBALE
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaleFactor: fontScale,
                      ),
                      child: child!,
                    );
                  },

                  home: const AuthWrapper(),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// ==================== THÈME CLAIR ====================
ThemeData _lightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF6F7FB),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}

/// ==================== THÈME SOMBRE ====================
ThemeData _darkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F14),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F0F14),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1A23),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}