import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_services.dart';
import '../../../core/localization/app_language.dart';
import '../../profile/domain/community_membership.dart';

/// Ana sayfada yer alan, resmi sporcu lisansı ve satranç pasaportu görünümündeki
/// interaktif Oyuncu Kimlik Kartı.
class PlayerIdentityCard extends StatelessWidget {
  const PlayerIdentityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final profileCtrl = services.profile;
    final membershipCtrl = services.membership;

    return ListenableBuilder(
      listenable: Listenable.merge([profileCtrl, membershipCtrl, services.language]),
      builder: (context, _) {
        final profile = profileCtrl.profile;
        final membership = membershipCtrl.value;
        final langCode = services.language.current.code;

        final displayName = (profile?.displayName.trim().isNotEmpty ?? false)
            ? profile!.displayName.trim()
            : AppStrings.get('id_card_default_name', langCode);

        final rawId = profile?.installId ?? 'CHESS2026';
        final cleanId = rawId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
        final licenseCode = cleanId.length >= 6
            ? cleanId.substring(0, 6)
            : cleanId.padRight(6, 'X');

        final schoolName = CommunityDirectory.find(membership.schoolId)?.name;
        final className = CommunityDirectory.find(membership.classId)?.name;
        final cityName = CommunityDirectory.find(membership.cityId)?.name;

        final hasSchool = schoolName != null && schoolName.isNotEmpty;
        final schoolDisplay = hasSchool
            ? (className != null ? '$schoolName · $className' : schoolName)
            : AppStrings.get('id_card_no_school', langCode);

        final locationDisplay = cityName ?? AppStrings.get('id_card_global', langCode);

        return Semantics(
          label: 'Oyuncu Kimlik Kartı: $displayName, $schoolDisplay',
          button: true,
          child: Container(
            margin: const EdgeInsets.only(top: 4, bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D1B2A).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.08),
                  blurRadius: 6,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F1E28),
                      Color(0xFF162D3B),
                      Color(0xFF1B3B4B),
                      Color(0xFF102830),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.40),
                    width: 1.4,
                  ),
                ),
                child: InkWell(
                  onTap: () => context.push('/profile'),
                  splashColor: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  highlightColor: Colors.white.withValues(alpha: 0.05),
                  child: Stack(
                    children: [
                      // Arka Plan Filigranı (Hafif Şeffaf Büyük Satranç Figürü)
                      Positioned(
                        right: -16,
                        bottom: -18,
                        child: IgnorePointer(
                          child: Icon(
                            Icons.shield_outlined,
                            size: 140,
                            color: Colors.white.withValues(alpha: 0.035),
                          ),
                        ),
                      ),

                      // Kart İçeriği
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. ÜST ŞERİT: Logo / Başlık & Çip / Lisans Rozeti
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 15,
                                    color: Color(0xFFFFDF79),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        AppStrings.get('id_card_platform_title', langCode),
                                        style: const TextStyle(
                                          color: Color(0xFFFFE082),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.9,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        AppStrings.get('id_card_subtitle', langCode),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.4,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Altın Akıllı Kart Çipi
                                Container(
                                  width: 26,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFE082), Color(0xFFB8860B)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFFFFF8DC),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: CustomPaint(
                                    painter: _SimChipLinesPainter(),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // 2. ORTA BÖLÜM: Fotoğraf/Avatar Kutucuğu & Kişisel / Okul Bilgileri
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Fotoğraf / Avatar Kutusu
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 62,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0B161E),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.35),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          const Icon(
                                            Icons.person_rounded,
                                            size: 42,
                                            color: Color(0xFFC4D5E0),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Icon(
                                              Icons.star_rounded,
                                              size: 13,
                                              color: const Color(0xFFFFD54F).withValues(alpha: 0.9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1B4D3E),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: const Color(0xFF4EBA88),
                                          width: 0.6,
                                        ),
                                      ),
                                      child: const Text(
                                        'LİSANSLI',
                                        style: TextStyle(
                                          color: Color(0xFFD8F3DC),
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 14),

                                // Kişisel Bilgiler & Okul Detayı
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Oyuncu Adı
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),

                                      // Lisans Numarası & Unvan
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 2,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            'TR-$licenseCode',
                                            style: TextStyle(
                                              color: const Color(0xFFFFDF79).withValues(alpha: 0.9),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                          Container(
                                            width: 3,
                                            height: 3,
                                            decoration: const BoxDecoration(
                                              color: Colors.white54,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const Text(
                                            'Aday Usta',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      // Okul & Bölge Satırı
                                      InkWell(
                                        onTap: () => context.push('/registration'),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.school_outlined,
                                                size: 14,
                                                color: hasSchool
                                                    ? const Color(0xFF81D4FA)
                                                    : const Color(0xFFFFAB91),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  schoolDisplay,
                                                  style: TextStyle(
                                                    color: hasSchool
                                                        ? Colors.white.withValues(alpha: 0.92)
                                                        : const Color(0xFFFFCCBC),
                                                    fontSize: 11,
                                                    fontWeight: hasSchool
                                                        ? FontWeight.w600
                                                        : FontWeight.w500,
                                                    decoration: hasSchool
                                                        ? null
                                                        : TextDecoration.underline,
                                                    decorationColor: const Color(0xFFFFCCBC),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.chevron_right_rounded,
                                                size: 15,
                                                color: Colors.white54,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Şehir / Konum Bilgisi
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 13,
                                            color: Colors.white54,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            locationDisplay,
                                            style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // 3. ALT BÖLÜM: Sıralama & ELO Puan Göstergeleri
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _RankingMetricItem(
                                      icon: Icons.bolt_rounded,
                                      iconColor: const Color(0xFFFFD54F),
                                      label: 'ELO PUANI',
                                      value: '1420',
                                      accentColor: const Color(0xFFFFDF79),
                                      onTap: () => context.go('/leaderboard'),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 28,
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                  Expanded(
                                    child: _RankingMetricItem(
                                      icon: Icons.apartment_rounded,
                                      iconColor: const Color(0xFF81D4FA),
                                      label: 'OKUL SIRASI',
                                      value: hasSchool ? '#2' : '-',
                                      accentColor: Colors.white,
                                      onTap: () => context.go('/leaderboard'),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 28,
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                  Expanded(
                                    child: _RankingMetricItem(
                                      icon: Icons.emoji_events_outlined,
                                      iconColor: const Color(0xFFFF8A80),
                                      label: 'İL DERECESİ',
                                      value: '#14',
                                      accentColor: Colors.white,
                                      onTap: () => context.go('/leaderboard'),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // 4. MİKRO BARKOD & FEDERASYON DAMGASI
                            Row(
                              children: [
                                CustomPaint(
                                  size: const Size(64, 12),
                                  painter: _BarcodePainter(),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'DİJİTAL SPORCU LİSANSI · 2026',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.6,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.touch_app_outlined,
                                  size: 12,
                                  color: Color(0xFFFFDF79),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Profili Aç',
                                  style: TextStyle(
                                    color: Color(0xFFFFDF79),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RankingMetricItem extends StatelessWidget {
  const _RankingMetricItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 12, color: iconColor),
                  const SizedBox(width: 3),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Akıllı Çip Üzerindeki İnce İletken Çizgileri Çizen Ressam
class _SimChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6B4E00).withValues(alpha: 0.65)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Yatay orta hat
    canvas.drawLine(Offset(0, h * 0.5), Offset(w, h * 0.5), paint);
    // Sol dikey hat
    canvas.drawLine(Offset(w * 0.35, 0), Offset(w * 0.35, h), paint);
    // Sağ dikey hat
    canvas.drawLine(Offset(w * 0.65, 0), Offset(w * 0.65, h), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Kimlik Kartı Altındaki Güvenlik Barkod Çizgilerini Çizen Ressam
class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final widths = [1.5, 0.8, 2.0, 1.0, 0.8, 1.8, 2.5, 1.0, 0.8, 2.0, 1.2, 0.8, 2.2];
    double currentX = 0;

    for (int i = 0; i < widths.length && currentX < size.width; i++) {
      final barWidth = widths[i];
      if (i % 2 == 0) {
        canvas.drawRect(
          Rect.fromLTWH(currentX, 0, barWidth, size.height),
          paint,
        );
      }
      currentX += barWidth + 1.8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
