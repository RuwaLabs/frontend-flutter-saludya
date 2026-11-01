class LoginChallenge {
  const LoginChallenge({
    required this.id,
    required this.maskedEmail,
    this.expiresAt,
  });
  final String id;
  final String maskedEmail;
  final DateTime? expiresAt;
}

class PasswordRecoveryChallenge {
  const PasswordRecoveryChallenge({
    required this.id,
    required this.maskedEmail,
    this.expiresAt,
  });
  final String id;
  final String maskedEmail;
  final DateTime? expiresAt;
}

class PasswordResetGrant {
  const PasswordResetGrant({required this.token, this.expiresAt});
  final String token;
  final DateTime? expiresAt;
  @override
  String toString() => 'PasswordResetGrant[REDACTED]';
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.role,
    required this.userId,
    this.expiresAt,
  });
  final String token;
  final String role;
  final int userId;
  final DateTime? expiresAt;
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
