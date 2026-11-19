abstract interface class FriendshipRepository {
  Future<void> invite(String playerId);
  Future<void> remove(String playerId);
  Stream<List<String>> watchAcceptedFriends();
}
