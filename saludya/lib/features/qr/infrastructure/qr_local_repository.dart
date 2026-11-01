import '../domain/arrival_result.dart';
import '../domain/qr_repository.dart';
import '../domain/qr_ticket.dart';

/// Copia en memoria de las tablas de la BD que usa este módulo.
/// Sirve para probar la app SIN backend; replica las mismas reglas que
/// aplica backend-saludya. Úsala solo para probar sin servidor. Los datos se reinician al cerrar la app.

class _Appointment {
  _Appointment(this.id, this.patientName);
  final int id; // appointments.id
  final String patientName;
  String status = 'RESERVED'; // RESERVED | CONFIRMED | ABSENT | ATTENDED ...
}

class QrLocalRepository implements QrRepository {
  QrLocalRepository() {
    final now = DateTime.now();
    _slotDate = DateTime(now.year, now.month, now.day);
    // time_slot: el bloque actual de 2 h
    _slotStart = DateTime(now.year, now.month, now.day, now.hour + 1); // próximo bloque
    _slotEnd = _slotStart.add(const Duration(hours: 2));
    for (final a in [
      _Appointment(140, 'María Pérez'),
      _Appointment(141, 'José Ramos'),
      _Appointment(142, 'Lucía Torres'),
      _Appointment(143, 'Carlos Díaz'),
      _Appointment(144, 'Ana Flores'),
    ]) {
      _appointments['SAL-${a.id.toString().padLeft(10, '0')}'] = a;
    }
  }

  // hospital_configurations
  static const postCallToleranceMinutes = 5;
  static const checkInToleranceMinutes = 15;

  // specialties / doctors
  static const _specialty = 'Medicina general';
  static const _doctor = 'Dr. Juan Ramos';

  late final DateTime _slotDate;
  late final DateTime _slotStart;
  late final DateTime _slotEnd;
  final _appointments = <String, _Appointment>{};
  final _entries = <QrTicket>[]; // queue_entries
  final _entryAppointment = <String, _Appointment>{};
  static const _latency = Duration(milliseconds: 300);

  /// Códigos de prueba para escribir en "Ingresar código manualmente".
  List<String> get sampleCodes => _appointments.keys.toList();

  String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  QrTicket _find(String id) => _entries.firstWhere((t) => t.id == id,
      orElse: () => throw const QrException('Turno no encontrado.'));

  QrTicket _replace(QrTicket old, TicketStatus status, {DateTime? calledAt}) {
    final called = calledAt ?? old.calledAt;
    final t = QrTicket(
      id: old.id,
      position: old.position,
      code: old.code,
      patientName: old.patientName,
      arrivedAt: old.arrivedAt,
      status: status,
      specialty: old.specialty,
      doctor: old.doctor,
      calledAt: called,
      arrivalDeadline:
          called?.add(const Duration(minutes: postCallToleranceMinutes)),
    );
    _entries[_entries.indexOf(old)] = t;
    return t;
  }

  @override
  Future<QrSnapshot> getQr() async {
    await Future.delayed(_latency);
    return QrSnapshot(
      date: _slotDate,
      block: 'Consultorio 02 · ${_hhmm(_slotStart)}–${_hhmm(_slotEnd)}',
      tickets: List.of(_entries),
    );
  }

  @override
  Future<QrTicket> callNext() async {
    await Future.delayed(_latency);
    if (_entries.any((t) => t.status == TicketStatus.called)) {
      throw const QrException('Ya hay un paciente llamado. Gestiona su turno primero.');
    }
    final next = _entries.where((t) => t.status == TicketStatus.waiting).firstOrNull;
    if (next == null) throw const QrException('No hay pacientes en espera.');
    return _replace(next, TicketStatus.called, calledAt: DateTime.now());
  }

  @override
  Future<QrTicket> startAttention(String id) async {
    await Future.delayed(_latency);
    final t = _find(id);
    if (t.status != TicketStatus.called) {
      throw const QrException('Solo se puede iniciar la atención de un paciente llamado.');
    }
    if (_entries.any((x) => x.status == TicketStatus.inAttention)) {
      throw const QrException('Termina la atención en curso antes de iniciar otra.');
    }
    return _replace(t, TicketStatus.inAttention);
  }

  @override
  Future<QrTicket> markAbsent(String id) async {
    await Future.delayed(_latency);
    final t = _find(id);
    if (t.status == TicketStatus.inAttention || t.status == TicketStatus.attended) {
      throw const QrException('Si ya se inició la atención, no se puede marcar ausencia.');
    }
    if (t.status != TicketStatus.called) {
      throw const QrException('Solo se puede marcar ausente a un paciente llamado.');
    }
    if (!t.deadlineExpired) throw const QrException('Aún no termina el plazo de llegada.');
    _entryAppointment[id]?.status = 'ABSENT';
    return _replace(t, TicketStatus.absent);
  }

  @override
  Future<QrTicket> finishAttention(String id) async {
    await Future.delayed(_latency);
    final t = _find(id);
    if (t.status != TicketStatus.inAttention) {
      throw const QrException('Este paciente no está en atención.');
    }
    _entryAppointment[id]?.status = 'ATTENDED';
    return _replace(t, TicketStatus.attended);
  }

  @override
  Future<ArrivalResult> registerArrival(String code) async {
    await Future.delayed(_latency);
    final key = code.trim().toUpperCase();
    final a = _appointments[key];
    if (a == null) throw const QrException('No existe una reserva con ese código.');
    if (a.status == 'CONFIRMED') throw const QrException('La llegada ya fue registrada.');
    if (a.status != 'RESERVED') throw const QrException('La reserva no está activa.');
    final limit = _slotStart.add(const Duration(minutes: checkInToleranceMinutes));
    if (DateTime.now().isAfter(limit)) {
      throw const QrException('Pasó la tolerancia de llegada para esta reserva.');
    }

    a.status = 'CONFIRMED';
    final position = _entries.length + 1;
    final t = QrTicket(
      id: 'e$position',
      position: position,
      code: 'T-${position.toString().padLeft(3, '0')}',
      patientName: a.patientName,
      arrivedAt: DateTime.now(),
      status: TicketStatus.waiting,
      specialty: _specialty,
      doctor: _doctor,
    );
    _entries.add(t);
    _entryAppointment[t.id] = a;
    return ArrivalResult(
      reservationCode: key,
      patientName: a.patientName,
      arrivedAt: t.arrivedAt,
      specialty: _specialty,
      doctor: _doctor,
      room: 'Consultorio 02',
      ticket: t,
    );
  }
}
