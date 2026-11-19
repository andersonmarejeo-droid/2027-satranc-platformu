import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../app/app_services.dart';
import '../../../core/routing/menu_back.dart';
import '../../../core/widgets/page_layout.dart';
import '../../profile/domain/community_membership.dart';
import 'community_picker.dart';

class SchoolFeedbackScreen extends StatefulWidget {
  const SchoolFeedbackScreen({super.key});
  @override
  State<SchoolFeedbackScreen> createState() => _SchoolFeedbackScreenState();
}

class _SchoolFeedbackScreenState extends State<SchoolFeedbackScreen> {
  final _name = TextEditingController(), _district = TextEditingController();
  String? _city;
  bool _busy = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _city ??= AppScope.of(context).membership.value.cityId;
  }

  @override
  void dispose() {
    _name.dispose();
    _district.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_city == null || _name.text.trim().length < 3) {
      showNotice(context, 'Şehri seç ve okul adını yaz.');
      return;
    }
    setState(() => _busy = true);
    final account = AppScope.of(context).account;
    final id = List.generate(
      16,
      (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final data = {
      'id': id,
      'cityId': _city!,
      'district': _district.text.trim(),
      'schoolName': _name.text.trim(),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    try {
      final prefs = SharedPreferencesAsync();
      final rows = jsonDecode(
        await prefs.getString('schoolSuggestions.v1') ?? '[]',
      ) as List;
      await prefs.setString(
        'schoolSuggestions.v1',
        jsonEncode([data, ...rows].take(20).toList()),
      );
      if (account?.permanent == true) {
        await account!.db
            .collection('schoolSuggestions')
            .doc('${account.auth.currentUser!.uid}_$id')
            .set({
              'uid': account.auth.currentUser!.uid,
              'cityId': _city!,
              'district': _district.text.trim(),
              'schoolName': _name.text.trim(),
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
      if (mounted) {
        showNotice(
          context,
          account?.permanent == true
              ? 'İstek kaydedildi. Listeye eklenmeden önce incelenmesi gerekir.'
              : 'İstek bu cihazda saklandı. Bildirmek için hesabına giriş yapıp yeniden kaydet.',
        );
      }
    } catch (_) {
      if (mounted) {
        showNotice(
          context,
          'Cihazdaki istek korundu; çevrim içi bildirim tamamlanamadı. Yeniden dene.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const MenuBackButton(),
      title: const Text('Okul bilgisi'),
    ),
    body: PageLayout(
      eyebrow: 'Listeyi iyileştir',
      title: 'Okulunu bulamadın mı?',
      children: [
        SurfaceCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  CommunityDirectory.find(_city)?.name ?? 'Şehir seç',
                ),
                trailing: const Icon(Icons.expand_more),
                onTap: _busy
                    ? null
                    : () async {
                        final id = await showCommunityPicker(
                          context,
                          kind: CommunityKind.city,
                          parentId: 'tr',
                          selectedId: _city,
                        );
                        if (mounted && id != null && id.isNotEmpty) {
                          setState(() => _city = id);
                        }
                      },
              ),
              TextField(
                controller: _district,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'İlçe (isteğe bağlı)',
                ),
              ),
              TextField(
                controller: _name,
                maxLength: 160,
                decoration: const InputDecoration(labelText: 'Okulun tam adı'),
              ),
              const Text(
                'Yalnızca okul ve ilçe bilgisini yaz. Öğrenci adı, telefon veya adres ekleme.',
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(
                  _busy
                      ? 'Kaydediliyor…'
                      : AppScope.of(context).account?.permanent == true
                      ? 'Kaydet ve bildir'
                      : 'Cihazda kaydet',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
