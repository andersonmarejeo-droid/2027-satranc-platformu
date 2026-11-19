abstract final class AppConfig {
  static const name = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Satranç Platformu',
  );
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const challengeBaseUrl = String.fromEnvironment('CHALLENGE_BASE_URL');
  // App Check is opt-in at build time so local APKs and debug builds can use
  // the Firebase debug provider without weakening the Play release policy.
  static const appCheckEnabled = bool.fromEnvironment(
    'CHESS_APP_CHECK_ENABLED',
    defaultValue: false,
  );
  static const telemetryEnabled = bool.fromEnvironment(
    'CHESS_TELEMETRY_ENABLED',
    defaultValue: true,
  );
  /// The client-side adapter stays off until the deployed match-authority
  /// endpoint is live and its health checks pass. This prevents a store build
  /// from silently falling back to a half-deployed endpoint.
  static const serverAuthorityEnabled = bool.fromEnvironment(
    'CHESS_SERVER_AUTHORITY_ENABLED',
    defaultValue: false,
  );
  static const firebaseRegion = String.fromEnvironment(
    'CHESS_FIREBASE_REGION',
    defaultValue: 'europe-west3',
  );
  static const demoMode = true;
}
