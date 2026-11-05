class ImpersonationSession {
  const ImpersonationSession({
    required this.token,
    required this.expiresAt,
    required this.user,
    this.refreshToken,
    this.refreshExpiresAt,
  });

  final String token;
  final DateTime expiresAt;
  final Map<String, dynamic> user;
  final String? refreshToken;
  final DateTime? refreshExpiresAt;

  factory ImpersonationSession.fromResponse(
    dynamic response,
    int targetUserId,
  ) {
    final data = response is Map && response['data'] is Map
        ? response['data']
        : response;
    if (data is! Map ||
        data['userToken'] is! String ||
        (data['userToken'] as String).isEmpty ||
        data['userData'] is! Map) {
      throw const FormatException('Invalid impersonation response.');
    }

    final user = Map<String, dynamic>.from(data['userData'] as Map);
    final expiresAt = DateTime.tryParse('${data['expiresIn']}')?.toUtc();
    if (int.tryParse('${user['id']}') != targetUserId ||
        expiresAt == null ||
        !expiresAt.isAfter(
          DateTime.now().toUtc().add(const Duration(seconds: 30)),
        )) {
      throw const FormatException(
        'Invalid impersonation identity or expiration.',
      );
    }

    final refreshToken = data['refreshToken'];
    final refreshExpiresAt = data['refreshExpiresIn'] == null
        ? null
        : DateTime.tryParse('${data['refreshExpiresIn']}')?.toUtc();
    if (refreshToken != null &&
        (refreshToken is! String ||
            refreshToken.isEmpty ||
            refreshExpiresAt == null)) {
      throw const FormatException('Invalid impersonation refresh credentials.');
    }

    return ImpersonationSession(
      token: data['userToken'] as String,
      expiresAt: expiresAt,
      user: user,
      refreshToken: refreshToken as String?,
      refreshExpiresAt: refreshExpiresAt,
    );
  }
}
