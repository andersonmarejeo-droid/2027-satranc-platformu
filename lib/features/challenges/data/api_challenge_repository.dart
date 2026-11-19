import '../../../core/networking/api_client.dart';
import '../../game/domain/time_control.dart';
import '../domain/challenge_invite.dart';
import '../domain/challenge_repository.dart';

/// Server adapter for the versioned challenge contract in docs/api/openapi.yaml.
/// It is selected only after an authenticated session provider is supplied.
class ApiChallengeRepository implements ChallengeRepository {
  const ApiChallengeRepository(this._api);

  final ApiClient _api;
  static final _validId = RegExp(r'^[A-Za-z0-9_-]{32,64}$');

  @override
  bool get isLocalDemo => false;

  @override
  Future<ChallengeInvite> create(TimeControl timeControl) async {
    final response = await _api.post('/v1/challenges', {
      'timeControl': {
        'initialSeconds': timeControl.minutes * 60,
        'incrementSeconds': timeControl.incrementSeconds,
      },
      'colorPreference': 'random',
    });
    return _parse(response);
  }

  @override
  Future<ChallengeInvite?> find(String id) async {
    if (!_validId.hasMatch(id)) return null;
    try {
      return _parse(
        await _api.get('/v1/challenges/${Uri.encodeComponent(id)}'),
      );
    } on ApiFailure catch (failure) {
      if (failure.statusCode == 404) return null;
      rethrow;
    }
  }

  ChallengeInvite _parse(Map<String, Object?> response) {
    try {
      final id = response['id'];
      final expiresAt = response['expiresAt'];
      final shareUrl = response['shareUrl'];
      final rawTimeControl = response['timeControl'];
      if (id is! String || !_validId.hasMatch(id)) {
        throw const FormatException('Invalid challenge ID.');
      }
      if (expiresAt is! String || shareUrl is! String) {
        throw const FormatException('Missing challenge fields.');
      }
      if (rawTimeControl is! Map) {
        throw const FormatException('Invalid time control.');
      }
      final initialSeconds = rawTimeControl['initialSeconds'];
      final incrementSeconds = rawTimeControl['incrementSeconds'];
      if (initialSeconds is! int ||
          initialSeconds < 60 ||
          initialSeconds % 60 != 0 ||
          incrementSeconds is! int ||
          incrementSeconds < 0) {
        throw const FormatException('Unsupported time control.');
      }
      final expiry = DateTime.tryParse(expiresAt);
      final publicUrl = Uri.tryParse(shareUrl);
      if (expiry == null ||
          publicUrl == null ||
          publicUrl.scheme != 'https' ||
          publicUrl.host.isEmpty ||
          publicUrl.userInfo.isNotEmpty) {
        throw const FormatException('Invalid expiry or share URL.');
      }
      return ChallengeInvite(
        id: id,
        timeControl: TimeControl(initialSeconds ~/ 60, incrementSeconds),
        expiresAt: expiry,
        publicUrl: publicUrl,
      );
    } on FormatException {
      throw const ApiFailure(
        'Sunucu geçersiz bir davet yanıtı verdi.',
        kind: ApiFailureKind.invalidResponse,
      );
    }
  }
}
