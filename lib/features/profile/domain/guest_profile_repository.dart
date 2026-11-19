import 'guest_profile.dart';

abstract interface class GuestProfileRepository {
  Future<GuestProfile> loadOrCreate();
  Future<void> saveDisplayName(String displayName);
}
