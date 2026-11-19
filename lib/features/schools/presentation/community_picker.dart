import 'package:flutter/material.dart';

import '../../profile/domain/community_membership.dart';

Future<String?> showCommunityPicker(
  BuildContext context, {
  required CommunityKind kind,
  String? parentId,
  String? selectedId,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) =>
      _CommunityPicker(kind: kind, parentId: parentId, selectedId: selectedId),
);

class _CommunityPicker extends StatefulWidget {
  const _CommunityPicker({required this.kind, this.parentId, this.selectedId});
  final CommunityKind kind;
  final String? parentId, selectedId;
  @override
  State<_CommunityPicker> createState() => _CommunityPickerState();
}

class _CommunityPickerState extends State<_CommunityPicker> {
  late final List<CommunityNode> _options;
  late List<CommunityNode> _visible;
  @override
  void initState() {
    super.initState();
    _options =
        widget.kind == CommunityKind.school
              ? CommunityDirectory.schoolOptions(widget.parentId)
              : CommunityDirectory.children(widget.kind, widget.parentId)
          ..sort(
            (a, b) =>
                CommunityDirectory.searchKey(a.name)
                    .compareTo(CommunityDirectory.searchKey(b.name)),
          );
    _visible = _options;
  }

  @override
  Widget build(BuildContext context) {
    final school = widget.kind == CommunityKind.school;
    final title = school
        ? 'Okulunu seç'
        : widget.kind == CommunityKind.city
        ? 'Şehrini seç'
        : 'Ülkeni seç';
    final schoolRows = school
        ? _schoolRows(_visible)
        : const <_SchoolPickerRow>[];
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: (MediaQuery.sizeOf(context).height * .82 - keyboard).clamp(
          240.0,
          760.0,
        ),
        child: Column(
          children: [
            if (school && CommunityDirectory.hasSchoolCatalog)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(
                  'İlçeler alfabetik sıralanır; okul öncesi ve ilkokullar gösterilmez.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${CommunityDirectory.find(widget.parentId)?.name ?? ''}${widget.parentId == null ? '' : ' · '}${_visible.length} seçenek',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kapat',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                key: const ValueKey('community-search'),
                decoration: InputDecoration(
                  hintText: school ? 'Okul veya ilçe ara' : 'Ara',
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (query) => setState(
                  () => _visible = _options
                      .where((node) => CommunityDirectory.matches(node, query))
                      .toList(),
                ),
              ),
            ),
            if (widget.kind != CommunityKind.country)
              ListTile(
                key: const ValueKey('community-skip'),
                dense: true,
                leading: const Icon(Icons.skip_next_outlined),
                title: const Text('Şimdilik seçmiyorum'),
                onTap: () => Navigator.pop(context, ''),
              ),
            const Divider(height: 1),
            Expanded(
              child: _visible.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Sonuç bulunamadı. Aramanı kısaltabilir veya şimdilik bu adımı geçebilirsin.',
                        ),
                      ),
                    )
                  : ListView.builder(
                      key: const ValueKey('community-results'),
                      padding: const EdgeInsets.only(bottom: 72),
                      itemCount: school ? schoolRows.length : _visible.length,
                      itemBuilder: (context, index) {
                        if (school) {
                          final row = schoolRows[index];
                          if (row.district != null) {
                            return _DistrictHeader(name: row.district!);
                          }
                          final node = row.school!;
                          return _schoolTile(context, node);
                        }
                        final node = _visible[index];
                        return ListTile(
                          key: ValueKey('community-option-${node.id}'),
                          title: Text(node.name),
                          selected: node.id == widget.selectedId,
                          trailing: node.id == widget.selectedId
                              ? const Icon(Icons.check_circle_outline)
                              : null,
                          onTap: () => Navigator.pop(context, node.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<_SchoolPickerRow> _schoolRows(List<CommunityNode> schools) {
    final rows = <_SchoolPickerRow>[];
    String? district;
    for (final school in schools) {
      final nextDistrict = school.district ?? 'İlçesi belirtilmemiş';
      if (nextDistrict != district) {
        district = nextDistrict;
        rows.add(_SchoolPickerRow.header(nextDistrict));
      }
      rows.add(_SchoolPickerRow.school(school));
    }
    return rows;
  }

  Widget _schoolTile(BuildContext context, CommunityNode node) => ListTile(
    key: ValueKey('community-option-${node.id}'),
    title: Text(node.name),
    subtitle: node.schoolType == null ? null : Text(node.schoolType!),
    selected: node.id == widget.selectedId,
    trailing: node.id == widget.selectedId
        ? const Icon(Icons.check_circle_outline)
        : null,
    onTap: () => Navigator.pop(context, node.id),
  );
}

class _SchoolPickerRow {
  const _SchoolPickerRow.header(this.district) : school = null;
  const _SchoolPickerRow.school(this.school) : district = null;
  final String? district;
  final CommunityNode? school;
}

class _DistrictHeader extends StatelessWidget {
  const _DistrictHeader({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
    child: Text(
      name,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

Future<String?> showClassroomPicker(
  BuildContext context, {
  required String schoolId,
  String? selectedId,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _ClassroomPicker(schoolId: schoolId, selectedId: selectedId),
);

class _ClassroomPicker extends StatefulWidget {
  const _ClassroomPicker({required this.schoolId, this.selectedId});
  final String schoolId;
  final String? selectedId;
  @override
  State<_ClassroomPicker> createState() => _ClassroomPickerState();
}

class _ClassroomPickerState extends State<_ClassroomPicker> {
  int? _grade;
  String? _section;
  @override
  void initState() {
    super.initState();
    final name = CommunityDirectory.find(widget.selectedId)?.name;
    if (name != null) {
      final parts = name.split('-');
      _grade = int.tryParse(parts.first);
      _section = parts.length == 2 ? parts.last : null;
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sınıfını seç',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Kapat',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(CommunityDirectory.find(widget.schoolId)!.name),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            key: const ValueKey('classroom-grade'),
            initialValue: _grade,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Sınıf'),
            items: [
              for (var grade = 1; grade <= 12; grade++)
                DropdownMenuItem(value: grade, child: Text('$grade. sınıf')),
            ],
            onChanged: (value) => setState(() => _grade = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const ValueKey('classroom-section'),
            initialValue: _section,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Şube'),
            items: [
              for (final section in 'ABCÇDEFGĞHIİJKLMNOÖPQRSŞTUÜVWXYZ'.split(
                '',
              ))
                DropdownMenuItem(value: section, child: Text(section)),
            ],
            onChanged: (value) => setState(() => _section = value),
          ),
          const SizedBox(height: 12),
          Text(
            'Sınıfını kendin beyan edersin; bu seçim okul tarafından doğrulanmış üyelik değildir.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('classroom-confirm'),
            onPressed: _grade == null || _section == null
                ? null
                : () => Navigator.pop(
                    context,
                    CommunityDirectory.classroomFor(
                      widget.schoolId,
                      _grade!,
                      _section!,
                    ).id,
                  ),
            child: Text(
              _grade == null || _section == null
                  ? 'Sınıfımı seç'
                  : '$_grade-$_section seç',
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Şimdilik seçmiyorum'),
          ),
        ],
      ),
    ),
  );
}
