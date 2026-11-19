class GuestProfile {
  const GuestProfile({required this.installId, required this.displayName});

  final String installId;
  final String displayName;

  GuestProfile copyWith({String? displayName}) => GuestProfile(
    installId: installId,
    displayName: displayName ?? this.displayName,
  );

  static String? displayNameError(String value) {
    final name = value.trim();
    if (name.isEmpty) return 'Bir görünen ad yaz.';
    if (name.runes.length > 24) return 'Adın en fazla 24 karakter olabilir.';
    if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(name)) {
      return 'Adında satır sonu veya kontrol karakteri kullanma.';
    }
    return null;
  }
}

class ProfileValidationException implements Exception {
  const ProfileValidationException(this.message);
  final String message;
}
