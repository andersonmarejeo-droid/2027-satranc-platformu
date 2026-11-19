import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_services.dart';
import '../../../core/widgets/page_layout.dart';
import '../domain/guest_profile.dart';
import 'profile_controller.dart';
import 'my_community_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = AppScope.of(context).profile;
    return ListenableBuilder(
      listenable: profile,
      builder: (context, _) {
        final displayName = profile.profile?.displayName ?? 'Misafir oyuncu';
        return PageLayout(
          eyebrow: 'Oyunun sana ait',
          title: 'Senin yolculuğun.',
          children: [
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primary
                        .withValues(alpha: .1),
                    child: Icon(
                      Icons.person_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          key: const ValueKey('profile-display-name'),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        Text(
                          AppScope.of(context).account?.permanent == true
                              ? 'Kalıcı hesap · Profil yedeklenir'
                              : 'Misafir · Bu cihazda kayıtlı',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('edit-profile-name'),
                    tooltip: 'Görünen adı düzenle',
                    onPressed: profile.isSaving
                        ? null
                        : () => _editDisplayName(context, profile),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const MyCommunityCard(),
            const SizedBox(height: 8),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  if (AppScope.of(context).account != null) ...[
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.cloud_done_outlined, size: 20),
                      title: const Text('Hesabım'),
                      subtitle: const Text('Profil yedeği ve sıralamaya katılım'),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => context.push('/account'),
                    ),
                    const Divider(height: 1),
                  ],
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.history, size: 20),
                    title: const Text('Maç geçmişi'),
                    subtitle: const Text('Bu cihazda kaydettiğin yerel oyunlar'),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => context.push('/history'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.contrast_outlined, size: 20),
                    title: const Text('Görünüm ve tema'),
                    subtitle: const Text('Açık, koyu veya cihaz teması'),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => context.push('/settings'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.shield_outlined, size: 20),
                    title: const Text('Güvenlik ve gizlilik'),
                    subtitle: const Text('Profil ve davet tercihleri'),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => context.push('/safety'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editDisplayName(
    BuildContext context,
    ProfileController profile,
  ) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(
        initialName: profile.profile?.displayName ?? '',
      ),
    );

    if (value == null) return;
    try {
      await profile.saveDisplayName(value);
      if (context.mounted) showNotice(context, 'Görünen adın kaydedildi.');
    } catch (_) {
      if (context.mounted) {
        showNotice(context, 'Ad kaydedilemedi. Biraz sonra yeniden dene.');
      }
    }
  }
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initialName});
  final String initialName;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Görünen adın'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: 24,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Ad',
            hintText: 'Örneğin: Deniz',
          ),
          validator: (value) => GuestProfile.displayNameError(value ?? ''),
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
