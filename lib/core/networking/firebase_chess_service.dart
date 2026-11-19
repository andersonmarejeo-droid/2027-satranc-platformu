import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/challenges/domain/challenge_invite.dart';
import '../../features/challenges/domain/online_challenge_repository.dart';
import '../../features/game/data/online_position.dart';
import '../../features/game/domain/game_result.dart';
import '../../features/game/domain/match_repository.dart';
import '../../features/game/domain/match_interactions.dart';
import '../../features/game/domain/match_snapshot.dart';
import '../../features/game/domain/match_stream_event.dart';
import '../../features/game/domain/owned_match_repository.dart';
import '../../features/game/domain/time_control.dart';
import '../../features/game/domain/online_match_timing.dart';
import '../../features/game/domain/match_connection_repository.dart';
import '../../features/matchmaking/domain/matchmaking_repository.dart';
import 'api_client.dart';
import 'firebase_match_authority_client.dart';

class FirebaseChessService
    implements
        OnlineChallengeRepository,
        MatchRepository,
        RealtimeMatchRepository,
        MatchmakingRepository,
        OwnedMatchRepository,
        MatchSocialRepository,
        MatchConnectionRepository {
  FirebaseChessService(this.auth, this.db, {this.authority}) {
    // Online moves must reach the server; never queue a stale move offline.
    db.settings = const Settings(persistenceEnabled: false);
  }
  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseMatchAuthorityClient? authority;
  final _random = Random.secure();
  Future<String>? _signingIn;
  final Map<String, String> _tickets = {};
  Future<void> Function()? beforeDelete;
  @override
  Stream<MatchConnection> watchConnection(String matchId) {
    late StreamController<MatchConnection> controller;
    Timer? timer;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? peer;
    DateTime? seen;
    bool connected = false, working = false, cancelled = false;
    void emit() {
      if (!cancelled && !controller.isClosed) {
        controller.add(
          MatchConnection(connected: connected, opponentSeenAt: seen),
        );
      }
    }

    Future<void> ping() async {
      if (working || cancelled) return;
      working = true;
      try {
        final uid = await _uid();
        await _match(matchId)
            .collection('presence')
            .doc(uid)
            .set({'seenAt': FieldValue.serverTimestamp()})
            .timeout(const Duration(seconds: 8));
        connected = true;
      } catch (_) {
        connected = false;
      } finally {
        working = false;
        emit();
      }
    }

    controller = StreamController<MatchConnection>(
      onListen: () async {
        try {
          final uid = await _uid();
          if (cancelled) return;
          peer = _match(matchId)
              .collection('presence')
              .snapshots()
              .listen(
                (snapshot) {
                  for (final doc in snapshot.docs) {
                    if (doc.id != uid) {
                      seen = (doc.data()['seenAt'] as Timestamp?)?.toDate();
                    }
                  }
                  emit();
                },
                onError: (Object _) {
                  connected = false;
                  emit();
                },
              );
          unawaited(ping());
          timer = Timer.periodic(
            const Duration(seconds: 20),
            (_) => unawaited(ping()),
          );
        } catch (_) {
          connected = false;
          emit();
        }
      },
      onCancel: () async {
        cancelled = true;
        timer?.cancel();
        await peer?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  bool get isLocalDemo => false;
  @override
  String? get playerId => auth.currentUser?.uid;
  Future<String> _uid() async {
    if (playerId != null) return playerId!;
    return _signingIn ??= auth
        .signInAnonymously()
        .then((value) => value.user!.uid)
        .whenComplete(() => _signingIn = null);
  }

  /// Stores only the current device token. The token is private to its owner
  /// and is replaceable, so revoking notification permission never leaves a
  /// second device token behind.
  Future<void> saveNotificationToken(String token) async {
    if (token.trim().isEmpty) return;
    final uid = await _uid();
    await db.collection('notificationTokens').doc(uid).set({
      'token': token,
      'platform': 'android',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeNotificationToken() async {
    final uid = playerId;
    if (uid == null) return;
    await db.collection('notificationTokens').doc(uid).delete();
  }

  String _id() => List.generate(
    20,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  DocumentReference<Map<String, dynamic>> _invite(String id) =>
      db.collection('onlineInvites').doc(id);
  DocumentReference<Map<String, dynamic>> _match(String id) =>
      db.collection('onlineMatches').doc(id);
  Map<String, dynamic> _inviteData(String uid, TimeControl time) => {
    'creator': uid,
    'guest': '',
    'matchId': '',
    'minutes': time.minutes,
    'increment': time.incrementSeconds,
    'turnLimitSeconds': OnlineMatchTiming.defaultTurnLimitSeconds,
    'createdAt': FieldValue.serverTimestamp(),
    'expiresAt': Timestamp.fromDate(
      DateTime.now().toUtc().add(const Duration(hours: 24)),
    ),
  };
  @override
  Future<ChallengeInvite> create(TimeControl timeControl) async {
    final uid = await _uid(), id = _id();
    await _invite(id).set(_inviteData(uid, timeControl));
    return (await find(id))!;
  }

  @override
  Future<ChallengeInvite?> find(String id) async {
    await _uid();
    if (!RegExp(r'^[a-f0-9]{40}$').hasMatch(id)) return null;
    try {
      final data = (await _invite(
        id,
      ).get(const GetOptions(source: Source.server))).data();
      if (data == null) return null;
      return ChallengeInvite(
        id: id,
        timeControl: TimeControl(
          data['minutes'] as int,
          data['increment'] as int,
        ),
        expiresAt: (data['expiresAt'] as Timestamp).toDate(),
        turnLimitSeconds: data['turnLimitSeconds'] as int? ?? 0,
        publicUrl: Uri.parse('https://satranc-platformu.web.app/challenge/$id'),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  Future<String> _acceptInTransaction(
    Transaction tx,
    String id,
    String uid,
    Map<String, dynamic> invite,
  ) async {
    final owner = invite['creator'] as String;
    if (invite['matchId'] != '') {
      if (uid != owner && uid != invite['guest']) {
        throw StateError('Davet kullanılmış.');
      }
      return invite['matchId'] as String;
    }
    if (uid == owner) {
      throw StateError('Arkadaşının daveti kabul etmesi bekleniyor.');
    }
    if ((invite['expiresAt'] as Timestamp).toDate().isBefore(DateTime.now())) {
      throw StateError('Davetin süresi dolmuş.');
    }
    if (invite['opponent'] != null && invite['opponent'] != uid) {
      throw StateError('Bu rövanş yalnız aynı iki oyuncu içindir.');
    }
    final parentId = invite['rematchOf'] as String?;
    Map<String, dynamic>? parent;
    if (parentId != null) {
      parent = (await tx.get(_match(parentId))).data();
      if (parent == null || parent['rematchInvite'] != id) {
        throw StateError('Rövanş teklifi değişmiş.');
      }
    }
    final ms = (invite['minutes'] as int) * 60000;
    tx.set(_match(id), {
      'participants': [owner, uid],
      'minutes': invite['minutes'],
      'increment': invite['increment'],
      'turnLimitSeconds': invite['turnLimitSeconds'] ?? 0,
      'moves': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'lastAt': FieldValue.serverTimestamp(),
      'whiteMs': ms,
      'blackMs': ms,
    });
    tx.update(_invite(id), {'guest': uid, 'matchId': id});
    if (parentId != null) {
      tx.update(_match(parentId), {
        'rematchMatch': id,
        'actionRevision': (parent!['actionRevision'] as int? ?? 0) + 1,
        'actionAt': FieldValue.serverTimestamp(),
      });
    }
    return id;
  }

  Future<Set<String>> _blockedPlayers(String uid) async {
    try {
      final docs = await db
          .collection('blockedPlayers')
          .where('owner', isEqualTo: uid)
          .limit(100)
          .get();
      return {
        for (final doc in docs.docs)
          if (doc.data()['blockedPlayer'] case final String id
              when id.isNotEmpty)
            id,
      };
    } catch (_) {
      return const {};
    }
  }

  @override
  Future<String> accept(String inviteId) async {
    final uid = await _uid();
    final blocked = await _blockedPlayers(uid);
    return db.runTransaction((tx) async {
      final data = (await tx.get(_invite(inviteId))).data();
      if (data == null) throw StateError('Davet bulunamadı.');
      if (blocked.contains(data['creator'] as String?)) {
        throw StateError('Engellediğin bir oyuncunun daveti açılamaz.');
      }
      return _acceptInTransaction(tx, inviteId, uid, data);
    });
  }

  @override
  Stream<String?> watchMatch(String inviteId) async* {
    await _uid();
    yield* _invite(inviteId).snapshots().map((doc) {
      final id = doc.data()?['matchId'] as String?;
      return id == null || id.isEmpty ? null : id;
    }).distinct();
  }

  @override
  Future<List<String>> recentMatches() async {
    final uid = playerId;
    if (uid == null) return [];
    final docs = await db
        .collection('onlineMatches')
        .where('participants', arrayContains: uid)
        .limit(30)
        .get();
    final sorted = docs.docs.toList()
      ..sort(
        (a, b) => (b.data()['lastAt'] as Timestamp).compareTo(
          a.data()['lastAt'] as Timestamp,
        ),
      );
    return sorted.map((d) => d.id).toList();
  }

  @override
  Future<List<OnlineMatchSummary>> recentMatchSummaries() async {
    final uid = playerId;
    if (uid == null) return [];
    final docs = await db
        .collection('onlineMatches')
        .where('participants', arrayContains: uid)
        .limit(30)
        .get();
    final sorted = docs.docs.toList()
      ..sort(
        (a, b) => (b.data()['lastAt'] as Timestamp).compareTo(
          a.data()['lastAt'] as Timestamp,
        ),
      );
    final summaries = <OnlineMatchSummary>[];
    for (final doc in sorted) {
      try {
        final data = doc.data();
        final snap = _snapshot(doc.id, data);
        final myColor = snap.player(MatchColor.white).id == uid
            ? MatchColor.white
            : MatchColor.black;
        final myTurn =
            snap.status == MatchStatus.active &&
            snap.whiteToMove == (myColor == MatchColor.white);
        final won =
            (snap.result == MatchResult.white && myColor == MatchColor.white) ||
            (snap.result == MatchResult.black && myColor == MatchColor.black);
        final reasonSuffix = snap.interactions.resignedBy != null
            ? ' · Terk'
            : snap.timeoutReason == MatchTimeoutReason.inactivity
            ? ' · Hareketsizlik'
            : snap.timeoutReason == MatchTimeoutReason.clock
            ? ' · Süre'
            : snap.interactions.drawAccepted
            ? ' · Anlaşma'
            : '';
        final label = snap.status == MatchStatus.active
            ? (myTurn ? 'Hamle sırası sende' : 'Rakibin hamlesi bekleniyor')
            : snap.result == MatchResult.draw
            ? 'Berabere$reasonSuffix'
            : won
            ? 'Kazandın$reasonSuffix'
            : 'Kaybettin$reasonSuffix';
        summaries.add(
          OnlineMatchSummary(
            id: doc.id,
            timeControl: TimeControl(
              data['minutes'] as int? ?? 10,
              data['increment'] as int? ?? 0,
            ),
            status: snap.status,
            playerColor: myColor,
            isMyTurn: myTurn,
            ply: snap.ply,
            updatedAt: snap.updatedAt,
            statusLabel: label,
          ),
        );
      } catch (_) {
        // Skip malformed match entries safely.
      }
    }
    return summaries;
  }

  @override
  Future<MatchSnapshot> fetch(String matchId) async {
    await _uid();
    late DocumentSnapshot<Map<String, dynamic>> doc;
    try {
      doc = await _match(matchId).get(const GetOptions(source: Source.server));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const ApiFailure(
          'Bu maç bu hesaba ait değil veya silinmiş. Doğru hesaba giriş yaparak yeniden dene.',
          statusCode: 403,
          kind: ApiFailureKind.invalidResponse,
        );
      }
      rethrow;
    }
    if (!doc.exists) {
      throw const ApiFailure(
        'Maç bulunamadı veya silindi.',
        statusCode: 404,
        kind: ApiFailureKind.invalidResponse,
      );
    }
    return _snapshot(matchId, doc.data()!);
  }

  MatchSnapshot _snapshot(String id, Map<String, dynamic> data) {
    String? nonEmpty(String key) {
      final value = data[key] as String?;
      return value == null || value.isEmpty ? null : value;
    }

    final moves = List<String>.from(data['moves'] as List);
    final position = OnlinePosition(moves), rules = position.rules;
    final players = List<String>.from(data['participants'] as List);
    final date = (data['lastAt'] as Timestamp).toDate();
    final agreedDraw = data['drawAccepted'] == true;
    final resignedBy = nonEmpty('resignedBy');
    final now = DateTime.now().toUtc();
    final timing = OnlineMatchTiming(
      whiteMilliseconds: data['whiteMs'] as int,
      blackMilliseconds: data['blackMs'] as int,
      whiteToMove: rules.whiteToMove,
      lastMoveAt: date,
      now: now,
      turnLimitSeconds: data['turnLimitSeconds'] as int? ?? 0,
      boardFinished:
          rules.isOver ||
          agreedDraw ||
          resignedBy != null ||
          moves.length == 600,
    );
    final white = timing.whiteRemaining, black = timing.blackRemaining;
    final timeout = timing.timeoutReason != null;
    final actionAt = (data['actionAt'] as Timestamp?)?.toDate();

    return MatchSnapshot(
      id: id,
      status:
          agreedDraw ||
              resignedBy != null ||
              rules.isOver ||
              timeout ||
              moves.length == 600
          ? MatchStatus.completed
          : MatchStatus.active,
      fen: rules.fen,
      ply: moves.length,
      whiteToMove: rules.whiteToMove,
      players: [
        for (var i = 0; i < 2; i++)
          MatchPlayer(
            id: players[i],
            displayName: players[i] == playerId ? 'Sen' : 'Rakibin',
            color: i == 0 ? MatchColor.white : MatchColor.black,
          ),
      ],
      clocks: MatchClocks(
        whiteMilliseconds: white,
        blackMilliseconds: black,
        serverTime: now,
      ),
      timeoutReason: timing.timeoutReason,
      turnRemainingMilliseconds: timing.turnRemainingMilliseconds,
      updatedAt: actionAt != null && actionAt.isAfter(date) ? actionAt : date,
      lastMoveUci: moves.isEmpty ? null : moves.last,
      sanHistory: rules.history,
      interactions: MatchInteractions(
        drawOfferedBy: nonEmpty('drawBy'),
        drawOfferPly: data['drawPly'] as int?,
        drawAccepted: agreedDraw,
        resignedBy: resignedBy,
        rematchOfferedBy: nonEmpty('rematchBy'),
        rematchInviteId: nonEmpty('rematchInvite'),
        rematchMatchId: nonEmpty('rematchMatch'),
        messages: [
          for (final message in (data['quickMessages'] as List? ?? const []))
            MatchQuickMessage(
              senderId: message['sender'] as String,
              code: QuickMessageCode.values.byName(message['code'] as String),
              sentAt: (message['at'] as Timestamp).toDate(),
            ),
        ],
      ),
      result: resignedBy != null
          ? (resignedBy == players[0] ? MatchResult.black : MatchResult.white)
          : agreedDraw || moves.length == 600
          ? MatchResult.draw
          : timeout
          ? (rules.whiteToMove ? MatchResult.black : MatchResult.white)
          : switch (position.result) {
              GameResult.whiteWins => MatchResult.white,
              GameResult.blackWins => MatchResult.black,
              GameResult.draw => MatchResult.draw,
              _ => null,
            },
    );
  }

  @override
  Future<MatchSnapshot> submitMove(
    String matchId, {
    required int expectedPly,
    required String uci,
  }) async {
    final uid = await _uid();
    if (authority != null) {
      // The key is deterministic so a network retry cannot apply a move twice.
      final idempotencyKey = '$matchId:$expectedPly:$uci';
      await authority!.submitMove(
        matchId: matchId,
        expectedPly: expectedPly,
        uci: uci,
        idempotencyKey: idempotencyKey,
      );
      return fetch(matchId);
    }
    await db.runTransaction((tx) async {
      final data = (await tx.get(_match(matchId))).data();
      if (data == null) throw StateError('Maç bulunamadı.');
      final moves = List<String>.from(data['moves'] as List);
      final state = _snapshot(matchId, data);
      if (moves.length != expectedPly) {
        throw const ApiFailure(
          'Tahta değişti.',
          kind: ApiFailureKind.http,
          statusCode: 409,
        );
      }
      if (state.status != MatchStatus.active) {
        throw const ApiFailure(
          'Maç sona erdi.',
          kind: ApiFailureKind.http,
          statusCode: 409,
        );
      }
      if ((data['participants'] as List)[expectedPly % 2] != uid) {
        throw StateError('Hamle sırası sende değil.');
      }
      OnlinePosition([...moves, uci]);
      final remaining =
          (expectedPly.isEven
              ? state.clocks.whiteMilliseconds
              : state.clocks.blackMilliseconds) +
          (data['increment'] as int) * 1000;
      tx.update(_match(matchId), {
        'moves': [...moves, uci],
        'lastAt': FieldValue.serverTimestamp(),
        'drawBy': '',
        if (expectedPly.isEven) 'whiteMs': remaining else 'blackMs': remaining,
      });
    });
    return fetch(matchId);
  }

  Future<MatchSnapshot> _interaction(
    String matchId,
    Map<String, dynamic> Function(Map<String, dynamic>, String) change,
  ) async {
    final uid = await _uid();
    await db.runTransaction((tx) async {
      final data = (await tx.get(_match(matchId))).data();
      if (data == null || !(data['participants'] as List).contains(uid)) {
        throw StateError('Bu maçta oyuncu değilsin.');
      }
      tx.update(_match(matchId), {
        ...change(data, uid),
        'actionRevision': (data['actionRevision'] as int? ?? 0) + 1,
        'actionAt': FieldValue.serverTimestamp(),
      });
    });
    return fetch(matchId);
  }

  @override
  Future<MatchSnapshot> offerDraw(String matchId) =>
      _interaction(matchId, (data, uid) {
        if (_snapshot(matchId, data).status != MatchStatus.active ||
            (data['drawBy'] as String? ?? '').isNotEmpty) {
          throw StateError('Yeni beraberlik teklifi yapılamıyor.');
        }
        return {'drawBy': uid, 'drawPly': (data['moves'] as List).length};
      });

  @override
  Future<MatchSnapshot> respondToDraw(String matchId, {required bool accept}) =>
      _interaction(matchId, (data, uid) {
        final offeredBy = data['drawBy'] as String? ?? '';
        if (offeredBy.isEmpty ||
            offeredBy == uid ||
            data['drawPly'] != (data['moves'] as List).length ||
            _snapshot(matchId, data).status != MatchStatus.active) {
          throw StateError('Beraberlik teklifi artık geçerli değil.');
        }
        final state = _snapshot(matchId, data);
        return accept
            ? {
                'drawAccepted': true,
                'whiteMs': state.clocks.whiteMilliseconds,
                'blackMs': state.clocks.blackMilliseconds,
              }
            : {'drawBy': ''};
      });

  @override
  Future<MatchSnapshot> resign(String matchId) =>
      _interaction(matchId, (data, uid) {
        final state = _snapshot(matchId, data);
        if (state.status != MatchStatus.active ||
            (data['resignedBy'] as String? ?? '').isNotEmpty) {
          throw StateError('Oyun zaten sona ermiş.');
        }
        return {
          'resignedBy': uid,
          'whiteMs': state.clocks.whiteMilliseconds,
          'blackMs': state.clocks.blackMilliseconds,
        };
      });

  @override
  Future<MatchSnapshot> requestRematch(String matchId) async {
    final uid = await _uid(), inviteId = _id();
    await db.runTransaction((tx) async {
      final data = (await tx.get(_match(matchId))).data();
      if (data == null ||
          !(data['participants'] as List).contains(uid) ||
          _snapshot(matchId, data).status != MatchStatus.completed) {
        throw StateError('Rövanş, oyun bittikten sonra istenebilir.');
      }
      if ((data['rematchInvite'] as String? ?? '').isNotEmpty) return;
      final players = List<String>.from(data['participants'] as List);
      final time = TimeControl(
        data['minutes'] as int,
        data['increment'] as int,
      );
      tx.set(_invite(inviteId), {
        ..._inviteData(uid, time),
        'opponent': players.firstWhere((id) => id != uid),
        'rematchOf': matchId,
      });
      tx.update(_match(matchId), {
        'rematchBy': uid,
        'rematchInvite': inviteId,
        'actionRevision': (data['actionRevision'] as int? ?? 0) + 1,
        'actionAt': FieldValue.serverTimestamp(),
      });
    });
    return fetch(matchId);
  }

  @override
  Future<String> acceptRematch(String matchId) async {
    final state = await fetch(matchId), request = state.interactions;
    if (state.status != MatchStatus.completed ||
        request.rematchInviteId == null ||
        request.rematchOfferedBy == playerId) {
      throw StateError('Rakibinin rövanş teklifi bekleniyor.');
    }
    return accept(request.rematchInviteId!);
  }

  @override
  Future<MatchSnapshot> sendQuickMessage(
    String matchId,
    QuickMessageCode code,
  ) => _interaction(matchId, (data, uid) {
    if (_snapshot(matchId, data).status != MatchStatus.completed) {
      throw StateError('Hazır mesajlar oyun sonunda gönderilir.');
    }
    final prior = data['quickMessages'] as List? ?? const [];
    if (prior.length >= 12) {
      throw StateError('Bu maçın mesaj sınırına ulaşıldı.');
    }
    return {
      'quickMessages': [
        ...prior,
        {'sender': uid, 'code': code.name, 'at': Timestamp.now()},
      ],
    };
  });

  @override
  Future<MatchStreamTicket> createStreamTicket(String matchId) async {
    await fetch(matchId);
    return MatchStreamTicket(
      value: 'firebase-authenticated-listener',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  @override
  Stream<MatchStreamEvent> watchEvents(
    String matchId, {
    required int afterSequence,
  }) async* {
    await _uid();
    yield* _match(matchId)
        .snapshots()
        .where((d) => d.exists && !d.metadata.hasPendingWrites)
        .map((doc) {
          final data = doc.data()!;
          return MatchStreamEvent(
            type: 'match.snapshot',
            matchId: matchId,
            sequence:
                (data['moves'] as List).length * 10000 +
                (data['actionRevision'] as int? ?? 0) +
                1,
            serverTime: ((data['actionAt'] ?? data['lastAt']) as Timestamp)
                .toDate(),
            payload: {'snapshot': _snapshot(matchId, data)},
          );
        })
        .where((event) => event.sequence > afterSequence);
  }

  @override
  Future<MatchTicket> join(TimeControl timeControl) async {
    final uid = await _uid(), id = _id();
    final blocked = await _blockedPlayers(uid);
    final bucket =
        '${timeControl.minutes}_${timeControl.incrementSeconds}_${OnlineMatchTiming.defaultTurnLimitSeconds}';
    final queue = db.collection('onlineQueues').doc(bucket);
    final ticket = await db.runTransaction((tx) async {
      final slot = (await tx.get(queue)).data();
      Map<String, dynamic>? invite;
      final previousId = slot?['invite'] as String?;
      if (previousId != null &&
          previousId.isNotEmpty &&
          (slot!['expiresAt'] as Timestamp).toDate().isAfter(DateTime.now())) {
        invite = (await tx.get(_invite(previousId))).data();
      }
      if (invite != null && invite['creator'] == uid && invite['guest'] == '') {
        return MatchTicket(previousId!, QueueStatus.searching);
      }
      if (invite != null &&
          invite['creator'] != uid &&
          invite['guest'] == '' &&
          !blocked.contains(invite['creator'] as String?)) {
        final match = await _acceptInTransaction(tx, previousId!, uid, invite);
        tx.update(queue, {
          'invite': '',
          'creator': '',
          'expiresAt': Timestamp.fromDate(DateTime.now()),
        });
        return MatchTicket(previousId, QueueStatus.matched, matchId: match);
      }
      tx.set(_invite(id), _inviteData(uid, timeControl));
      tx.set(queue, {
        'creator': uid,
        'invite': id,
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 5)),
        ),
      });
      return MatchTicket(id, QueueStatus.searching);
    });
    _tickets[ticket.id] = bucket;
    return ticket;
  }

  @override
  Stream<MatchTicket> watch(String ticketId) => watchMatch(ticketId).map(
    (id) => MatchTicket(
      ticketId,
      id == null ? QueueStatus.searching : QueueStatus.matched,
      matchId: id,
    ),
  );
  @override
  Future<void> cancel(String ticketId) async {
    final uid = await _uid(), bucket = _tickets[ticketId];
    if (bucket == null) return;
    final queue = db.collection('onlineQueues').doc(bucket);
    await db.runTransaction((tx) async {
      final data = (await tx.get(queue)).data();
      final invite = (await tx.get(_invite(ticketId))).data();
      if (data?['creator'] == uid &&
          data?['invite'] == ticketId &&
          invite?['guest'] == '') {
        tx.delete(_invite(ticketId));
        tx.update(queue, {
          'creator': '',
          'invite': '',
          'expiresAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    });
  }

  @override
  Future<void> deleteOnlineData() async {
    final uid = playerId;
    if (uid == null) return;
    await beforeDelete?.call();
    for (final query in [
      db.collection('communityScores').where('uid', isEqualTo: uid),
      db.collection('scoreClaims').where('uid', isEqualTo: uid),
      db.collection('schoolSuggestions').where('uid', isEqualTo: uid),
      db.collection('blockedPlayers').where('owner', isEqualTo: uid),
      db.collection('onlineResults').where('participants', arrayContains: uid),
      db.collection('onlineMatches').where('participants', arrayContains: uid),
      db.collection('onlineInvites').where('creator', isEqualTo: uid),
      db.collection('onlineInvites').where('guest', isEqualTo: uid),
      db.collection('onlineInvites').where('opponent', isEqualTo: uid),
      db.collection('onlineQueues').where('creator', isEqualTo: uid),
    ]) {
      while (true) {
        // Presence rules evaluate get(matchPath(id)), so delete presence first
        // in small batches before deleting the parent onlineMatches documents.
        final docs = await query.limit(5).get();
        if (docs.docs.isEmpty) break;
        if (docs.docs.first.reference.parent.id == 'onlineMatches') {
          final presenceBatch = db.batch();
          var hasPresence = false;
          for (final doc in docs.docs) {
            final presence = await doc.reference.collection('presence').get();
            for (final row in presence.docs) {
              presenceBatch.delete(row.reference);
              hasPresence = true;
            }
          }
          if (hasPresence) await presenceBatch.commit();
        }
        final batch = db.batch();
        for (final doc in docs.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
    await db.collection('notificationTokens').doc(uid).delete();
    await db.collection('playerAccounts').doc(uid).delete();
    await auth.currentUser!.delete();
  }
}
