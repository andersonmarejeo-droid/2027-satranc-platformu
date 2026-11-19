import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../profile/domain/community_membership.dart';
import '../../profile/presentation/profile_controller.dart';
import '../../profile/presentation/community_membership_controller.dart';
import '../../groups/domain/small_team_membership_repository.dart';
import '../data/firebase_email_registration.dart';

class AccountController extends ChangeNotifier {
  AccountController(
    this.auth,
    this.db,
    this.profile,
    this.membership, {
    this.teams,
    this.registerEmail,
  }) {
    _session = auth.idTokenChanges().listen((_) {
      notifyListeners();
    });
    profile.addListener(_scheduleBackup);
    membership.addListener(_scheduleBackup);
    membership.beforeSave = _beforeMembershipSave;
  }
  final SmallTeamMembershipRepository? teams;
  final Future<void> Function(String email, String password)? registerEmail;
  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final ProfileController profile;
  final CommunityMembershipController membership;
  StreamSubscription<User?>? _session;
  Timer? _backupTimer;
  bool busy = false, rankingEnabled = false, _restoring = false;
  bool removalPending = false;
  bool restorePending = false;
  String? error;
  String? verificationNotice, backupNotice;
  bool verificationFailed = false;
  DateTime? _lastVerificationRequest;
  DateTime? lastBackup;
  // Matches the enforced Firebase password policy (verified 5 October 2026).
  int get minimumPasswordLength => 12;
  Future<void> _pending = Future.value();
  bool get permanent =>
      auth.currentUser != null && !auth.currentUser!.isAnonymous;
  bool get verified => auth.currentUser?.emailVerified == true;
  String? get email => auth.currentUser?.email;
  DocumentReference<Map<String, dynamic>> _account(String uid) =>
      db.collection('playerAccounts').doc(uid);
  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } on TeamCapacityFailure catch (e) {
      error = e.message;
    } on FirebaseAuthException catch (e) {
      error = switch (e.code) {
        'email-already-in-use' => 'Bu e-posta kayıtlı. Hesabına giriş yap.',
        'credential-already-in-use' =>
          'Bu e-posta başka hesaba bağlı. Giriş yap seçeneğini kullan.',
        'invalid-email' => 'E-posta adresini kontrol et.',
        'weak-password' =>
          'En az $minimumPasswordLength karakterli bir şifre seç.',
        'invalid-credential' ||
        'user-not-found' ||
        'wrong-password' => 'E-posta veya şifre hatalı.',
        'too-many-requests' =>
          'Çok fazla deneme oldu. Biraz sonra yeniden dene.',
        'requires-recent-login' =>
          'Bu işlem için yeniden giriş yapman gerekiyor.',
        'network-request-failed' =>
          'Bağlantı kurulamadı. İnternetini kontrol edip yeniden dene.',
        'operation-not-allowed' || 'registration-unavailable' =>
          'Kayıt hizmeti şu anda kullanılamıyor. Biraz sonra yeniden dene.',
        'invalid-user-token' ||
        'user-token-expired' ||
        'user-mismatch' => 'Oturum yenilenemedi. Uygulamayı yeniden açıp dene.',
        'registration-sync-required' => 'Kaydın oluşturuldu; oturum açılamadı. Giriş yap seçeneğiyle e-posta ve şifreni kullan.',
        'provider-already-linked' =>
          'Hesabın zaten kayıtlı. Giriş yap seçeneğini kullan.',
        'user-disabled' =>
          'Bu hesap kullanıma kapalı. Destek ile iletişime geç.',
        _ => 'Hesap işlemi tamamlanamadı. Biraz sonra yeniden dene.',
      };
    } on TimeoutException {
      error =
          'İşlem beklenenden uzun sürdü. Bağlantını kontrol edip yeniden dene.';
    } on FirebaseException catch (e) {
      error = e.code == 'permission-denied'
          ? 'Hesap bilgilerine erişilemedi. Oturumunu yenileyip tekrar dene.'
          : 'Hesap bilgileri kaydedilemedi. Biraz sonra yeniden dene.';
    } catch (_) {
      error = 'Hesap işlemi tamamlanamadı. Biraz sonra yeniden dene.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password) => _run(() async {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim())) {
      error = 'Geçerli bir e-posta adresi yaz.';
      return;
    }
    if (password.length < minimumPasswordLength) {
      error = 'En az $minimumPasswordLength karakterli bir şifre seç.';
      return;
    }
    _backupTimer?.cancel();
    await _pending;
    _restoring = true;
    verificationNotice = null;
    backupNotice = null;
    try {
      if (auth.currentUser == null) await auth.signInAnonymously();
      await (registerEmail ?? FirebaseEmailRegistration(auth).link)(
        email.trim(),
        password,
      );
      rankingEnabled = false;
      removalPending = false;
      restorePending = false;
      lastBackup = null;
      // Verification and profile backup are separate. A full class or a failed
      // Firestore write must never prevent the new account's verification mail.
      await _requestVerification();
      try {
        await backup().timeout(const Duration(seconds: 10));
      } on TeamCapacityFailure catch (e) {
        backupNotice =
            'Kaydın tamamlandı. ${e.message} Okul veya grup seçimini düzenleyip tekrar yedekle.';
      } catch (_) {
        backupNotice = 'Kaydın tamamlandı. Profil yedeğin bekliyor; Şimdi yedekle ile tekrar deneyebilirsin.';
      }
    } finally {
      _restoring = false;
    }
  });
  Future<void> signIn(String email, String password) => _run(() async {
    _backupTimer?.cancel();
    await _pending;
    _restoring = true;
    try {
      await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      rankingEnabled = false;
      verificationNotice = null;
      backupNotice = null;
      verificationFailed = false;
      _lastVerificationRequest = null;
      removalPending = false;
      lastBackup = null;
      await restoreOrBackup();
    } finally {
      _restoring = false;
    }
  });
  Future<void> restoreOrBackup() async {
    final user = auth.currentUser;
    if (user == null || user.isAnonymous) return;
    restorePending = true;
    final data =
        (await _account(user.uid)
                .get(const GetOptions(source: Source.server))
                .timeout(const Duration(seconds: 8)))
            .data();
    if (auth.currentUser?.uid != user.uid) return;
    if (data == null) {
      rankingEnabled = false;
      removalPending = false;
      restorePending = false;
      await backup();
      return;
    }
    _restoring = true;
    try {
      await profile.saveDisplayName(data['displayName'] as String);
      await membership.save(
        CommunityMembership.fromJson(
          Map<String, dynamic>.from(data['membership'] as Map),
        ),
      );
      rankingEnabled = data['rankingEnabled'] == true;
      removalPending = data['rankingCleanupPending'] == true;
      lastBackup = (data['updatedAt'] as Timestamp?)?.toDate();
      restorePending = false;
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  void _scheduleBackup() {
    if (_restoring ||
        restorePending ||
        !permanent ||
        profile.isSaving ||
        membership.saving) {
      return;
    }
    _backupTimer?.cancel();
    _backupTimer = Timer(const Duration(milliseconds: 750), () {
      unawaited(
        backup().catchError((Object _) {
          error = 'Cihazdaki seçimlerin kaydedildi; hesap yedeği bekliyor.';
          notifyListeners();
        }),
      );
    });
  }

  Future<void> _beforeMembershipSave(CommunityMembership next) async {
    if (_restoring || !permanent || teams == null) return;
    _backupTimer?.cancel();
    await _writeBackup(next);
  }

  Future<void> backup() => _writeBackup(membership.value);
  Future<void> _writeBackup(CommunityMembership selected) {
    final user = auth.currentUser;
    if (user == null || user.isAnonymous) return Future.value();
    if (restorePending) {
      return Future.error(
        StateError('Restore account before replacing its backup'),
      );
    }
    final data = <String, dynamic>{
      'displayName': profile.profile?.displayName ?? 'Misafir oyuncu',
      'membership': selected.toJson(),
      'rankingEnabled': rankingEnabled,
      'rankingCleanupPending': removalPending,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final operation = _pending.then((_) async {
      if (auth.currentUser?.uid != user.uid) return;
      if (teams == null) {
        await _account(user.uid).set(data);
      } else {
        await teams!.saveAccount(user.uid, data);
      }
      lastBackup = DateTime.now();
      backupNotice = null;
      error = null;
      notifyListeners();
    });
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> refreshVerification() => _run(() async {
    await auth.currentUser?.reload();
    await auth.currentUser?.getIdToken(true);
    await restoreOrBackup();
  });
  Future<void> retryRestore() => _run(restoreOrBackup);
  Future<void> _requestVerification() async {
    final user = auth.currentUser;
    if (user == null || user.isAnonymous || user.emailVerified) return;
    if (_lastVerificationRequest != null &&
        DateTime.now().difference(_lastVerificationRequest!).inSeconds < 60) {
      verificationNotice = 'E-posta isteğin alındı. Yeniden göndermek için bir dakika bekle; spam klasörünü de kontrol et.';
      return;
    }
    try {
      await auth.setLanguageCode('tr');
      await user.sendEmailVerification().timeout(const Duration(seconds: 15));
      _lastVerificationRequest = DateTime.now();
      verificationFailed = false;
      verificationNotice = 'Doğrulama e-postası için gönderim isteği alındı. Gelen kutunu ve spam klasörünü kontrol et.';
    } catch (_) {
      verificationFailed = true;
      verificationNotice = 'Hesabın hazır; doğrulama e-postası gönderilemedi. Yeniden gönder ile tekrar dene.';
    }
  }

  Future<void> resendVerification() => _run(_requestVerification);
  Future<void> resetPassword(String value) => _run(() async {
    await auth.sendPasswordResetEmail(email: value.trim());
  });
  Future<void> setRanking(bool value) => _run(() async {
    if (restorePending) {
      error = 'Önce hesap yedeğini yeniden yükle.';
      return;
    }
    if (!value) {
      final previous = rankingEnabled;
      rankingEnabled = false;
      removalPending = true;
      try {
        await backup();
      } catch (_) {
        rankingEnabled = previous;
        removalPending = false;
        rethrow;
      }
      final uid = auth.currentUser!.uid;
      for (final collection in ['communityScores', 'scoreClaims']) {
        while (true) {
          final rows = await db
              .collection(collection)
              .where('uid', isEqualTo: uid)
              .limit(10)
              .get();
          if (rows.docs.isEmpty) break;
          final batch = db.batch();
          for (final row in rows.docs) {
            batch.delete(row.reference);
          }
          await batch.commit();
        }
      }
      removalPending = false;
      try {
        await backup();
      } catch (_) {
        removalPending = true;
        rethrow;
      }
      return;
    }
    if (removalPending) {
      error = 'Önce eski sıralama kayıtlarının temizliğini tamamla.';
      return;
    }
    final previous = rankingEnabled;
    rankingEnabled = value;
    try {
      await backup();
    } catch (_) {
      rankingEnabled = previous;
      rethrow;
    }
  });
  Future<void> signOut() => _run(() async {
    _backupTimer?.cancel();
    await _pending;
    await auth.signOut();
    await SharedPreferencesAsync().remove('onlineConsent.v2');
    rankingEnabled = false;
    verificationNotice = null;
    backupNotice = null;
    verificationFailed = false;
    _lastVerificationRequest = null;
    lastBackup = null;
    removalPending = false;
    restorePending = false;
    _restoring = true;
    try {
      await profile.saveDisplayName('Misafir oyuncu');
      await membership.save(
        CommunityMembership().select(CommunityKind.country, 'tr'),
      );
    } finally {
      _restoring = false;
    }
  });
  @override
  void dispose() {
    _restoring = true;
    _backupTimer?.cancel();
    unawaited(_session?.cancel());
    profile.removeListener(_scheduleBackup);
    membership.removeListener(_scheduleBackup);
    membership.beforeSave = null;
    super.dispose();
  }

  Future<void> prepareDeletion() async {
    _backupTimer?.cancel();
    _restoring = true;
    await _pending;
    final user = auth.currentUser;
    if (user != null && !user.isAnonymous) await teams?.leaveAll(user.uid);
  }

  Future<bool> reauthenticate(String password) async {
    if (busy) return false;
    final user = auth.currentUser;
    if (user == null || user.email == null) return false;
    await _run(() async {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
    });
    return error == null;
  }
}
