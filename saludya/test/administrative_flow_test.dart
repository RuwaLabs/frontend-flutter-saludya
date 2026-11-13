import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:saludya/features/main/main_page.dart';
import 'package:saludya/features/operations/domain/operations_models.dart';
import 'package:saludya/features/operations/domain/operations_repository.dart';
import 'package:saludya/features/settings/application/get_establishment_settings_use_case.dart';
import 'package:saludya/features/settings/domain/establishment_settings.dart';
import 'package:saludya/features/settings/domain/settings_repository.dart';

void main() {
  testWidgets(
    'staff can open the queue, register a code and call the next patient manually',
    (tester) async {
      final locator = GetIt.instance;
      await locator.reset();
      final repository = _FakeOperationsRepository();
      locator.registerSingleton<OperationsRepository>(repository);
      locator.registerSingleton<GetEstablishmentSettingsUseCase>(
        GetEstablishmentSettingsUseCase(repository: _FakeSettingsRepository()),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MainPage(role: 'ADMISSION_STAFF', onLogout: () async {}),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Citas de hoy'), findsOneWidget);

      await tester.tap(find.text('Calendario').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medicina general'));
      await tester.pumpAndSettle();
      expect(find.text('Agenda operativa'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('09:00–09:30'),
        find.byType(ListView).last,
        const Offset(0, -320),
      );
      expect(find.text('09:00–09:30'), findsOneWidget);
      await tester.tap(find.text('Ver detalle →'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle del bloque'), findsOneWidget);
      await tester.tap(find.text('Ver cola presencial'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Citas').last);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Sin pacientes en espera'), findsOneWidget);

      await tester.tap(find.text('Registrar llegada por código').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'sal-ab12cd34ef');
      await tester.tap(find.text('Validar código'));
      await tester.pumpAndSettle();
      expect(repository.lastSubmittedCode, 'SAL-AB12CD34EF');
      expect(find.text('Llegada confirmada'), findsOneWidget);
      await tester.tap(find.text('Ver cola'));
      await tester.pumpAndSettle();
      expect(find.text('María Pérez · SAL-AB12CD34EF'), findsOneWidget);

      await tester.dragUntilVisible(
        find.text('Llamar al siguiente'),
        find.byType(ListView).last,
        const Offset(0, -300),
      );
      await tester.tap(find.text('Llamar al siguiente'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(repository.callNextCount, 1);
      expect(find.text('PACIENTE LLAMADO'), findsOneWidget);

      await tester.tap(find.text('Marcar ausente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar ausencia'));
      await tester.pumpAndSettle();
      expect(
        repository.callNextCount,
        1,
        reason: 'absence must not call the next person automatically',
      );
      expect(find.text('Ausente'), findsOneWidget);

      await tester.dragUntilVisible(
        find.text('Llamar al siguiente'),
        find.byType(ListView).last,
        const Offset(0, -300),
      );
      await tester.tap(find.text('Llamar al siguiente'));
      await tester.pumpAndSettle();
      expect(repository.callNextCount, 2);
      expect(find.text('PACIENTE LLAMADO'), findsOneWidget);

      await tester.tap(find.text('Iniciar atención'));
      await tester.pumpAndSettle();
      expect(repository.lastQueueStatus, 'IN_ATTENTION');
      await tester.tap(find.text('Finalizar atención'));
      await tester.pumpAndSettle();
      expect(repository.lastQueueStatus, 'ATTENDED');

      await tester.pumpWidget(const SizedBox.shrink());
      await locator.reset();
    },
  );
}

class _FakeOperationsRepository implements OperationsRepository {
  bool _arrivalRegistered = false;
  final List<String> _queueStatuses = ['WAITING', 'WAITING'];
  String? lastSubmittedCode;
  int callNextCount = 0;

  String? get lastQueueStatus => _queueStatuses.firstWhere(
    (status) =>
        status == 'CALLED' || status == 'IN_ATTENTION' || status == 'ATTENDED',
    orElse: () => '',
  );

  final _block = TimeBlock(
    id: 9,
    doctorId: 4,
    date: DateTime.now(),
    startHour: '09:00',
    endHour: '09:30',
    room: 'Consultorio 01',
    maxCapacity: 8,
    currentBookings: 1,
    status: 'AVAILABLE',
  );

  @override
  Future<DashboardMetrics> getDashboard(DateTime date) async =>
      const DashboardMetrics(
        scheduled: 1,
        pending: 1,
        cancelled: 0,
        attended: 0,
        absent: 0,
      );

  @override
  Future<List<Specialty>> getSpecialties() async => const [
    Specialty(
      id: 1,
      name: 'Medicina general',
      description: 'Atención primaria',
    ),
  ];

  @override
  Future<List<Doctor>> getDoctors(int specialtyId) async => const [
    Doctor(id: 4, specialtyId: 1, name: 'Ana', lastname: 'Rojas'),
  ];

  @override
  Future<List<TimeBlock>> getCalendarBlocks(
    int specialtyId,
    DateTime from,
    DateTime to,
  ) async => [_block];

  @override
  Future<TimeBlock> getTimeBlock(int id) async => _block;

  @override
  Future<List<BookedPatient>> getAppointmentsForBlock(int timeSlotId) async =>
      const [];

  @override
  Future<List<BookedPatient>> getCancelledAppointments(DateTime date) async =>
      const [];

  @override
  Future<TimeBlock> createTimeBlock(BlockDraft draft) async => _block;

  @override
  Future<TimeBlock> updateTimeBlock(int id, BlockChanges changes) async =>
      _block;

  @override
  Future<AttendanceQueue?> getAttendanceQueue(
    int timeSlotId,
    DateTime date,
  ) async => _arrivalRegistered
      ? AttendanceQueue(
          id: 12,
          timeSlotId: timeSlotId,
          date: date,
          status: 'OPEN',
        )
      : null;

  @override
  Future<List<QueueEntry>> getQueueEntries(int queueId) async =>
      !_arrivalRegistered
      ? const []
      : List.generate(_queueStatuses.length, (index) {
          final status = _queueStatuses[index];
          return QueueEntry(
            id: 22 + index,
            attendanceQueueId: queueId,
            checkInId: 18 + index,
            appointmentId: 21 + index,
            patientId: 6 + index,
            bookingCode: index == 0 ? 'SAL-AB12CD34EF' : 'SAL-2ND8C0DE00',
            patientName: index == 0 ? 'María Pérez' : 'José Ramos',
            position: index + 1,
            status: status,
            calledAt: status == 'CALLED' ? DateTime.now() : null,
            attendedAt: status == 'ATTENDED' ? DateTime.now() : null,
          );
        });

  @override
  Future<ArrivalReceipt> registerArrival(String bookingCode) async {
    lastSubmittedCode = bookingCode.trim().toUpperCase();
    _arrivalRegistered = true;
    return const ArrivalReceipt(
      checkInId: 18,
      appointmentId: 21,
      queueEntryId: 22,
      position: 1,
      totalInQueue: 2,
    );
  }

  @override
  Future<void> callNext(int queueId) async {
    final index = _queueStatuses.indexOf('WAITING');
    if (index >= 0) _queueStatuses[index] = 'CALLED';
    callNextCount++;
  }

  @override
  Future<void> startAttention(int queueEntryId) async {
    _queueStatuses[queueEntryId - 22] = 'IN_ATTENTION';
  }

  @override
  Future<void> finishAttention(int queueEntryId) async {
    _queueStatuses[queueEntryId - 22] = 'ATTENDED';
  }

  @override
  Future<void> markAbsent(int queueEntryId) async {
    _queueStatuses[queueEntryId - 22] = 'ABSENT';
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  final _settings = const EstablishmentSettings(
    maxCapacityPerSlot: 8,
    intervalDurationMinutes: 30,
    bookingOrderScope: BookingOrderScope.global,
    checkInToleranceMinutes: 15,
    postCallToleranceMinutes: 5,
    reassignmentResponseTimeoutMin: 5,
    bookingCutoffTime: '18:00',
    cancellationDeadlineHours: 24,
    attendanceQueueVisible: true,
  );

  @override
  Future<EstablishmentSettings> getSettings() async => _settings;

  @override
  Future<void> updateSettings(EstablishmentSettings settings) async {}
}
