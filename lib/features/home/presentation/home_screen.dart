import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/widgets/page_layout.dart';
import '../../../app/app_services.dart';
import '../../game/presentation/quick_play.dart';
import '../../game/presentation/quick_play_controller.dart';
import '../../game/domain/time_control.dart';
import '../../settings/domain/board_appearance.dart';
import 'player_identity_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _shareWhatsAppChallenge(BuildContext context) async {
    try {
      final challenges = AppScope.of(context).challenges;
      final quickChoice = AppScope.of(context).quickPlay?.value;
      final time = quickChoice?.time ?? const TimeControl(10, 0);
      final invite = await challenges.create(time);
      if (!context.mounted) return;
      final opened = await AppScope.of(context).whatsApp.openComposer(invite);
      if (!context.mounted) return;
      if (!opened) {
        showNotice(context, 'WhatsApp açılamadı. Davet bağlantısı kopyalandı.');
        await Clipboard.setData(ClipboardData(text: invite.shareLink.toString()));
      }
    } catch (_) {
      if (context.mounted) {
        context.push('/challenges');
      }
    }
  }

  void _start3DArena(BuildContext context) {
    AppScope.of(context).boardAppearance.update(view: BoardViewMode.wizard3d);
    startQuickPlay(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final quickChoice = AppScope.of(context).quickPlay?.value ?? const QuickPlayChoice();
    final langService = AppScope.of(context).language;

    return ListenableBuilder(
      listenable: langService,
      builder: (context, _) {
        final langCode = langService.current.code;

        return PageLayout(
          eyebrow: AppStrings.get('app_name_full', langCode),
          title: AppStrings.get('home_title', langCode),
          trailing: IconButton(
            tooltip: AppStrings.get('settings_title', langCode),
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_rounded),
          ),
          children: [
            // 1. SATIR: İki Eşit Boyutta Ana Eylem Kartı (Hemen Oyna & WhatsApp Meydan Oku)
            Row(
              children: [
                Expanded(
                  child: _PrimaryActionCard(
                    key: const ValueKey('home-quick-play'),
                    title: AppStrings.get('play_now', langCode),
                    subtitle: quickChoice.description,
                    icon: Icons.play_arrow_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF163E2E), Color(0xFF28654B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    accentColor: const Color(0xFFD8F3DC),
                    onTap: () => startQuickPlay(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PrimaryActionCard(
                    key: const ValueKey('home-whatsapp-challenge'),
                    title: AppStrings.get('challenge', langCode),
                    subtitle: AppStrings.get('challenge_whatsapp', langCode),
                    icon: Icons.chat_bubble_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F7A4A), Color(0xFF25D366)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    accentColor: Colors.white,
                    onTap: () => _shareWhatsAppChallenge(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. SATIR: İki Eşit Boyutta İkincil Eylem Kartı (3D Büyücü Arenası & Yapay Zeka Botları)
            Row(
              children: [
                Expanded(
                  child: _PrimaryActionCard(
                    key: const ValueKey('home-wizard-3d'),
                    title: AppStrings.get('arena_3d', langCode),
                    subtitle: AppStrings.get('wizard_chess', langCode),
                    icon: Icons.view_in_ar_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B1F3B), Color(0xFF333A6B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    accentColor: const Color(0xFFC7D2FE),
                    onTap: () => _start3DArena(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PrimaryActionCard(
                    key: const ValueKey('home-play-modes'),
                    title: AppStrings.get('ai_bots', langCode),
                    subtitle: AppStrings.get('ai_bots_desc', langCode),
                    icon: Icons.smart_toy_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5A2A18), Color(0xFF8B4526)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    accentColor: const Color(0xFFFFD8CC),
                    onTap: () => context.go('/play'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Aktif Hızlı Oyun Modu ve Değiştirme Şeridi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${AppStrings.get('active_mode', langCode)} ${quickChoice.description}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    onPressed: () => context.go('/play'),
                    child: Text(AppStrings.get('change', langCode), style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Sporcu Kimlik Kartı & Oyun İçi Sıralama / Okul Rozeti
            const PlayerIdentityCard(),
          ],
        );
      },
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 108),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            splashColor: accentColor.withValues(alpha: 0.2),
            highlightColor: accentColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
