import 'package:flutter/material.dart';
import '../../core/app_settings.dart';
import '../../core/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.t('settings')),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle(context, t.t('appearance')),

          // 🌗 MODE SOMBRE
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppSettings.themeMode,
            builder: (context, mode, _) {
              return _card(
                context,
                child: SwitchListTile(
                  value: mode == ThemeMode.dark,
                  onChanged: (value) {
                    AppSettings.themeMode.value =
                        value ? ThemeMode.dark : ThemeMode.light;
                  },
                  secondary: const Icon(Icons.dark_mode_rounded),
                  title: Text(t.t('dark_mode')),
                  subtitle: Text(t.t('dark_mode_desc')),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          _sectionTitle(context, t.t('text_size')),

          // 🔤 TAILLE TEXTE
          ValueListenableBuilder<double>(
            valueListenable: AppSettings.fontScale,
            builder: (context, scale, _) {
              return _card(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.t('text_size')),
                    Slider(
                      value: scale,
                      min: 0.8,
                      max: 1.4,
                      divisions: 6,
                      label: scale.toStringAsFixed(1),
                      onChanged: (value) {
                        AppSettings.fontScale.value = value;
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          _sectionTitle(context, t.t('language')),

          // 🌍 LANGUE
          ValueListenableBuilder<Locale>(
            valueListenable: AppSettings.locale,
            builder: (context, locale, _) {
              return _card(
                context,
                child: Column(
                  children: [
                    RadioListTile<Locale>(
                      value: const Locale('fr'),
                      groupValue: locale,
                      onChanged: (value) {
                        AppSettings.locale.value = value!;
                      },
                      title: Text(t.t('french')),
                    ),
                    RadioListTile<Locale>(
                      value: const Locale('en'),
                      groupValue: locale,
                      onChanged: (value) {
                        AppSettings.locale.value = value!;
                      },
                      title: Text(t.t('english')),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          _sectionTitle(context, t.t('security')),

          _card(
            context,
            child: ListTile(
              leading: const Icon(Icons.lock),
              title: Text(t.t('change_password')),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),

          const SizedBox(height: 24),
          _sectionTitle(context, t.t('about')),

          _card(
            context,
            child: const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('EduLearn'),
              subtitle: Text('Version 1.0'),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== HELPERS =====================

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: Colors.white12)
            : null,
      ),
      child: child,
    );
  }
}