import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> ensureOnlineConsent(BuildContext context) async {
  final prefs = SharedPreferencesAsync();
  if (await prefs.getBool('onlineConsent.v2') == true) return true;
  if (!context.mounted) return false;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Çevrim içi oyuna katıl'),
      content: const Text(
        'Maçı eşleştirmek için rastgele bir oyuncu kimliği, davet, hamle, sonuç ve son bağlantı bilgileri Firebase üzerinde saklanır. Misafir maçlarında adın ve okulun paylaşılmaz. Serbest sohbet yoktur.\n\nİstersen e-posta ile kalıcı hesap açıp profil/okul seçimini yedekleyebilirsin. Ayrıca sıralamaya katılmayı seçersen takma adın, seçtiğin topluluk ve puanın diğer oyunculara görünür.\n\nVerilerini Güvenlik ve gizlilik ekranından silebilirsin.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: const Text('Katıl'),
        ),
      ],
    ),
  );
  if (accepted == true) await prefs.setBool('onlineConsent.v2', true);
  return accepted == true;
}
