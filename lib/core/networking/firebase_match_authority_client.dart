import 'package:cloud_functions/cloud_functions.dart';

import '../constants/app_config.dart';

/// Client boundary for the server-authoritative online match endpoint.
///
/// The callable is intentionally kept behind [AppConfig.serverAuthorityEnabled]
/// until the Firebase Functions/Cloud Run deployment is live. Keeping this
/// contract in the app now lets the UI and the backend evolve independently,
/// while the existing Firestore adapter remains the safe compatibility path.
class FirebaseMatchAuthorityClient {
  FirebaseMatchAuthorityClient({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(region: AppConfig.firebaseRegion);

  final FirebaseFunctions _functions;

  Future<void> submitMove({
    required String matchId,
    required int expectedPly,
    required String uci,
    required String idempotencyKey,
  }) async {
    final callable = _functions.httpsCallable(
      'submitOnlineMove',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
    );
    final response = await callable.call(<String, dynamic>{
      'matchId': matchId,
      'expectedPly': expectedPly,
      'uci': uci,
      'idempotencyKey': idempotencyKey,
    });
    if (response.data is! Map) {
      throw StateError('Maç otoritesi geçersiz yanıt verdi.');
    }
  }
}
