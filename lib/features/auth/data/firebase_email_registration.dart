import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/networking/api_transport.dart';
import '../../../core/networking/api_transport_factory.dart';

/// Google's supported ID-token signUp links a guest without changing its UID,
/// including projects with improved email privacy. No credentials are logged.
class FirebaseEmailRegistration {
  FirebaseEmailRegistration(this.auth, {this.transport, this.apiKey});
  final FirebaseAuth auth;
  final ApiTransport? transport;
  final String? apiKey;

  Future<void> link(String email, String password) async {
    final guest = auth.currentUser;
    if (guest == null || !guest.isAnonymous) {
      throw FirebaseAuthException(code: 'provider-already-linked');
    }
    final uid = guest.uid;
    final token = await guest.getIdToken();
    if (token == null || token.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-user-token');
    }
    final http = transport ?? createPlatformApiTransport();
    late final ApiTransportResponse response;
    try {
      response = await http
          .send(
            method: 'POST',
            uri: Uri.https(
              'identitytoolkit.googleapis.com',
              '/v1/accounts:signUp',
              {'key': apiKey ?? auth.app.options.apiKey},
            ),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idToken': token,
              'email': email.trim(),
              'password': password,
              'returnSecureToken': true,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      rethrow;
    } catch (_) {
      throw FirebaseAuthException(code: 'network-request-failed');
    } finally {
      if (transport == null) http.close();
    }
    final Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw FirebaseAuthException(code: 'invalid-response');
    }
    if (response.statusCode != 200) {
      final detail = (data['error'] as Map?)?['message'] as String? ?? '';
      throw FirebaseAuthException(
        code: switch (detail.split(RegExp(r'[ :]+')).first) {
          'EMAIL_EXISTS' => 'email-already-in-use',
          'INVALID_EMAIL' => 'invalid-email',
          'WEAK_PASSWORD' ||
          'PASSWORD_DOES_NOT_MEET_REQUIREMENTS' => 'weak-password',
          'TOO_MANY_ATTEMPTS_TRY_LATER' ||
          'QUOTA_EXCEEDED' => 'too-many-requests',
          'OPERATION_NOT_ALLOWED' ||
          'PASSWORD_LOGIN_DISABLED' => 'operation-not-allowed',
          'INVALID_ID_TOKEN' || 'TOKEN_EXPIRED' => 'invalid-user-token',
          _ => 'registration-unavailable',
        },
      );
    }
    if (data['localId'] != uid || auth.currentUser?.uid != uid) {
      throw FirebaseAuthException(code: 'user-mismatch');
    }
    // A refreshed guest token still has the anonymous sign-in provider. Sign in
    // to this already-linked account so verification and private profile writes
    // use a password session. Never create a replacement UID or store REST tokens.
    try {
      final result = await auth
          .signInWithEmailAndPassword(email: email.trim(), password: password)
          .timeout(const Duration(seconds: 15));
      if (result.user?.uid != uid || auth.currentUser?.uid != uid) {
        throw FirebaseAuthException(code: 'user-mismatch');
      }
      await auth.currentUser?.getIdToken(true);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-mismatch') rethrow;
      throw FirebaseAuthException(code: 'registration-sync-required');
    } catch (_) {
      throw FirebaseAuthException(code: 'registration-sync-required');
    }
    if (auth.currentUser?.uid != uid ||
        auth.currentUser?.isAnonymous != false) {
      throw FirebaseAuthException(code: 'registration-sync-required');
    }
  }
}
