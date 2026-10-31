import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

/// Application use-case facade for the authentication feature.
class AuthService {
  const AuthService(this._repository);
  final AuthRepository _repository;

  Future<LoginChallenge> startLogin(String email, String password) =>
      _repository.login(email, password);
  Future<AuthSession> verifyCode(String challengeId, String code) =>
      _repository.verify(challengeId, code);
  Future<void> resendCode(String challengeId) =>
      _repository.resend(challengeId);
  Future<PasswordRecoveryChallenge> requestPasswordRecoveryCode(String email) =>
      _repository.requestPasswordRecoveryCode(email);
  Future<PasswordResetGrant> verifyPasswordRecoveryCode(
    String challengeId,
    String code,
  ) => _repository.verifyPasswordRecoveryCode(challengeId, code);
  Future<void> resetPassword(
    String token,
    String password,
    String confirmation,
  ) => _repository.resetPassword(token, password, confirmation);
  Future<AuthSession?> restoreSession() => _repository.restoreSession();
  Future<void> logout() => _repository.logout();
}
