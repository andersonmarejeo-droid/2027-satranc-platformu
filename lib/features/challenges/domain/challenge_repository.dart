import '../../game/domain/time_control.dart';
import 'challenge_invite.dart';

/// Production implementation must create and resolve invites on the server.
/// The server owns expiry, identity, one-time acceptance and match creation.
abstract interface class ChallengeRepository {
  bool get isLocalDemo;
  Future<ChallengeInvite> create(TimeControl timeControl);
  Future<ChallengeInvite?> find(String id);
}
