import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/arrival_result.dart';
import '../domain/qr_repository.dart';
import '../domain/qr_ticket.dart';
import 'remote/qr_api.dart';
import 'remote/qr_dto.dart';

/// Implementación contra backend-saludya.
///
/// El backend devuelve las entradas de cola "delgadas" (solo ids y estado),
/// así que aquí se completan con el check-in (especialidad, doctor, sala,
/// hora de llegada) y el paciente (nombre). Se cachean para no repetir llamadas.
class QrRepositoryImpl implements QrRepository {
  QrRepositoryImpl({required this.api});

  final QrApi api;

  int? _queueId; // attendance_queues.id mostrado
  int? _preferredSlotId; // bloque del último check-in registrado
  int _postCallTolerance = 5; // hospital_configurations.post_call_tolerance_minutes
  final _checkIns = <int, CheckInDto>{};
  final _patientNames = <int, String>{}; // appointmentId -> nombre

  // ---------------------------------------------------------------- helpers
  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on QrApiException catch (e) {
      throw QrException(
        switch (e.statusCode) {
          401 => 'Tu sesión expiró. Inicia sesión nuevamente.',
          403 => 'No tienes permisos para esta operación.',
          >= 500 => 'El servidor presenta un problema. Inténtalo más tarde.',
          _ => e.message,
        },
        code: e.code,
      );
    } on SocketException {
      throw const QrException('No se pudo conectar con el servidor. Revisa tu conexión.');
    } on http.ClientException {
      throw const QrException('Ocurrió un problema de comunicación con el servidor.');
    } on TimeoutException {
      throw const QrException('El servidor tardó demasiado en responder.');
    } on FormatException {
      throw const QrException('El servidor devolvió datos con un formato no válido.');
    }
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<CheckInDto> _checkIn(int id) async =>
      _checkIns[id] ??= CheckInDto.fromJson(await api.getCheckIn(id));

  Future<String> _patientName(int appointmentId) async {
    final cached = _patientNames[appointmentId];
    if (cached != null) return cached;
    final appt = AppointmentDto.fromJson(await api.getAppointment(appointmentId));
    final name = patientFullName(await api.getPatient(appt.patientId));
    return _patientNames[appointmentId] = name;
  }

  Future<QrTicket> _toTicket(QueueEntryDto e) async {
    final ci = await _checkIn(e.checkInId);
    final name = await _patientName(ci.appointmentId);
    return QrTicket(
      id: '${e.id}',
      position: e.position,
      code: turnCode(e.position),
      patientName: name,
      arrivedAt: ci.checkedInAt,
      status: e.ticketStatus,
      specialty: ci.specialtyName,
      doctor: ci.doctorName,
      calledAt: e.calledAt,
      arrivalDeadline: e.calledAt?.add(Duration(minutes: _postCallTolerance)),
    );
  }

  Future<void> _loadConfig() async {
    try {
      final c = await api.getConfig();
      _postCallTolerance = (c['postCallToleranceMinutes'] as num?)?.toInt() ?? _postCallTolerance;
    } on QrApiException {
      // Si falla la configuración, se usa el último valor conocido.
    }
  }

  /// Elige el bloque (time_slot) de hoy: el del último check-in, el que tiene
  /// pacientes activos en cola, el que está en curso, o el más cercano.
  Future<(TimeSlotDto, Map<String, dynamic>?)?> _resolveSlot(String date) async {
    final appts = (await api.getAppointmentsByDate(date))
        .map((j) => AppointmentDto.fromJson(j as Map<String, dynamic>))
        .where((a) => a.status != 'CANCELLED');
    final slotIds = {...appts.map((a) => a.timeSlotId), if (_preferredSlotId != null) _preferredSlotId!};
    if (slotIds.isEmpty) return null;

    final slots = await Future.wait(slotIds.map((id) async => TimeSlotDto.fromJson(await api.getTimeSlot(id))));
    final now = DateTime.now();
    final nowHm = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    int rank(TimeSlotDto s) {
      if (s.id == _preferredSlotId) return 0;
      if (s.start.compareTo(nowHm) <= 0 && s.end.compareTo(nowHm) > 0) return 1; // en curso
      if (s.start.compareTo(nowHm) > 0) return 2; // próximo
      return 3; // ya pasó
    }

    slots.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      return rank(a) == 3 ? b.start.compareTo(a.start) : a.start.compareTo(b.start);
    });

    // Prioriza un bloque que tenga gente esperando / llamada / en atención.
    (TimeSlotDto, Map<String, dynamic>?)? first;
    for (final s in slots) {
      final q = await api.findAttendanceQueue(s.id, date);
      first ??= (s, q);
      if (s.id == _preferredSlotId && q != null) return (s, q);
      if (q != null) {
        final entries = await api.getQueueEntries((q['id'] as num).toInt());
        final active = entries.any((e) => const ['WAITING', 'CALLED', 'IN_ATTENTION'].contains(e['status']));
        if (active) return (s, q);
      }
    }
    return first;
  }

  // ---------------------------------------------------------------- QrRepository
  @override
  Future<QrSnapshot> getQr() => _guard(() async {
        final date = _today();
        await _loadConfig();
        final resolved = await _resolveSlot(date);
        if (resolved == null) {
          _queueId = null;
          return QrSnapshot(date: DateTime.now(), block: 'Sin bloques hoy', tickets: const []);
        }
        final (slot, queue) = resolved;
        final block = '${slot.room.isNotEmpty ? '${slot.room} · ' : ''}${slot.start}–${slot.end}';
        _queueId = queue == null ? null : (queue['id'] as num).toInt();
        if (_queueId == null) {
          return QrSnapshot(date: DateTime.now(), block: block, tickets: const []);
        }
        final entries = (await api.getQueueEntries(_queueId!))
            .map((j) => QueueEntryDto.fromJson(j as Map<String, dynamic>))
            .toList();
        final tickets = await Future.wait(entries.map(_toTicket));
        return QrSnapshot(date: DateTime.now(), block: block, tickets: tickets);
      });

  @override
  Future<QrTicket> callNext() => _guard(() async {
        if (_queueId == null) throw const QrException('No hay pacientes en espera.');
        return _toTicket(QueueEntryDto.fromJson(await api.callNext(_queueId!)));
      });

  @override
  Future<QrTicket> startAttention(String id) =>
      _guard(() async => _toTicket(QueueEntryDto.fromJson(await api.startAttention(int.parse(id)))));

  @override
  Future<QrTicket> markAbsent(String id) => _guard(() async {
        await api.markAbsent(int.parse(id));
        return _toTicket(QueueEntryDto.fromJson(await api.getQueueEntry(int.parse(id))));
      });

  @override
  Future<QrTicket> finishAttention(String id) =>
      _guard(() async => _toTicket(QueueEntryDto.fromJson(await api.finishAttention(int.parse(id)))));

  /// Acepta lo que lea el escáner o lo que escriba el personal:
  /// - token QR firmado (JWT, tiene puntos) -> POST /check-ins/qr
  /// - código de reserva (SAL-XXXXXXXXXX)    -> POST /check-ins/code
  @override
  Future<ArrivalResult> registerArrival(String raw) => _guard(() async {
        final value = raw.trim();
        final isQrToken = value.split('.').length == 3 && value.length > 40;
        final result = CheckInResultDto.fromJson(
          isQrToken ? await api.checkInByQr(value) : await api.checkInByCode(value.toUpperCase()),
        );

        final appt = AppointmentDto.fromJson(await api.getAppointment(result.appointmentId));
        _preferredSlotId = appt.timeSlotId; // la cola mostrará este bloque

        final ticket = await _toTicket(QueueEntryDto.fromJson(await api.getQueueEntry(result.queueEntryId)));
        final ci = await _checkIn(result.checkInId);
        return ArrivalResult(
          reservationCode: ci.bookingCode,
          patientName: ticket.patientName,
          arrivedAt: ci.checkedInAt,
          specialty: ci.specialtyName,
          doctor: ci.doctorName,
          room: ci.room,
          ticket: ticket,
        );
      });
}
