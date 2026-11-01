import 'package:http/http.dart' as http;

import 'application/home_controller.dart';
import 'infrastructure/home_api_repository.dart';

// The authenticated shell supplies its session token; Home never stores credentials.
HomeController buildHomeController({
  required http.Client client,
  required Future<String?> Function() tokenProvider,
  String? baseUrl,
}) => HomeController(
  HomeApiRepository(
    client: client,
    tokenProvider: tokenProvider,
    baseUrl:
        baseUrl ??
        const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://3.129.217.49:8080/api/v1',
        ),
  ),
);
