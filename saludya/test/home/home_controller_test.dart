import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:saludya/features/home/application/home_controller.dart';
import 'package:saludya/features/home/domain/home_models.dart';
import 'package:saludya/features/home/domain/home_repository.dart';

class PendingRepository implements HomeRepository {
  final requests = <Completer<HomeSummary>>[];
  @override
  Future<HomeSummary> getSummary(DateTime date) {
    final request = Completer<HomeSummary>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<List<HomeBooking>> getPatients(DateTime date, int timeSlotId) async =>
      [];
}

void main() {
  test('a later refresh wins when responses arrive out of order', () async {
    final repo = PendingRepository();
    final controller = HomeController(repo);
    final first = controller.load();
    final second = controller.load();
    final newest = HomeSummary(date: DateTime(2026, 11, 1), bookings: []);
    repo.requests[1].complete(newest);
    await second;
    repo.requests[0].complete(
      HomeSummary(date: DateTime(2026, 10, 31), bookings: []),
    );
    await first;
    expect(controller.summary, same(newest));
    expect(controller.loading, isFalse);
    controller.dispose();
  });
  test('completion after disposal does not notify listeners', () async {
    final repo = PendingRepository();
    final controller = HomeController(repo);
    final request = controller.load();
    controller.dispose();
    repo.requests.single.complete(
      HomeSummary(date: DateTime.now(), bookings: []),
    );
    await expectLater(request, completes);
  });
  test('refresh failure clears previously loaded private data', () async {
    final repo = PendingRepository();
    final controller = HomeController(repo);
    final first = controller.load();
    repo.requests[0].complete(HomeSummary(date: DateTime.now(), bookings: []));
    await first;
    final second = controller.load();
    repo.requests[1].completeError(
      const HomeFailure('Sesión expirada', sessionExpired: true),
    );
    await second;
    expect(controller.summary, isNull);
    expect(controller.error!.sessionExpired, isTrue);
    controller.dispose();
  });
}
