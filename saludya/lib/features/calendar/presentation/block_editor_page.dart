import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:saludya/core/design/saludya_palette.dart';
import 'package:saludya/core/utils/iterable_extensions.dart';
import 'package:saludya/features/operations/domain/operations_models.dart';
import 'package:saludya/features/operations/domain/operations_repository.dart';
import 'package:saludya/features/settings/application/get_establishment_settings_use_case.dart';

class BlockEditorPage extends StatefulWidget {
  final DateTime date;
  final Specialty? initialSpecialty;
  final TimeBlock? block;

  const BlockEditorPage({
    super.key,
    required this.date,
    this.initialSpecialty,
    this.block,
  });

  @override
  State<BlockEditorPage> createState() => _BlockEditorPageState();
}

class _BlockEditorPageState extends State<BlockEditorPage> {
  final OperationsRepository _repository =
      GetIt.instance<OperationsRepository>();
  final _formKey = GlobalKey<FormState>();
  final _roomController = TextEditingController();
  final _capacityController = TextEditingController();
  List<Specialty> _specialties = [];
  List<Doctor> _doctors = [];
  Specialty? _specialty;
  int? _doctorId;
  late DateTime _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  int? _intervalDurationMinutes;
  String _status = 'AVAILABLE';
  bool _loading = true;
  bool _saving = false;
  Object? _error;

  bool get _editing => widget.block != null;

  @override
  void initState() {
    super.initState();
    _date = widget.block?.date ?? widget.date;
    _start = widget.block == null ? null : _parseTime(widget.block!.startHour);
    _end = widget.block == null ? null : _parseTime(widget.block!.endHour);
    _status = widget.block?.status ?? 'AVAILABLE';
    _roomController.text = widget.block?.room ?? '';
    _capacityController.text = widget.block == null
        ? ''
        : '${widget.block!.maxCapacity}';
    _load();
  }

  @override
  void dispose() {
    _roomController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    try {
      if (!_editing) {
        try {
          _intervalDurationMinutes =
              (await GetIt.instance<GetEstablishmentSettingsUseCase>()
                      .execute())
                  .intervalDurationMinutes;
        } catch (_) {
          _intervalDurationMinutes = null;
        }
      }
      final specialties = await _repository.getSpecialties();
      if (!mounted) return;
      setState(() => _specialties = specialties);

      if (_editing) {
        final doctorOptions = await Future.wait(
          specialties.map((specialty) => _repository.getDoctors(specialty.id)),
        );
        final doctors = doctorOptions.expand((items) => items).toList();
        final currentDoctor = doctors
            .where((doctor) => doctor.id == widget.block!.doctorId)
            .firstOrNull;
        if (mounted) {
          setState(() {
            _doctors = doctors;
            _doctorId = widget.block!.doctorId;
            _specialty = currentDoctor == null
                ? widget.initialSpecialty
                : specialties
                      .where((item) => item.id == currentDoctor.specialtyId)
                      .firstOrNull;
            _loading = false;
          });
        }
      } else {
        final specialty =
            widget.initialSpecialty ??
            (specialties.isEmpty ? null : specialties.first);
        final doctors = specialty == null
            ? <Doctor>[]
            : await _repository.getDoctors(specialty.id);
        if (mounted) {
          setState(() {
            _specialty = specialty;
            _doctors = doctors;
            _doctorId = doctors.isEmpty ? null : doctors.first.id;
            _loading = false;
          });
        }
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

  Future<void> _selectSpecialty(int? id) async {
    final selected = _specialties.where((item) => item.id == id).firstOrNull;
    if (selected == null) return;
    setState(() {
      _specialty = selected;
      _doctors = [];
      _doctorId = null;
      _loading = true;
    });
    try {
      final doctors = await _repository.getDoctors(selected.id);
      if (mounted) {
        setState(() {
          _doctors = doctors;
          _doctorId = doctors.isEmpty ? null : doctors.first.id;
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

  Future<void> _pickTime({required bool start}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: (start ? _start : _end) ?? TimeOfDay.now(),
      helpText: start ? 'Hora de inicio' : 'Hora de fin',
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (start) {
        _start = selected;
        if (_end == null && _intervalDurationMinutes != null) {
          final end = DateTime(
            2000,
            1,
            1,
            selected.hour,
            selected.minute,
          ).add(Duration(minutes: _intervalDurationMinutes!));
          if (end.day == 1) {
            _end = TimeOfDay(hour: end.hour, minute: end.minute);
          }
        }
      } else {
        _end = selected;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final doctorId = _doctorId;
    final specialty = _specialty;
    final capacity = int.tryParse(_capacityController.text);
    if (specialty == null || doctorId == null || capacity == null) return;
    final startTime = _start;
    final endTime = _end;
    if (startTime == null || endTime == null) {
      _showError('Selecciona la hora de inicio y de fin.');
      return;
    }
    final start = _formatTime(startTime);
    final end = _formatTime(endTime);
    if (end.compareTo(start) <= 0) {
      _showError('La hora de fin debe ser posterior a la hora de inicio.');
      return;
    }
    setState(() => _saving = true);
    try {
      if (_editing) {
        await _repository.updateTimeBlock(
          widget.block!.id,
          BlockChanges(
            doctorId: doctorId,
            startHour: start,
            endHour: end,
            status: _status,
            maxCapacity: capacity,
          ),
        );
      } else {
        await _repository.createTimeBlock(
          BlockDraft(
            doctorId: doctorId,
            date: _date,
            startHour: start,
            endHour: end,
            room: _roomController.text.trim(),
            maxCapacity: capacity,
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showError('$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No se pudo guardar'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SaludYaPalette.background,
    appBar: AppBar(
      title: Text(_editing ? 'Editar bloque' : 'Crear bloque'),
      backgroundColor: SaludYaPalette.background,
      foregroundColor: SaludYaPalette.text,
    ),
    body: _loading
        ? const Center(
            child: CircularProgressIndicator(color: SaludYaPalette.primary),
          )
        : _error != null
        ? Center(child: Text('No se pudieron cargar los datos: $_error'))
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Text(
                  'Fecha del bloque',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                SaludYaCard(child: Text(formatSpanishDate(_date))),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _specialty?.id,
                  decoration: const InputDecoration(
                    labelText: 'Especialidad',
                    border: OutlineInputBorder(),
                  ),
                  items: _specialties
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: _saving ? null : _selectSpecialty,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _doctorId,
                  decoration: const InputDecoration(
                    labelText: 'Profesional',
                    border: OutlineInputBorder(),
                  ),
                  items: _doctors
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.fullName),
                        ),
                      )
                      .toList(),
                  validator: (value) =>
                      value == null ? 'Selecciona un profesional.' : null,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _doctorId = value),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _timeButton(
                        'Inicio',
                        _start,
                        () => _pickTime(start: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _timeButton(
                        'Fin',
                        _end,
                        () => _pickTime(start: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _roomController,
                  enabled: !_saving && !_editing,
                  decoration: const InputDecoration(
                    labelText: 'Consultorio',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      !_editing && (value == null || value.trim().isEmpty)
                      ? 'Indica el consultorio.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _capacityController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Capacidad máxima',
                    suffixText: 'pacientes',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final capacity = int.tryParse(value ?? '');
                    if (capacity == null || capacity <= 0) {
                      return 'La capacidad debe ser mayor que cero.';
                    }
                    if (_editing && capacity < widget.block!.currentBookings) {
                      return 'No puede ser menor que las reservas existentes (${widget.block!.currentBookings}).';
                    }
                    if (_editing &&
                        _status == 'AVAILABLE' &&
                        capacity == widget.block!.currentBookings) {
                      return 'Un bloque sin cupos debe permanecer completo.';
                    }
                    if (_editing &&
                        _status == 'FULL' &&
                        capacity > widget.block!.currentBookings) {
                      return 'El estado completo requiere que todas las plazas estén ocupadas.';
                    }
                    return null;
                  },
                ),
                if (_editing) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        [
                              'AVAILABLE',
                              if (_status == 'FULL') 'FULL',
                              'CANCELLED',
                            ]
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(_statusName(status)),
                              ),
                            )
                            .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _status = value ?? _status),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Reservas registradas: ${widget.block!.currentBookings}',
                    style: const TextStyle(color: SaludYaPalette.secondaryText),
                  ),
                ],
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _saving || _doctors.isEmpty ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: SaludYaPalette.primary,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_editing ? 'Guardar cambios' : 'Crear bloque'),
                ),
              ],
            ),
          ),
  );

  Widget _timeButton(String label, TimeOfDay? value, VoidCallback onPressed) =>
      OutlinedButton(
        onPressed: _saving ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: SaludYaPalette.primary,
        ),
        child: Text(
          '$label · ${value == null ? 'Elegir hora' : _formatTime(value)}',
        ),
      );

  String _statusName(String status) => switch (status) {
    'AVAILABLE' => 'Activo',
    'FULL' => 'Completo',
    'CANCELLED' => 'Cancelado',
    _ => status,
  };
}
