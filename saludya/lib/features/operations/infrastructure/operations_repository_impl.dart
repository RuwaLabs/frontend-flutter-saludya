import '../domain/operations_models.dart';
import '../domain/operations_repository.dart';
import 'remote/operations_api.dart';

class OperationsRepositoryImpl implements OperationsRepository {
  final OperationsApi api;

  const OperationsRepositoryImpl({required this.api});

  Map<String, dynamic> _map(dynamic value) => value as Map<String, dynamic>;
  List<dynamic> _list(dynamic value) => value as List<dynamic>;

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _time(dynamic value) => value.toString().substring(0, 5);

  @override
  Future<DashboardMetrics> getDashboard(DateTime date) async {
    final data = _map(
      await api.get('config/dashboard', query: {'date': _date(date)}),
    );
    final metrics = <String, int>{};
    for (final entry in _list(data['metrics'])) {
      final item = _map(entry);
      metrics[item['name'].toString()] = (item['value'] as num).toInt();
    }
    return DashboardMetrics(
      scheduled: metrics['scheduledToday'] ?? 0,
      pending: metrics['pendingToday'] ?? 0,
      cancelled: metrics['cancelledToday'] ?? 0,
      attended: metrics['attendedToday'] ?? 0,
      absent: metrics['absentToday'] ?? 0,
    );
  }

  @override
  Future<List<Specialty>> getSpecialties() async =>
      _list(await api.get('specialties')).map((item) {
        final data = _map(item);
        return Specialty(
          id: (data['id'] as num).toInt(),
          name: data['name']?.toString() ?? '',
          description: data['description']?.toString() ?? '',
        );
      }).toList();

  @override
  Future<List<Doctor>> getDoctors(int specialtyId) async =>
      _list(await api.get('doctors', query: {'specialtyId': '$specialtyId'}))
          .map((item) {
            final data = _map(item);
            return Doctor(
              id: (data['id'] as num).toInt(),
              specialtyId: (data['specialtyId'] as num).toInt(),
              name: data['name']?.toString() ?? '',
              lastname: data['lastname']?.toString() ?? '',
            );
          })
          .toList();

  TimeBlock _timeBlock(Map<String, dynamic> data) => TimeBlock(
    id: (data['id'] as num).toInt(),
    doctorId: (data['doctorId'] as num).toInt(),
    date: DateTime.parse(data['date'].toString()),
    startHour: _time(data['startHour']),
    endHour: _time(data['endHour']),
    room: data['room']?.toString() ?? '',
    maxCapacity: (data['maxCapacity'] as num).toInt(),
    currentBookings: (data['currentBookings'] as num).toInt(),
    status: data['status']?.toString() ?? 'AVAILABLE',
  );

  @override
  Future<List<TimeBlock>> getCalendarBlocks(
    int specialtyId,
    DateTime from,
    DateTime to,
  ) async {
    try {
      return _list(
        await api.get(
          'time-slots/calendar',
          query: {
            'specialtyId': '$specialtyId',
            'from': _date(from),
            'to': _date(to),
          },
        ),
      ).map((item) => _timeBlock(_map(item))).toList();
    } on ApiFailure catch (error) {
      if (error.statusCode != 404 && error.statusCode != 405) rethrow;
      if (_date(from) == _date(to)) {
        return _getAllBlocksForDate(specialtyId, from);
      }
      return _getAvailableCalendarDays(specialtyId, from, to);
    }
  }

  Future<List<TimeBlock>> _getAllBlocksForDate(
    int specialtyId,
    DateTime date,
  ) async {
    final doctors = await getDoctors(specialtyId);
    final slotsPerDoctor = await Future.wait(
      doctors.map(
        (doctor) async => _list(
          await api.get(
            'time-slots',
            query: {'doctorId': '${doctor.id}', 'date': _date(date)},
          ),
        ).map((item) => _timeBlock(_map(item))).toList(),
      ),
    );
    return slotsPerDoctor.expand((slots) => slots).toList()
      ..sort((a, b) => a.startHour.compareTo(b.startHour));
  }

  Future<List<TimeBlock>> _getAvailableCalendarDays(
    int specialtyId,
    DateTime from,
    DateTime to,
  ) async {
    final days = <DateTime>[];
    for (
      var date = DateTime(from.year, from.month, from.day);
      !date.isAfter(to);
      date = date.add(const Duration(days: 1))
    ) {
      days.add(date);
    }
    final slotsPerDay = await Future.wait(
      days.map(
        (date) async => _list(
          await api.get(
            'time-slots/available',
            query: {'specialtyId': '$specialtyId', 'date': _date(date)},
          ),
        ).map((item) => _timeBlock(_map(item))).toList(),
      ),
    );
    return slotsPerDay.expand((slots) => slots).toList();
  }

  @override
  Future<TimeBlock> getTimeBlock(int id) async =>
      _timeBlock(_map(await api.get('time-slots/$id')));

  Future<BookedPatient> _bookedPatient(
    dynamic value, {
    bool includeSlot = false,
  }) async {
    final data = _map(value);
    final patientId = (data['patientId'] as num).toInt();
    final timeSlotId = (data['timeSlotId'] as num).toInt();
    var patientName = 'Paciente #$patientId';
    String? slotSummary;
    try {
      final patient = _map(await api.get('patients/$patientId'));
      patientName = '${patient['name'] ?? ''} ${patient['lastname'] ?? ''}'
          .trim();
      if (patientName.isEmpty) patientName = 'Paciente #$patientId';
    } on ApiFailure {
      // Preserve the reservation in the list if the identity endpoint is unavailable.
    }
    if (includeSlot) {
      try {
        final block = await getTimeBlock(timeSlotId);
        final doctor = _map(await api.get('doctors/${block.doctorId}'));
        final specialty = _map(
          await api.get('specialties/${doctor['specialtyId']}'),
        );
        slotSummary =
            '${specialty['name']} · ${block.startHour}–${block.endHour} · ${block.room}';
      } on ApiFailure {
        slotSummary = 'Bloque #$timeSlotId · detalle no disponible';
      }
    }
    return BookedPatient(
      appointmentId: (data['id'] as num).toInt(),
      patientId: patientId,
      timeSlotId: timeSlotId,
      bookingCode: data['bookingCode']?.toString() ?? '',
      bookingOrder: (data['bookingOrder'] as num?)?.toInt() ?? 0,
      status: data['status']?.toString() ?? '',
      patientName: patientName,
      slotSummary: slotSummary,
    );
  }

  Future<List<BookedPatient>> _bookedPatients(
    dynamic value, {
    bool includeSlot = false,
  }) async => Future.wait(
    _list(value).map((item) => _bookedPatient(item, includeSlot: includeSlot)),
  );

  @override
  Future<List<BookedPatient>> getAppointmentsForBlock(int timeSlotId) async =>
      _bookedPatients(
        await api.get('appointments', query: {'timeSlotId': '$timeSlotId'}),
      );

  @override
  Future<List<BookedPatient>> getCancelledAppointments(DateTime date) async =>
      _bookedPatients(
        await api.get(
          'appointments',
          query: {'date': _date(date), 'status': 'CANCELLED'},
        ),
        includeSlot: true,
      );

  @override
  Future<TimeBlock> createTimeBlock(BlockDraft draft) async => _timeBlock(
    _map(
      await api.post('time-slots', {
        'doctorId': draft.doctorId,
        'date': _date(draft.date),
        'startHour': draft.startHour,
        'endHour': draft.endHour,
        'room': draft.room.trim(),
        'maxCapacity': draft.maxCapacity,
      }),
    ),
  );

  @override
  Future<TimeBlock> updateTimeBlock(int id, BlockChanges changes) async {
    await api.put('time-slots/$id', {
      'doctorId': changes.doctorId,
      'startHour': changes.startHour,
      'endHour': changes.endHour,
      'status': changes.status,
    });
    final current = await getTimeBlock(id);
    if (current.maxCapacity != changes.maxCapacity) {
      await api.put('time-slots/$id/capacity', {
        'maxCapacity': changes.maxCapacity,
      });
    }
    return getTimeBlock(id);
  }

  @override
  Future<AttendanceQueue?> getAttendanceQueue(
    int timeSlotId,
    DateTime date,
  ) async {
    try {
      final data = _map(
        await api.get(
          'attendance-queues',
          query: {'timeSlotId': '$timeSlotId', 'date': _date(date)},
        ),
      );
      return AttendanceQueue(
        id: (data['id'] as num).toInt(),
        timeSlotId: (data['timeSlotId'] as num).toInt(),
        date: DateTime.parse(data['date'].toString()),
        status: data['status']?.toString() ?? 'OPEN',
      );
    } on ApiFailure catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<QueueEntry>> getQueueEntries(int queueId) async {
    try {
      return _list(
        await api.get('attendance-queues/$queueId/entries/administrative'),
      ).map((item) => _administrativeQueueEntry(_map(item))).toList();
    } on ApiFailure catch (error) {
      if (error.statusCode != 404 && error.statusCode != 405) rethrow;
      return _loadQueueEntriesFromExistingEndpoints(queueId);
    }
  }

  QueueEntry _administrativeQueueEntry(Map<String, dynamic> data) => QueueEntry(
    id: (data['id'] as num).toInt(),
    attendanceQueueId: (data['attendanceQueueId'] as num).toInt(),
    checkInId: (data['checkInId'] as num).toInt(),
    appointmentId: (data['appointmentId'] as num).toInt(),
    patientId: (data['patientId'] as num).toInt(),
    bookingCode: data['bookingCode']?.toString() ?? '',
    patientName: data['patientName']?.toString() ?? '',
    position: (data['position'] as num).toInt(),
    status: data['status']?.toString() ?? '',
    calledAt: DateTime.tryParse(data['calledAt']?.toString() ?? ''),
    attendedAt: DateTime.tryParse(data['attendedAt']?.toString() ?? ''),
  );

  Future<List<QueueEntry>> _loadQueueEntriesFromExistingEndpoints(
    int queueId,
  ) async {
    final entries = _list(await api.get('attendance-queues/$queueId/entries'));
    return Future.wait(
      entries.map((item) async {
        final entry = _map(item);
        final checkIn = _map(await api.get('check-ins/${entry['checkInId']}'));
        final appointmentId = (checkIn['appointmentId'] as num).toInt();
        final appointment = _map(await api.get('appointments/$appointmentId'));
        final patientId = (appointment['patientId'] as num).toInt();
        var patientName = 'Paciente #$patientId';
        try {
          final patient = _map(await api.get('patients/$patientId'));
          patientName = '${patient['name'] ?? ''} ${patient['lastname'] ?? ''}'
              .trim();
        } on ApiFailure {
          // Preserve the queue row even if the patient lookup cannot be completed.
        }
        if (patientName.isEmpty) patientName = 'Paciente #$patientId';
        return QueueEntry(
          id: (entry['id'] as num).toInt(),
          attendanceQueueId: (entry['attendanceQueueId'] as num).toInt(),
          checkInId: (entry['checkInId'] as num).toInt(),
          appointmentId: appointmentId,
          patientId: patientId,
          bookingCode:
              checkIn['bookingCode']?.toString() ??
              appointment['bookingCode']?.toString() ??
              '',
          patientName: patientName,
          position: (entry['position'] as num).toInt(),
          status: entry['status']?.toString() ?? '',
          calledAt: DateTime.tryParse(entry['calledAt']?.toString() ?? ''),
          attendedAt: DateTime.tryParse(entry['attendedAt']?.toString() ?? ''),
        );
      }),
    );
  }

  @override
  Future<ArrivalReceipt> registerArrival(String bookingCode) async {
    final data = _map(
      await api.post('check-ins/code', {
        'bookingCode': bookingCode.trim().toUpperCase(),
      }),
    );
    return ArrivalReceipt(
      checkInId: (data['checkInId'] as num).toInt(),
      appointmentId: (data['appointmentId'] as num).toInt(),
      queueEntryId: (data['queueEntryId'] as num).toInt(),
      position: (data['position'] as num).toInt(),
      totalInQueue: (data['totalInQueue'] as num).toInt(),
    );
  }

  @override
  Future<void> callNext(int queueId) async =>
      api.post('attendance-queues/$queueId/call-next');

  @override
  Future<void> startAttention(int queueEntryId) async =>
      api.post('queue-entries/$queueEntryId/start');

  @override
  Future<void> finishAttention(int queueEntryId) async =>
      api.post('queue-entries/$queueEntryId/finish');

  @override
  Future<void> markAbsent(int queueEntryId) async =>
      api.post('queue-entries/$queueEntryId/absent');
}
