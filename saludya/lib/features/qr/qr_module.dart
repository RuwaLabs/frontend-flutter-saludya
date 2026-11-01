import 'application/qr_controller.dart';
import 'infrastructure/qr_local_repository.dart';
import 'infrastructure/qr_repository_impl.dart';
import 'infrastructure/remote/qr_api.dart';

QrController buildQrController({
  String baseUrl = 'http://3.129.217.49:8080',
  bool useLocalData = false,
  Future<String?> Function()? tokenProvider,
}) {
  if (useLocalData) return QrController(QrLocalRepository());

  final api = QrApi(baseUrl: baseUrl, tokenProvider: tokenProvider);
  return QrController(QrRepositoryImpl(api: api));
}