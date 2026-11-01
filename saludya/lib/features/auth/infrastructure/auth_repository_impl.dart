import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._storage, {http.Client? client})
    : _client = client ?? http.Client();
  final FlutterSecureStorage _storage;
  final http.Client _client;
  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}/$path');
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client.post(
        _uri(path),
        headers: _headers,
        body: jsonEncode(body),
      );
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthException(_message(decoded, response.statusCode));
      }
      return decoded;
    } on AuthException {
      rethrow;
    } on FormatException {
      throw const AuthException('La respuesta del servidor no es válida.');
    } catch (_) {
      throw const AuthException(
        'No se pudo conectar con el servidor. Verifica tu conexión.',
      );
    }
  }

  String _message(Map<String, dynamic> data, int status) {
    final raw = (data['message'] ?? data['detail'] ?? data['error'])
        ?.toString();
    if (raw != null && raw.isNotEmpty) return raw;
    return switch (status) {
      400 => 'Revisa los datos ingresados.',
      401 => 'Credenciales o código incorrectos.',
      403 => 'Esta cuenta no tiene acceso a la aplicación de personal.',
      404 => 'No se encontró la cuenta solicitada.',
      429 => 'Demasiados intentos. Espera un momento e inténtalo nuevamente.',
      _ => 'Ocurrió un error del servidor ($status).',
    };
  }

  @override
  Future<LoginChallenge> login(String email, String password) async {
    final data = await _post('user-accounts/login', {
      'email': email.trim(),
      'password': password,
    });
    final id = data['challengeId']?.toString();
    if (id == null || id.isEmpty) {
      throw const AuthException(
        'El servidor no devolvió el desafío de acceso.',
      );
    }
    return LoginChallenge(
      id: id,
      maskedEmail: data['maskedEmail']?.toString() ?? email.trim(),
      expiresAt: DateTime.tryParse(data['expiresAt']?.toString() ?? ''),
    );
  }

  @override
  Future<AuthSession> verify(String challengeId, String code) async {
    final data = await _post('user-accounts/login/verify', {
      'challengeId': challengeId,
      'code': code.trim(),
    });
    final token = data['accessToken']?.toString();
    final role = data['role']?.toString();
    if (token == null || role == null) {
      throw const AuthException('La respuesta de acceso está incompleta.');
    }
    if (!{'ADMISSION_STAFF', 'SUPER_ADMIN'}.contains(role)) {
      throw const AuthException(
        'Tu cuenta no tiene un rol autorizado para esta aplicación.',
      );
    }
    final session = AuthSession(
      token: token,
      role: role,
      userId: (data['userId'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.tryParse(data['expiresAt']?.toString() ?? ''),
    );
    await _storage.write(key: 'access_token', value: session.token);
    await _storage.write(key: 'user_role', value: session.role);
    await _storage.write(key: 'user_id', value: session.userId.toString());
    if (session.expiresAt != null) {
      await _storage.write(
        key: 'expires_at',
        value: session.expiresAt!.toIso8601String(),
      );
    }
    return session;
  }

  @override
  Future<void> resend(String challengeId) async =>
      _post('user-accounts/login/resend', {'challengeId': challengeId});

  @override
  Future<PasswordRecoveryChallenge> requestPasswordRecoveryCode(
    String email,
  ) async {
    final data = await _post('user-accounts/recover-password/code', {
      'email': email.trim(),
    });
    final id = data['challengeId']?.toString();
    if (id == null || id.isEmpty) {
      throw const AuthException('No se pudo iniciar la recuperación.');
    }
    return PasswordRecoveryChallenge(
      id: id,
      maskedEmail: data['maskedEmail']?.toString() ?? email.trim(),
      expiresAt: DateTime.tryParse(data['expiresAt']?.toString() ?? ''),
    );
  }

  @override
  Future<PasswordResetGrant> verifyPasswordRecoveryCode(
    String challengeId,
    String code,
  ) async {
    final data = await _post('user-accounts/recover-password/code/verify', {
      'challengeId': challengeId,
      'code': code.trim(),
    });
    final token = data['resetToken']?.toString();
    if (token == null || token.isEmpty) {
      throw const AuthException('No se pudo validar el código.');
    }
    return PasswordResetGrant(
      token: token,
      expiresAt: DateTime.tryParse(data['expiresAt']?.toString() ?? ''),
    );
  }

  @override
  Future<void> resetPassword(
    String token,
    String password,
    String confirmation,
  ) async => _post('user-accounts/recover-password/code/reset', {
    'resetToken': token,
    'password': password,
    'confirmPassword': confirmation,
  });

  @override
  Future<AuthSession?> restoreSession() async {
    final token = await _storage.read(key: 'access_token');
    final role = await _storage.read(key: 'user_role');
    final id = int.tryParse(await _storage.read(key: 'user_id') ?? '');
    final expires = DateTime.tryParse(
      await _storage.read(key: 'expires_at') ?? '',
    );
    if (token == null ||
        role == null ||
        id == null ||
        (expires != null && expires.isBefore(DateTime.now()))) {
      await _clear();
      return null;
    }
    try {
      final response = await _client.get(
        _uri('user-accounts/me'),
        headers: {..._headers, 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await _clear();
        return null;
      }
      final profile = jsonDecode(response.body) as Map<String, dynamic>;
      final serverRole = profile['role']?.toString() ?? role;
      if (!{'ADMISSION_STAFF', 'SUPER_ADMIN'}.contains(serverRole)) {
        await _clear();
        return null;
      }
      return AuthSession(
        token: token,
        role: serverRole,
        userId: id,
        expiresAt: expires,
      );
    } catch (_) {
      return AuthSession(
        token: token,
        role: role,
        userId: id,
        expiresAt: expires,
      );
    }
  }

  @override
  Future<void> logout() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      try {
        await _client.post(
          _uri('user-accounts/logout'),
          headers: {..._headers, 'Authorization': 'Bearer $token'},
        );
      } finally {
        await _clear();
      }
    } else {
      await _clear();
    }
  }

  Future<void> _clear() async => _storage.deleteAll();
}
