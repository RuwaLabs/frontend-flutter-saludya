import 'auth_models.dart';

abstract interface class AuthRepository {
  Future<LoginChallenge> login(String email, String password);
  Future<AuthSession> verify(String challengeId, String code);
  Future<void> resend(String challengeId);
  Future<PasswordRecoveryChallenge> requestPasswordRecoveryCode(String email);
  Future<PasswordResetGrant> verifyPasswordRecoveryCode(
    String challengeId,
    String code,
  );
  Future<void> resetPassword(
    String token,
    String password,
    String confirmation,
  );
  Future<AuthSession?> restoreSession();
  Future<void> logout();
}
