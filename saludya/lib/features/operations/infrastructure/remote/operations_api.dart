import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../domain/operations_models.dart';

class OperationsApi {
  final http.Client _client;
  final Future<String?> Function() _tokenProvider;
  final String _baseUrl;

  OperationsApi({
    http.Client? client,
    required this._tokenProvider,
    String baseUrl = AppConfig.apiBaseUrl,
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _send('PUT', path, body: body);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final token = await _tokenProvider();
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer ${token.trim()}',
    };
    final uri = Uri.parse('$_baseUrl/${path.replaceFirst(RegExp(r'^/+'), '')}')
        .replace(queryParameters: query);

    try {
      final request = switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'POST' => _client.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        ),
        'PUT' => _client.put(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        ),
        _ => throw ArgumentError.value(
          method,
          'method',
          'Unsupported HTTP method',
        ),
      };
      final response = await request.timeout(const Duration(seconds: 20));
      final decoded = response.body.trim().isEmpty
          ? null
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final map = decoded is Map<String, dynamic>
            ? decoded
            : const <String, dynamic>{};
        final message = (map['message'] ?? map['detail'] ?? map['error'])
            ?.toString();
        throw ApiFailure(
          response.statusCode,
          message?.isNotEmpty == true
              ? message!
              : _defaultMessage(response.statusCode),
        );
      }
      return decoded;
    } on ApiFailure {
      rethrow;
    } on TimeoutException {
      throw const ApiFailure(
        0,
        'El servidor tardó demasiado. Inténtalo nuevamente.',
      );
    } on SocketException {
      throw const ApiFailure(0, 'No se pudo conectar con el servidor.');
    } on http.ClientException {
      throw const ApiFailure(
        0,
        'Ocurrió un problema de comunicación con el servidor.',
      );
    } on FormatException {
      throw const ApiFailure(
        0,
        'El servidor devolvió una respuesta no válida.',
      );
    }
  }

  String _defaultMessage(int status) => switch (status) {
    400 => 'Revisa los datos ingresados.',
    401 => 'La sesión venció. Inicia sesión nuevamente.',
    403 => 'Tu cuenta no tiene permiso para esta operación.',
    404 => 'No se encontró la información solicitada.',
    409 => 'El cambio entra en conflicto con el estado actual.',
    >= 500 => 'El servidor presenta un problema. Inténtalo más tarde.',
    _ => 'La operación no se pudo completar ($status).',
  };

  void close() => _client.close();
}
