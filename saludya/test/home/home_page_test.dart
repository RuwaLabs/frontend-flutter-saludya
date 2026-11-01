import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saludya/features/home/application/home_controller.dart';
import 'package:saludya/features/home/domain/home_models.dart';
import 'package:saludya/features/home/domain/home_repository.dart';
import 'package:saludya/features/home/presentation/home_page.dart';

class FakeRepository implements HomeRepository {
  bool fails = false;
  @override
  Future<HomeSummary> getSummary(DateTime date) async {
    if (fails) throw const HomeFailure('Sin conexión');
    return HomeSummary(
      date: date,
      bookings: [
        HomeBooking(
          id: 1,
          timeSlotId: 10,
          patientName: 'Paciente Prueba',
          specialty: 'Medicina general',
          code: 'SY-1',
          date: date,
          startHour: '09:00',
          endHour: '09:30',
          status: 'CONFIRMED',
          updatedAt: date,
        ),
        HomeBooking(
          id: 2,
          timeSlotId: 10,
          patientName: 'Paciente Cancelado',
          specialty: 'Pediatría',
          code: 'SY-2',
          date: date,
          startHour: '10:00',
          endHour: '10:30',
          status: 'CANCELLED',
          updatedAt: date,
        ),
      ],
    );
  }

  @override
  Future<List<HomeBooking>> getPatients(DateTime date, int timeSlotId) async =>
      [
        (await getSummary(date)).pending.single
            .withArrival(ArrivalStatus.registered),
      ];
}

void main() {
  late FakeRepository repo;
  late HomeController controller;
  late List<HomeDestination> navigation;
  setUp(() {
    repo = FakeRepository();
    controller = HomeController(repo, clock: () => DateTime(2026, 10, 31));
    navigation = [];
  });
  tearDown(() => controller.dispose());
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          controller: controller,
          staffName: 'Diego',
          onNavigate: navigation.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows live totals and opens cancelled appointments', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Hola, Diego'), findsOneWidget);
    expect(find.text('1 reserva para hoy'), findsOneWidget);
    await tester.tap(find.text('Ver detalle →'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Paciente Cancelado'), findsOneWidget);
    expect(find.text('Paciente Prueba'), findsNothing);
  });
  testWidgets('opens reserved patients for a selected time slot', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Ver pacientes con reserva →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver pacientes con reserva'));
    await tester.pumpAndSettle();
    expect(find.text('Paciente Prueba'), findsOneWidget);
    expect(find.text('Llegada registrada'), findsOneWidget);
  });
  testWidgets('retry recovers after a load failure', (tester) async {
    repo.fails = true;
    await open(tester);
    expect(find.text('Sin conexión'), findsOneWidget);
    repo.fails = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Citas pendientes'), findsOneWidget);
  });
  testWidgets('delegates calendar and arrival navigation', (tester) async {
    await open(tester);
    await tester.tap(find.text('Ver calendario →'));
    await tester.ensureVisible(find.text('Registrar llegada'));
    await tester.tap(find.text('Registrar llegada'));
    expect(navigation, [
      HomeDestination.calendar,
      HomeDestination.registerArrival,
    ]);
  });
  testWidgets(
    'small screens and large text remain scrollable without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: HomePage(controller: controller, onNavigate: navigation.add),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Ver cola de atención'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
