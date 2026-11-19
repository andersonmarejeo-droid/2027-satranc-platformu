import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '../../challenges/domain/online_challenge_repository.dart';

import '../../../core/routing/menu_back.dart';

import '../../../app/app_services.dart';
import '../../../core/widgets/page_layout.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});
  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final online = services.challenges;
    return Scaffold(
      appBar: AppBar(
        leading: const MenuBackButton(),
        title: const Text('Güvenlik ve gizlilik'),
      ),
      body: ListenableBuilder(
        listenable: services.account ?? services.theme,
        builder: (context, _) => PageLayout(
          eyebrow: 'Saygı oyunun parçası',
          title: 'Kontrol sende kalsın.',
          subtitle: 'Gizlilik tercihlerin güvenli varsayılanlarla başlar.',
          children: [
            SurfaceCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Gizlilik politikası'),
                subtitle: const Text(
                  'Yerel kayıtlar ve çevrim içi maç verileri',
                ),
                trailing: const Icon(Icons.open_in_new),
                onTap: () async {
                  final opened = await launchUrl(
                    Uri.parse('https://satranc-platformu.web.app/privacy'),
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gizlilik sayfası açılamadı.'),
                      ),
                    );
                  }
                },
              ),
            ),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    online is OnlineChallengeRepository
                        ? 'Güvenli çevrim içi oyun'
                        : 'Şimdilik çevrim dışı',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    online is OnlineChallengeRepository
                        ? 'Çevrim içi oyun 13 yaş ve üzeri içindir. Misafir olarak adını ve okulunu paylaşmadan oynayabilirsin. E-posta hesabı isteğe bağlıdır; profilini ve okul seçimini yedekler. Sıralamaya ayrıca katılmayı seçersen takma adın, seçtiğin topluluk ve maçlardan kazandığın puan görünür. Yalnız hazır kısa mesajlar gönderilir; serbest sohbet yoktur.'
                        : 'İnternetsiz oyunların ve profil seçimlerin bu cihazda saklanır. Çevrim içi oyun kullanılamadığında yeni maç ve sıralama verileri gönderilmez.',
                  ),
                ],
              ),
            ),
            if (services.account != null)
              SurfaceCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: const Text('Hesabım ve sıralama tercihim'),
                  subtitle: const Text(
                    'Sıralamaya katıl veya herkese açık puanlarını kaldır.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/account'),
                ),
              ),
            const SizedBox(height: 20),
            const SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Topluluk ilkeleri',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Rakibine saygı duy. Kişisel bilgilerini herkese açık alanlarda paylaşma. Oyun sırasında dış yardım kullanma.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (online is OnlineChallengeRepository)
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: Text(
                  _deleting
                      ? 'Veriler siliniyor…'
                      : 'Çevrim içi verilerimi sil',
                ),
                onPressed: _deleting
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text(
                              'Çevrim içi verilerin silinsin mi?',
                            ),
                            content: const Text(
                              'Hesabın, profil yedeğin, sıralama puanların, okul bildirimlerin, davetlerin ve çevrim içi maçların silinir. Rakibin de silinen maçlara dönemez. Bu işlem geri alınamaz. Yerel oyunların bu cihazda korunur.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Vazgeç'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Verilerimi sil'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        if (!context.mounted) return;
                        final account = AppScope.of(context).account;
                        final user = account?.auth.currentUser;
                        final signedAt = user?.metadata.lastSignInTime;
                        if (user != null &&
                            !user.isAnonymous &&
                            (signedAt == null ||
                                DateTime.now().difference(signedAt).inMinutes >=
                                    5)) {
                          final secret = await showDialog<String>(
                            context: context,
                            builder: (c) =>
                                const _DeleteAccountPasswordDialog(),
                          );
                          if (secret == null ||
                              !await account!.reauthenticate(secret)) {
                            if (context.mounted && secret != null) {
                              showNotice(
                                context,
                                account?.error ?? 'Şifre doğrulanamadı.',
                              );
                            }
                            return;
                          }
                        }
                        if (!context.mounted) return;
                        setState(() => _deleting = true);
                        try {
                          await online.deleteOnlineData();
                          await SharedPreferencesAsync().remove(
                            'onlineConsent.v1',
                          );
                          await SharedPreferencesAsync().remove(
                            'onlineConsent.v2',
                          );
                          if (context.mounted) {
                            showNotice(
                              context,
                              'Çevrim içi verilerin silindi.',
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            showNotice(
                              context,
                              'Silme tamamlanamadı. İnternet bağlantınla yeniden dene.',
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _deleting = false);
                        }
                      },
              )
            else
              const Text(
                'Bu ekrandaki tercihler tek başına hesap veya izin oluşturmaz.',
              ),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountPasswordDialog extends StatefulWidget {
  const _DeleteAccountPasswordDialog();
  @override
  State<_DeleteAccountPasswordDialog> createState() =>
      _DeleteAccountPasswordDialogState();
}

class _DeleteAccountPasswordDialogState
    extends State<_DeleteAccountPasswordDialog> {
  final _password = TextEditingController();
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Hesabını doğrula'),
    content: TextField(
      controller: _password,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      decoration: const InputDecoration(
        labelText: 'Şifre',
        helperText: 'Hesap silme için yeniden giriş gerekir.',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Vazgeç'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _password.text),
        child: const Text('Doğrula'),
      ),
    ],
  );
}
