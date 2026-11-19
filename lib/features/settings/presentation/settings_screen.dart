import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routing/menu_back.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_language.dart';
import '../../../app/app_services.dart';
import '../../../core/widgets/page_layout.dart';
import 'board_appearance_controls.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openUrl(BuildContext context, String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        showNotice(context, 'Sayfa açılamadı.');
      }
    } catch (_) {
      if (context.mounted) {
        showNotice(context, 'Bağlantı açılamadı.');
      }
    }
  }

  void _showLanguageSelector(BuildContext context) {
    final languageController = AppScope.of(context).language;
    final currentLang = languageController.current;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.language_rounded, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppStrings.get('language_section', currentLang.code),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(bottomContext).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: AppLanguage.values.length,
                    itemBuilder: (ctx, index) {
                      final lang = AppLanguage.values[index];
                      final isSelected = lang == currentLang;

                      return ListTile(
                        leading: Text(
                          lang.flag,
                          style: const TextStyle(fontSize: 26),
                        ),
                        title: Text(
                          lang.nativeName,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(lang.code.toUpperCase()),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: Colors.teal)
                            : null,
                        onTap: () async {
                          Navigator.of(bottomContext).pop();
                          await languageController.setLanguage(lang);
                          if (context.mounted) {
                            showNotice(
                              context,
                              AppStrings.get('saved', lang.code),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final theme = services.theme;
    final language = services.language;
    final langCode = language.current.code;

    return Scaffold(
      appBar: AppBar(
        leading: const MenuBackButton(),
        title: Text(AppStrings.get('settings_title', langCode)),
      ),
      body: PageLayout(
        eyebrow: AppStrings.get('settings_eyebrow', langCode),
        title: AppStrings.get('settings_title', langCode),
        subtitle: AppStrings.get('settings_subtitle', langCode),
        children: [
          // 1. DİL SEÇİM ALANI
          SectionTitle(AppStrings.get('language_section', langCode)),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      language.current.flag,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            language.current.nativeName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.get('language_desc', langCode),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.translate_rounded, size: 16),
                    label: Text(AppStrings.get('change', langCode)),
                    onPressed: () => _showLanguageSelector(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. GÖRÜNÜM VE TEMALAR
          SectionTitle(AppStrings.get('appearance_section', langCode)),
          Text(
            AppStrings.get('color_palette', langCode),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: theme,
            builder: (context, _) => Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                for (final palette in AppColorTheme.values)
                  ChoiceChip(
                    key: ValueKey('color-theme-${palette.name}'),
                    avatar: Icon(
                      Icons.circle,
                      color: palette == AppColorTheme.fresh
                          ? AppColors.turquoise
                          : AppColors.forest,
                      size: 18,
                    ),
                    label: Text(
                      palette == AppColorTheme.fresh
                          ? AppStrings.get('theme_fresh', langCode)
                          : AppStrings.get('theme_forest', langCode),
                    ),
                    selected: theme.colorTheme == palette,
                    onSelected: (_) async {
                      try {
                        await theme.setColorTheme(palette);
                      } catch (_) {
                        if (context.mounted) {
                          showNotice(
                            context,
                            AppStrings.get('saved', langCode),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.get('app_theme', langCode),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: theme,
            builder: (context, _) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final entry in {
                  ThemeMode.system: AppStrings.get('system', langCode),
                  ThemeMode.light: AppStrings.get('light', langCode),
                  ThemeMode.dark: AppStrings.get('dark', langCode),
                }.entries)
                  ChoiceChip(
                    key: ValueKey('theme-${entry.key.name}'),
                    label: Text(entry.value),
                    selected: theme.mode == entry.key,
                    onSelected: (_) async {
                      try {
                        await theme.setMode(entry.key);
                      } catch (_) {
                        if (context.mounted) {
                          showNotice(context, 'Tema tercihi kaydedilemedi.');
                        }
                      }
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. TAHTA VE TAŞ TASARIMI (3D WIZARD DAHİL)
          Text(
            AppStrings.get('board_and_pieces', langCode),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const BoardAppearanceControls(),
          const SizedBox(height: 12),

          // 4. RAHAT KULLANIM VE PERFORMANS
          if (services.comfort case final comfort?) ...[
            SectionTitle(AppStrings.get('comfort_section', langCode)),
            ListenableBuilder(
              listenable: comfort,
              builder: (context, _) => SurfaceCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppStrings.get('reduce_motion_title', langCode)),
                      subtitle: Text(
                        AppStrings.get('reduce_motion_subtitle', langCode),
                      ),
                      value: comfort.reducedMotion,
                      onChanged: (v) =>
                          comfort.setReducedMotion(v).catchError((Object _) {
                            if (context.mounted) {
                              showNotice(context, AppStrings.get('saved', langCode));
                            }
                          }),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppStrings.get('light_board_title', langCode)),
                      subtitle: Text(
                        AppStrings.get('light_board_subtitle', langCode),
                      ),
                      value: comfort.lightBoard,
                      onChanged: (v) =>
                          comfort.setLightBoard(v).catchError((Object _) {
                            if (context.mounted) {
                              showNotice(context, AppStrings.get('saved', langCode));
                            }
                          }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // BİLDİRİMLER (GÜNLÜK OYUN HATIRLATICISI)
          if (services.dailyReminder case final reminder?) ...[
            SectionTitle(AppStrings.get('notifications_section', langCode)),
            ListenableBuilder(
              listenable: reminder,
              builder: (context, _) => SurfaceCard(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: Text(AppStrings.get('daily_reminder_title', langCode)),
                  subtitle: Text(AppStrings.get('daily_reminder_desc', langCode)),
                  value: reminder.isDailyReminderEnabled,
                  onChanged: (v) =>
                      reminder.setDailyReminder(v).catchError((Object _) {
                        if (context.mounted) {
                          showNotice(context, AppStrings.get('saved', langCode));
                        }
                      }),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 5. HESAP VE SIRALAMA BİLGİLERİ
          SectionTitle(AppStrings.get('account_section', langCode)),
          SurfaceCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.manage_accounts_outlined),
              title: Text(AppStrings.get('account_section', langCode)),
              subtitle: Text(AppStrings.get('account_desc', langCode)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/account'),
            ),
          ),
          const SizedBox(height: 12),

          // 6. YASAL BİLGİLER, GİZLİLİK VE GÜVENLİK
          SectionTitle(AppStrings.get('legal_section', langCode)),
          SurfaceCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.security_rounded),
                  title: Text(AppStrings.get('child_safety', langCode)),
                  subtitle: Text(AppStrings.get('child_safety_desc', langCode)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/safety'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(AppStrings.get('privacy_policy', langCode)),
                  subtitle: Text(AppStrings.get('privacy_policy_desc', langCode)),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                  onTap: () => _openUrl(
                    context,
                    'https://satranc-platformu.web.app/privacy',
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.gavel_outlined),
                  title: Text(AppStrings.get('terms_of_service', langCode)),
                  subtitle: Text(AppStrings.get('terms_of_service_desc', langCode)),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                  onTap: () => _openUrl(
                    context,
                    'https://satranc-platformu.web.app/terms',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 7. UYGULAMA HAKKINDA VE SÜRÜM BİLGİSİ
          SectionTitle(AppStrings.get('about_app', langCode)),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(Icons.shield_outlined, color: Colors.teal),
                    Text(
                      AppStrings.get('app_name_full', langCode),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppStrings.get('app_version', langCode),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  AppStrings.get('about_desc', langCode),
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
