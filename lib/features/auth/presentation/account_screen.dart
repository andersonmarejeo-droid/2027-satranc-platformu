import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_services.dart';
import '../../../core/routing/menu_back.dart';
import '../../../core/widgets/page_layout.dart';
import '../../profile/domain/community_membership.dart';

/// Oyuncunun sadece Ad-Soyad ve Şehir/Okul bilgisini girerek
/// resmi lisansını oluşturduğu tamamen sadeleştirilmiş kayıt ekranı.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _name = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final currentName =
          AppScope.of(context).profile.profile?.displayName ?? '';
      if (currentName.isNotEmpty && currentName != 'Misafir oyuncu') {
        _name.text = currentName;
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final rawName = _name.text.trim();
    if (rawName.isEmpty) {
      showNotice(context, 'Lütfen adını ve soyadını yaz.');
      return;
    }
    setState(() => _saving = true);
    try {
      await AppScope.of(context, listen: false).profile.saveDisplayName(rawName);
      if (mounted) {
        showNotice(context, 'Oyuncu lisansın başarıyla kaydedildi!');
        if (context.canPop()) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        showNotice(context, 'Kayıt sırasında hata oluştu: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final profile = services.profile;
    final membership = services.membership.value;

    final schoolName = CommunityDirectory.find(membership.schoolId)?.name;
    final cityName = CommunityDirectory.find(membership.cityId)?.name;
    final communitySummary = [
      if (cityName != null && cityName.isNotEmpty) cityName,
      if (schoolName != null && schoolName.isNotEmpty) schoolName,
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(
        leading: const MenuBackButton(),
        title: const Text('Oyuncu Kaydı'),
      ),
      body: ListenableBuilder(
        listenable: profile,
        builder: (context, _) => PageLayout(
          eyebrow: 'Satranç Platformu',
          title: 'Oyuncu Kaydı',
          subtitle:
              'Adını ve soyadını yazman yeterli; lisans kartın hemen hazır olsun.',
          children: [
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.badge_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lisans Bilgilerin',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Kartında görünecek ad ve soyad',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 1. AD VE SOYAD
                  TextField(
                    controller: _name,
                    autofillHints: const [AutofillHints.name],
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Adın ve Soyadın',
                      hintText: 'Örn: Ahmet Yılmaz',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. ŞEHİR VE OKUL
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Şehir ve Okul',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                communitySummary.isEmpty
                                    ? 'Seçilmedi (İsteğe bağlı)'
                                    : communitySummary,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () => context.push('/community'),
                          child: const Text('Seç / Değiştir', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 3. KAYDET VE BAŞLA BUTONU
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, size: 20),
                      label: Text(
                        _saving ? 'Kaydediliyor…' : 'Kaydet ve Lisansımı Oluştur',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saving ? null : _save,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
