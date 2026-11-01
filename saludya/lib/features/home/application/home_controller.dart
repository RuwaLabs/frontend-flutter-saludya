import 'package:flutter/foundation.dart';
import '../domain/home_models.dart';
import '../domain/home_repository.dart';

class HomeController extends ChangeNotifier {
  HomeController(this.repository, {DateTime Function()? clock}) : clock = clock ?? DateTime.now;
  final HomeRepository repository;
  final DateTime Function() clock;
  HomeSummary? summary;
  HomeFailure? error;
  bool loading = false;
  bool _disposed = false;
  int _request = 0;

  Future<void> load() async {
    final request = ++_request;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await repository.getSummary(clock());
      if (_disposed || request != _request) return;
      summary = result;
    } on HomeFailure catch (failure) {
      if (_disposed || request != _request) return;
      error = failure;
      summary = null;
    } catch (_) {
      if (_disposed || request != _request) return;
      error = const HomeFailure('No pudimos cargar el inicio. Vuelve a intentar.');
      summary = null;
    } finally {
      if (!_disposed && request == _request) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() { _disposed = true; super.dispose(); }
}
