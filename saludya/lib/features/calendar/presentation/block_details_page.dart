import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:saludya/core/design/saludya_palette.dart';
import 'package:saludya/core/utils/iterable_extensions.dart';
import 'package:saludya/features/calendar/presentation/block_editor_page.dart';
import 'package:saludya/features/operations/domain/operations_models.dart';
import 'package:saludya/features/operations/domain/operations_repository.dart';

class BlockDetailsPage extends StatefulWidget {
  final TimeBlock block;
  final Specialty specialty;
  final ValueChanged<TimeBlock> onOpenQueue;

  const BlockDetailsPage({
    super.key,
    required this.block,
    required this.specialty,
    required this.onOpenQueue,
  });

  @override
  State<BlockDetailsPage> createState() => _BlockDetailsPageState();
}

class _BlockDetailsPageState extends State<BlockDetailsPage> {
  final OperationsRepository _repository =
      GetIt.instance<OperationsRepository>();
  late TimeBlock _block = widget.block;
  Doctor? _doctor;
  List<BookedPatient> _appointments = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.getTimeBlock(_block.id),
        _repository.getDoctors(widget.specialty.id),
        _repository.getAppointmentsForBlock(_block.id),
      ]);
      final block = results[0] as TimeBlock;
      final doctors = results[1] as List<Doctor>;
      final patients = results[2] as List<BookedPatient>;
      if (mounted) {
        setState(() {
          _block = block;
          _doctor = doctors
              .where((doctor) => doctor.id == block.doctorId)
              .firstOrNull;
          _appointments = patients;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlockEditorPage(
          date: _block.date,
          initialSpecialty: widget.specialty,
          block: _block,
        ),
      ),
    );
    if (changed == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SaludYaPalette.background,
    appBar: AppBar(
      title: const Text('Detalle del bloque'),
      backgroundColor: SaludYaPalette.background,
      foregroundColor: SaludYaPalette.text,
      actions: [
        IconButton(
          onPressed: _load,
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _loading
        ? const Center(
            child: CircularProgressIndicator(color: SaludYaPalette.primary),
          )
        : _error != null
        ? Center(child: Text('No se pudo cargar el bloque: $_error'))
        : ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              SaludYaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_block.startHour}–${_block.endHour}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: SaludYaPalette.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.specialty.name,
                      style: const TextStyle(
                        color: SaludYaPalette.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _doctor?.fullName ?? 'Profesional #${_block.doctorId}',
                      style: const TextStyle(color: SaludYaPalette.text),
                    ),
                    Text(
                      _block.room.isEmpty
                          ? 'Consultorio no especificado'
                          : _block.room,
                      style: const TextStyle(
                        color: SaludYaPalette.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(label: '${_block.currentBookings} reservas'),
                        _InfoChip(label: 'Capacidad ${_block.maxCapacity}'),
                        _InfoChip(label: _statusName(_block.status)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pacientes con reserva',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: SaludYaPalette.text,
                ),
              ),
              const SizedBox(height: 8),
              if (_appointments.isEmpty)
                const SaludYaCard(
                  child: Text('Este bloque todavía no tiene reservas.'),
                )
              else
                ..._appointments.map(
                  (appointment) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SaludYaCard(
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: SaludYaPalette.selected,
                            child: Icon(
                              Icons.person_outline,
                              color: SaludYaPalette.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appointment.patientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: SaludYaPalette.text,
                                  ),
                                ),
                                Text(
                                  appointment.bookingCode,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: SaludYaPalette.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _appointmentStatus(appointment.status),
                            style: const TextStyle(
                              fontSize: 12,
                              color: SaludYaPalette.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _edit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar bloque'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SaludYaPalette.primary,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onOpenQueue(_block);
                },
                icon: const Icon(Icons.people_alt_outlined),
                label: const Text('Ver cola presencial'),
                style: FilledButton.styleFrom(
                  backgroundColor: SaludYaPalette.primary,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
  );

  String _statusName(String status) => switch (status) {
    'AVAILABLE' => 'Activo',
    'FULL' => 'Completo',
    'CANCELLED' => 'Cancelado',
    _ => status,
  };

  String _appointmentStatus(String status) => switch (status) {
    'RESERVED' => 'Pendiente',
    'CONFIRMED' => 'Confirmada',
    'CANCELLED' => 'Cancelada',
    'ABSENT' => 'Ausente',
    'ATTENDED' => 'Atendida',
    _ => status,
  };
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: SaludYaPalette.selected,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 12, color: SaludYaPalette.primaryDark),
    ),
  );
}
