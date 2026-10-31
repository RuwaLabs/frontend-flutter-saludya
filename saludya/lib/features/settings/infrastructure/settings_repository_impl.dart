import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:saludya/features/settings/domain/establishment_settings.dart';
import 'package:saludya/features/settings/domain/settings_repository.dart';
import 'package:saludya/features/settings/infrastructure/remote/settings_api.dart';
import 'package:saludya/features/settings/infrastructure/remote/settings_dto.dart';

class SettingsRepositoryException implements Exception {
  final String message;
  final int? statusCode;

  const SettingsRepositoryException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsApi api;

  SettingsRepositoryImpl({required this.api});

  @override
  Future<EstablishmentSettings> getSettings() async {
    try {
      final settingsDto = await api.getSettings();

      return settingsDto.toDomain();
    } on SettingsApiException catch (error) {
      throw _translateApiException(error);
    } on SocketException {
      throw const SettingsRepositoryException(
        message:
            'No se pudo conectar con el servidor. '
            'Comprueba tu conexión a Internet.',
      );
    } on http.ClientException {
      throw const SettingsRepositoryException(
        message: 'Ocurrió un problema de comunicación con el servidor.',
      );
    } on TimeoutException {
      throw const SettingsRepositoryException(
        message: 'El servidor tardó demasiado en responder.',
      );
    } on FormatException {
      throw const SettingsRepositoryException(
        message: 'El servidor devolvió datos con un formato no válido.',
      );
    }
  }

  @override
  Future<void> updateSettings(EstablishmentSettings settings) async {
    try {
      final settingsDto = EstablishmentSettingsDto.fromDomain(settings);

      await api.updateSettings(settingsDto);
    } on SettingsApiException catch (error) {
      throw _translateApiException(error);
    } on SocketException {
      throw const SettingsRepositoryException(
        message:
            'No se pudo conectar con el servidor. '
            'Comprueba tu conexión a Internet.',
      );
    } on http.ClientException {
      throw const SettingsRepositoryException(
        message: 'Ocurrió un problema de comunicación con el servidor.',
      );
    } on TimeoutException {
      throw const SettingsRepositoryException(
        message: 'El servidor tardó demasiado en responder.',
      );
    } on FormatException {
      throw const SettingsRepositoryException(
        message: 'El servidor devolvió datos con un formato no válido.',
      );
    }
  }

  SettingsRepositoryException _translateApiException(
    SettingsApiException error,
  ) {
    return SettingsRepositoryException(
      statusCode: error.statusCode,
      message: switch (error.statusCode) {
        401 => 'Tu sesión no está autenticada. Inicia sesión nuevamente.',
        403 => 'No tienes permisos para realizar esta operación.',
        404 => 'No se encontró la configuración del establecimiento.',
        >= 500 => 'El servidor presenta un problema. Inténtalo más tarde.',
        _ => error.message,
      },
    );
  }
}
