import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../game/data/online_position.dart';
import '../../game/domain/game_result.dart';
import '../../game/domain/online_match_timing.dart';
import '../domain/competition_score.dart';

/// Participant agreement, not a server chess engine. Never trusts supplied FEN.
class FirebaseCompetitionRepository extends CompetitionRepository {
  FirebaseCompetitionRepository(this.auth, this.db);
  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final _states = <String, String>{}, _working = <String>{};
  final _listeners =
      <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};
  final _fallbackTimers = <String, Timer>{};
  static const _immediateClaimReasons = {
    'timeout',
    'inactivity',
    'resign',
    'agreedDraw',
    'limit',
  };
  @override
  String? get playerId => auth.currentUser?.uid;
  @override
  String? status(String matchId) => _states[matchId];
  void _status(String id, String value) {
    if (_states[id] == value) return;
    _states[id] = value;
    notifyListeners();
  }

  @override
  Future<void> record(String matchId) async {
    final uid = playerId;
    if (uid == null ||
        _working.contains(matchId) ||
        (_states[matchId]?.startsWith('Puanın kaydedildi') == true ||
            _states[matchId]?.startsWith('Sonuç doğrulandı') == true ||
            _states[matchId]?.startsWith('Çok kısa oyun') == true)) {
      return;
    }
    _working.add(matchId);
    try {
      final matchRef = db.collection('onlineMatches').doc(matchId),
          resultRef = db.collection('onlineResults').doc(matchId);
      await db.runTransaction((tx) async {
        final match = (await tx.get(matchRef)).data();
        if (match == null) throw StateError('Missing match');
        final prior = (await tx.get(resultRef)).data();
        final account = (await tx.get(db.collection('playerAccounts').doc(uid)))
            .data();
        final moves = List<String>.from(match['moves'] as List),
            position = OnlinePosition(moves);
        final participants = List<String>.from(match['participants'] as List);
        if (!participants.contains(uid)) throw StateError('Not participant');
        final resignedBy = match['resignedBy'] as String? ?? '';
        final timing = OnlineMatchTiming(
          whiteMilliseconds: match['whiteMs'] as int,
          blackMilliseconds: match['blackMs'] as int,
          whiteToMove: moves.length.isEven,
          lastMoveAt: (match['lastAt'] as Timestamp).toDate(),
          now: DateTime.now().toUtc(),
          turnLimitSeconds: match['turnLimitSeconds'] as int? ?? 0,
          boardFinished:
              position.rules.isOver ||
              match['drawAccepted'] == true ||
              resignedBy.isNotEmpty ||
              moves.length == 600,
        );
        final reason = match['drawAccepted'] == true
            ? 'agreedDraw'
            : resignedBy.isNotEmpty
            ? 'resign'
            : position.rules.isOver
            ? (position.result == GameResult.draw ? 'boardDraw' : 'mate')
            : timing.timeoutReason != null
            ? (timing.timeoutReason == MatchTimeoutReason.inactivity
                  ? 'inactivity'
                  : 'timeout')
            : moves.length == 600
            ? 'limit'
            : null;
        if (reason == null) return;
        final outcome =
            reason == 'agreedDraw' || reason == 'boardDraw' || reason == 'limit'
            ? 'draw'
            : reason == 'resign'
            ? (resignedBy == participants.first ? 'black' : 'white')
            : reason == 'timeout' || reason == 'inactivity'
            ? (moves.length.isEven ? 'black' : 'white')
            : position.result == GameResult.whiteWins
            ? 'white'
            : 'black';
        final opted =
            account?['rankingEnabled'] == true &&
            auth.currentUser?.emailVerified == true;
        final membership = opted
            ? Map<String, dynamic>.from(account!['membership'] as Map)
            : <String, dynamic>{};
        final profile = {
          'alias': opted ? account!['displayName'] : '',
          'optIn': opted,
          'countryId': membership['countryId'] ?? '',
          'cityId': membership['cityId'] ?? '',
          'schoolId': membership['schoolId'] ?? '',
          'classId': membership['classId'] ?? '',
          'groupIds': membership['groupIds'] ?? <String>[],
        };
        if (prior == null) {
          tx.set(resultRef, {
            'participants': participants,
            'ply': moves.length,
            'lastAt': match['lastAt'],
            'outcome': outcome,
            'reason': reason,
            'confirmedBy': [uid],
            'profiles': {uid: profile},
            'endedAt': FieldValue.serverTimestamp(),
          });
        } else {
          if (prior['outcome'] != outcome ||
              prior['ply'] != moves.length ||
              prior['lastAt'] != match['lastAt']) {
            throw StateError('Result mismatch');
          }
          final confirmed = List<String>.from(prior['confirmedBy'] as List);
          if (!confirmed.contains(uid)) {
            tx.update(resultRef, {
              'confirmedBy': [...confirmed, uid],
              'profiles': {
                ...Map<String, dynamic>.from(prior['profiles'] as Map),
                uid: profile,
              },
            });
          }
        }
      });
      final result = (await resultRef.get(
        const GetOptions(source: Source.server),
      )).data();
      if (result == null) return;
      final confirmedCount = (result['confirmedBy'] as List).length;
      final resultReason = result['reason'] as String? ?? '';
      final endedAt = (result['endedAt'] as Timestamp?)?.toDate();
      final fallbackElapsed = endedAt == null
          ? Duration.zero
          : DateTime.now().toUtc().difference(endedAt.toUtc());
      final canClaimUnilaterally =
          _immediateClaimReasons.contains(resultReason) ||
          fallbackElapsed >= const Duration(seconds: 180);
      if (confirmedCount < 2 && !canClaimUnilaterally) {
        _status(matchId, 'Sonuç rakibin uygulamasında doğrulanmayı bekliyor.');
        _listeners.putIfAbsent(
          matchId,
          () => resultRef.snapshots().listen(
            (doc) {
              if ((doc.data()?['confirmedBy'] as List?)?.length == 2) {
                unawaited(
                  Future<void>.delayed(
                    const Duration(milliseconds: 100),
                    () => record(matchId),
                  ),
                );
              }
            },
            onError: (Object _) {
              _status(matchId, 'Sonuç için yeniden bağlanılıyor.');
            },
          ),
        );
        final remainingWait =
            const Duration(seconds: 181) - fallbackElapsed;
        _fallbackTimers.putIfAbsent(
          matchId,
          () => Timer(
            remainingWait.isNegative ? Duration.zero : remainingWait,
            () {
              _fallbackTimers.remove(matchId);
              unawaited(record(matchId));
            },
          ),
        );
        return;
      }
      _fallbackTimers.remove(matchId)?.cancel();
      final profile = Map<String, dynamic>.from(
        (result['profiles'] as Map)[uid] as Map,
      );
      if (profile['optIn'] != true) {
        _status(matchId, 'Sonuç doğrulandı · Sıralamaya katılım kapalı.');
        await _listeners.remove(matchId)?.cancel();
        return;
      }
      if ((result['ply'] as int) < 4) {
        _status(matchId, 'Çok kısa oyun · Topluluk puanına eklenmez.');
        await _listeners.remove(matchId)?.cancel();
        return;
      }
      final participants = List<String>.from(result['participants'] as List);
      final points = competitionPoints(
        result['outcome'] as String,
        participants.first == uid,
      );
      final ended = (result['endedAt'] as Timestamp).toDate();
      final scopes = <String, String>{
        'country': profile['countryId'] as String,
        'city': profile['cityId'] as String,
        'school': profile['schoolId'] as String,
        'classroom': profile['classId'] as String,
        for (final group in (profile['groupIds'] as List).cast<String>())
          'group:$group': group,
      };
      for (final period in [
        'all',
        competitionWeek(ended),
        competitionMonth(ended),
      ]) {
        for (final item in scopes.entries.where((e) => e.value.isNotEmpty)) {
          final scope = item.key.startsWith('group:') ? 'group' : item.key;
          final cardId = '${period}_${scope}_${item.value}_$uid',
              claimId = '${cardId}_$matchId';
          final cardRef = db.collection('communityScores').doc(cardId),
              claimRef = db.collection('scoreClaims').doc(claimId);
          await db.runTransaction((tx) async {
            final claim = await tx.get(claimRef),
                card = (await tx.get(cardRef)).data();
            if (claim.exists) return;
            tx.set(claimRef, {
              'uid': uid,
              'cardId': cardId,
              'matchId': matchId,
              'period': period,
              'scope': scope,
              'communityId': item.value,
              'alias': profile['alias'],
              'points': points,
              'win': points == 3 ? 1 : 0,
              'draw': points == 1 ? 1 : 0,
              'loss': points == 0 ? 1 : 0,
              'awardedAt': FieldValue.serverTimestamp(),
            });
            tx.set(cardRef, {
              'uid': uid,
              'period': period,
              'scope': scope,
              'communityId': item.value,
              'alias': profile['alias'],
              'published': true,
              'points': (card?['points'] as int? ?? 0) + points,
              'games': (card?['games'] as int? ?? 0) + 1,
              'wins': (card?['wins'] as int? ?? 0) + (points == 3 ? 1 : 0),
              'draws': (card?['draws'] as int? ?? 0) + (points == 1 ? 1 : 0),
              'losses': (card?['losses'] as int? ?? 0) + (points == 0 ? 1 : 0),
              'lastClaim': claimId,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          });
        }
      }
      _status(matchId, 'Puanın kaydedildi · +$points');
      await _listeners.remove(matchId)?.cancel();
    } catch (_) {
      _status(
        matchId,
        'Sonuç kaydı bekliyor · Bağlantı gelince yeniden denenecek.',
      );
    } finally {
      _working.remove(matchId);
    }
  }

  @override
  void dispose() {
    for (final listener in _listeners.values) {
      unawaited(listener.cancel());
    }
    for (final timer in _fallbackTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}
