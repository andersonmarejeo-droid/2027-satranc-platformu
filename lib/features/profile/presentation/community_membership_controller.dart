import 'package:flutter/foundation.dart';

import '../domain/community_membership.dart';

class CommunityMembershipController extends ChangeNotifier {
  CommunityMembershipController(this.repository);
  final CommunityMembershipRepository repository;
  Future<void> Function(CommunityMembership next)? beforeSave;
  CommunityMembership value = CommunityMembership();
  bool saving = false;
  Future<void> load() async {
    value = await repository.load();
  }

  Future<void> save(CommunityMembership next) async {
    if (saving) throw StateError('Membership is already saving');
    saving = true;
    notifyListeners();
    try {
      await beforeSave?.call(next);
      await repository.save(next);
      value = next;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
