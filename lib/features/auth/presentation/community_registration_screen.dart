import 'package:flutter/material.dart';

import '../../../core/routing/menu_back.dart';
import '../../../app/app_services.dart';
import '../../../core/widgets/page_layout.dart';
import '../../profile/domain/community_membership.dart';
import '../../schools/presentation/community_picker.dart';
import '../../groups/domain/small_team_membership_repository.dart';

import 'package:go_router/go_router.dart';

class CommunityRegistrationScreen extends StatefulWidget {
  const CommunityRegistrationScreen({super.key, this.initialKind});
  final CommunityKind? initialKind;
  @override
  State<CommunityRegistrationScreen> createState() =>
      _CommunityRegistrationScreenState();
}

class _CommunityRegistrationScreenState
    extends State<CommunityRegistrationScreen> {
  CommunityMembership? _selection;
  bool _saving = false;
  bool _openedInitial = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selection ??= AppScope.of(context).membership.value;
    if (!_selection!.hasCountry) {
      _selection = _selection!.select(CommunityKind.country, 'tr');
    }
    if (!_openedInitial && widget.initialKind != null) {
      _openedInitial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final kind = widget.initialKind!;
        if (kind == CommunityKind.school && _selection!.cityId == null) return;
        if (kind == CommunityKind.classroom && _selection!.schoolId == null) {
          return;
        }
        _pick(kind);
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AppScope.of(context).membership.save(_selection!);
      if (mounted) {
        showNotice(context, 'Seçimlerin kaydedildi.');
        Navigator.pop(context);
      }
    } on TeamCapacityFailure catch (e) {
      if (mounted) showNotice(context, e.message);
    } catch (_) {
      if (mounted) {
        showNotice(context, 'Seçimlerin kaydedilemedi. Yeniden dene.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pick(CommunityKind kind) async {
    final value = _selection!;
    final (parent, selected) = switch (kind) {
      CommunityKind.country => (null, value.countryId),
      CommunityKind.city => (value.countryId, value.cityId),
      CommunityKind.school => (value.cityId, value.schoolId),
      _ => (value.schoolId, value.classId),
    };
    final result = kind == CommunityKind.classroom
        ? await showClassroomPicker(
            context,
            schoolId: parent!,
            selectedId: selected,
          )
        : await showCommunityPicker(
            context,
            kind: kind,
            parentId: parent,
            selectedId: selected,
          );
    if (!mounted || result == null) return;
    setState(
      () =>
          _selection = _selection!.select(kind, result.isEmpty ? null : result),
    );
    if (widget.initialKind == null && result.isNotEmpty && result != selected) {
      if (kind == CommunityKind.city) await _pick(CommunityKind.school);
      if (kind == CommunityKind.school) await _pick(CommunityKind.classroom);
    }
  }

  Widget _row(
    String label,
    String hint,
    CommunityKind kind,
    String? parent,
    String? selected,
    IconData icon,
  ) => ListTile(
    key: ValueKey('join-${kind.name}-$parent-$selected'),
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(label, style: Theme.of(context).textTheme.bodySmall),
    subtitle: Text(
      CommunityDirectory.find(selected)?.name ?? hint,
      style: Theme.of(context).textTheme.titleMedium,
    ),
    trailing: const Icon(Icons.chevron_right, size: 20),
    enabled: !_saving && parent != null,
    onTap: () => _pick(kind),
  );
  @override
  Widget build(BuildContext context) {
    final value = _selection!;
    return Scaffold(
      appBar: AppBar(
        leading: const MenuBackButton(),
        title: const Text('Topluluğunu seç'),
      ),
      body: PageLayout(
        eyebrow: 'Çevreni seç',
        title: 'Şehrin ve okulun',
        subtitle: 'Listeden seç, kendi çevrendeki oyuncuları bul. Okul ve sınıf isteğe bağlı.',
        children: [
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.public, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          CommunityDirectory.find(value.countryId)!.name,
                        ),
                      ),
                      TextButton(
                        key: const ValueKey('change-country'),
                        onPressed: _saving
                            ? null
                            : () => _pick(CommunityKind.country),
                        child: const Text('Değiştir'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _row(
                  'Şehir',
                  'Şehrini seç',
                  CommunityKind.city,
                  value.countryId,
                  value.cityId,
                  Icons.location_city,
                ),
                const Divider(height: 1),
                _row(
                  'Okul',
                  value.cityId == null ? 'Önce şehrini seç' : 'Okulunu seç',
                  CommunityKind.school,
                  value.cityId,
                  value.schoolId,
                  Icons.school_outlined,
                ),
                const Divider(height: 1),
                _row(
                  'Sınıf',
                  value.schoolId == null ? 'Önce okulunu seç' : 'Sınıfını seç',
                  CommunityKind.classroom,
                  value.schoolId,
                  value.classId,
                  Icons.groups_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.path,
            key: const ValueKey('membership-path'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              key: const ValueKey('membership-groups'),
              leading: const Icon(Icons.group_add_outlined),
              title: const Text('Gruplarım'),
              subtitle: Text(
                value.groupIds.isEmpty
                    ? 'İsteğe bağlı'
                    : '${value.groupIds.length} grup seçili',
              ),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final group in CommunityDirectory.children(
                      CommunityKind.group,
                      null,
                    ))
                      FilterChip(
                        key: ValueKey('join-group-${group.id}'),
                        label: Text(group.name),
                        selected: value.groupIds.contains(group.id),
                        onSelected: _saving
                            ? null
                            : (_) => setState(
                                () => _selection = value.select(
                                  CommunityKind.group,
                                  group.id,
                                ),
                              ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => context.push('/school-feedback'),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Okulum listede yok / Bilgi hatalı'),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('save-membership'),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Her sınıf ve grup en fazla ${SmallTeamPolicy.maxMembers} üye kabul eder. Bir üye ayrılınca yer açılır. Misafir seçimleri bu cihazda saklanır; takım üyeliği kalıcı hesabınla kaydedilir. Okul ve sınıf üyeliği beyana dayanır.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
