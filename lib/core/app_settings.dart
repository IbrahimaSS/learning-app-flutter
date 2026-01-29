import 'package:flutter/material.dart';

class AppSettings {
  // Thème
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.light);

  // Taille du texte
  static final ValueNotifier<double> fontScale =
      ValueNotifier(1.0);

  // Langue
  static final ValueNotifier<Locale> locale =
      ValueNotifier(const Locale('fr'));
}
