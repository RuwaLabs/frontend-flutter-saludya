import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:saludya/features/settings/infrastructure/remote/settings_dto.dart';

class SettingsApiException implements Exception {
  final int statusCode;
  final String? code;
  final String message;

  const SettingsApiException({
    required this.statusCode,
    this.code,
    required this.message,
  });

  @override
  String toString() => message;
}

class SettingsApi {
  static const Duration requestTimeout = Duration(seconds: 15);

  final http.Client client;
  final String baseUrl;
  final Future<String?> Function()? tokenProvider;

  SettingsApi({required this.baseUrl, http.Client? client, this.tokenProvider})
    : client = client ?? http.Client();

  Uri get _configurationUri {
    final normalizedBaseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');

    return Uri.parse('$normalizedBaseUrl/api/v1/config');
  }

  Future<Map<String, String>> _headers({
    bool includeContentType = false,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};

    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }

    final token = await tokenProvider?.call();

    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    return headers;
  }

  Never _throwApiException(
    http.Response response, {
    required String operation,
  }) {
    String? code;
    String? message;

    try {
      final body = jsonDecode(response.body);

      if (body is Map<String, dynamic>) {
        code = body['code'] as String?;
        message = body['message'] as String?;
      }
    } catch (_) {
      // La respuesta no contiene JSON válido.
    }

    message ??= switch (response.statusCode) {
      401 => 'La sesión no está autenticada.',
      403 => 'No tienes permisos para realizar esta operación.',
      404 => 'No se encontró la configuración solicitada.',
      >= 500 => 'El servidor presenta un problema. Inténtalo más tarde.',
      _ => 'No se pudo $operation la configuración.',
    };

    throw SettingsApiException(
      statusCode: response.statusCode,
      code: code,
      message: message,
    );
  }

  Future<EstablishmentSettingsDto> getSettings() async {
    final response = await client
        .get(_configurationUri, headers: await _headers())
        .timeout(requestTimeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      return EstablishmentSettingsDto.fromJson(json);
    }

    _throwApiException(response, operation: 'obtener');
  }

  Future<EstablishmentSettingsDto> updateSettings(
    EstablishmentSettingsDto settings,
  ) async {
    final response = await client
        .put(
          _configurationUri,
          headers: await _headers(includeContentType: true),
          body: jsonEncode(settings.toJson()),
        )
        .timeout(requestTimeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      return EstablishmentSettingsDto.fromJson(json);
    }

    _throwApiException(response, operation: 'actualizar');
  }

  void dispose() {
    client.close();
  }
}
