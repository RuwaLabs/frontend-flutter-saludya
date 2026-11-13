import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:saludya/core/design/saludya_palette.dart';
import 'package:saludya/features/operations/domain/operations_models.dart';
import 'package:saludya/features/operations/domain/operations_repository.dart';
import 'package:saludya/features/settings/application/get_establishment_settings_use_case.dart';

class AttendancePage extends StatefulWidget {
  final TimeBlock? initialBlock;
  final bool active;
  final bool initialCancelled;

  const AttendancePage({
    super.key,
    this.initialBlock,
    this.active = true,
    this.initialCancelled = false,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final OperationsRepository _repository =
      GetIt.instance<OperationsRepository>();
  List<TimeBlock> _blocks = [];
  List<QueueEntry> _entries = [];
  List<BookedPatient> _cancelled = [];
  TimeBlock? _selectedBlock;
  AttendanceQueue? _queue;
  DateTime _date = DateTime.now();
  Timer? _refreshTimer;
  int? _postCallToleranceMinutes;
  bool _loading = true;
  bool _loadingQueue = false;
  bool _saving = false;
  late bool _showCancelled = widget.initialCancelled;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _date = widget.initialBlock?.date ?? DateTime.now();
    _selectedBlock = widget.initialBlock;
    _load();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant AttendancePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _syncTimer();
    if (oldWidget.initialCancelled != widget.initialCancelled &&
        widget.initialCancelled) {
      _showCancelled = true;
      _loadCancelled();
    }
    if (oldWidget.initialBlock?.id != widget.initialBlock?.id &&
        widget.initialBlock != null) {
      _date = widget.initialBlock!.date;
      _selectedBlock = widget.initialBlock;
      _showCancelled = false;
      _load();
    }
  }

  void _syncTimer() {
    _refreshTimer?.cancel();
    if (!widget.active || _selectedBlock == null || _showCancelled) return;
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadQueue(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      try {
        final settings = await GetIt.instance<GetEstablishmentSettingsUseCase>()
            .execute();
        _postCallToleranceMinutes = settings.postCallToleranceMinutes;
      } catch (_) {
        // Queue operations remain usable; the server remains authoritative for timeout transitions.
        _postCallToleranceMinutes = null;
      }
      final specialties = await _repository.getSpecialties();
      final blocksPerSpecialty = await Future.wait(
        specialties.map(
          (specialty) =>
              _repository.getCalendarBlocks(specialty.id, _date, _date),
        ),
      );
      final blocks = blocksPerSpecialty.expand((items) => items).toList()
        ..sort((a, b) => a.startHour.compareTo(b.startHour));
      if (!mounted) return;
      setState(() {
        _blocks = blocks;
        _selectedBlock = _blocks
            .where((block) => block.id == _selectedBlock?.id)
            .firstOrNull;
        _loading = false;
      });
      if (_showCancelled) {
        await _loadCancelled();
      } else {
        await _loadQueue(silent: true);
      }
      _syncTimer();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  Future<void> _selectBlock(TimeBlock? block) async {
    setState(() {
      _selectedBlock = block;
      _queue = null;
      _entries = [];
      _showCancelled = false;
    });
    await _loadQueue();
    _syncTimer();
  }

  Future<void> _loadQueue({bool silent = false}) async {
    final block = _selectedBlock;
    if (block == null || _showCancelled) return;
    if (!silent && mounted) {
      setState(() {
        _loadingQueue = true;
        _error = null;
      });
    }
    try {
      final queue = await _repository.getAttendanceQueue(block.id, _date);
      final entries = queue == null
          ? <QueueEntry>[]
          : await _repository.getQueueEntries(queue.id);
      if (mounted) {
        setState(() {
          _queue = queue;
          _entries = entries;
          _loadingQueue = false;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loadingQueue = false;
        });
      }
    }
  }

  Future<void> _loadCancelled() async {
    setState(() {
      _showCancelled = true;
      _loadingQueue = true;
      _error = null;
    });
    _refreshTimer?.cancel();
    try {
      final cancelled = await _repository.getCancelledAppointments(_date);
      if (mounted) {
        setState(() {
          _cancelled = cancelled;
          _loadingQueue = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loadingQueue = false;
        });
      }
    }
  }

  Future<void> _showArrivalDialog() async {
    final block = _selectedBlock;
    if (block == null || _saving) return;
    final bookingCode = await showDialog<String>(
      context: context,
      builder: (_) => const _ManualArrivalDialog(),
    );
    if (bookingCode == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final receipt = await _repository.registerArrival(bookingCode);
      await _loadQueue(silent: true);
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(
              Icons.check_circle_outline,
              color: SaludYaPalette.primary,
              size: 38,
            ),
            title: const Text('Llegada confirmada'),
            content: Text(
              'Código: ${bookingCode.toUpperCase()}\nPosición en la cola: ${receipt.position} de ${receipt.totalInQueue}.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: FilledButton.styleFrom(
                  backgroundColor: SaludYaPalette.primary,
                ),
                child: const Text('Ver cola'),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      _showError('No se pudo registrar la llegada: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _callNext() async {
    final queue = _queue;
    if (queue == null || queue.status != 'OPEN' || _saving || _hasActiveTurn) {
      return;
    }
    setState(() => _saving = true);
    try {
      await _repository.callNext(queue.id);
      await _loadQueue(silent: true);
    } catch (error) {
      _showError('No se pudo llamar al siguiente paciente: $error');
      await _loadQueue(silent: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _startAttention(QueueEntry entry) => _runQueueAction(
    entry,
    action: () => _repository.startAttention(entry.id),
    success: 'Atención iniciada.',
  );

  Future<void> _finishAttention(QueueEntry entry) => _runQueueAction(
    entry,
    action: () => _repository.finishAttention(entry.id),
    success: 'Atención finalizada. Llama al siguiente cuando estés listo.',
  );

  Future<void> _markAbsent(QueueEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Marcar paciente como ausente?'),
        content: Text('${entry.patientName} · ${entry.bookingCode}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: SaludYaPalette.absent,
            ),
            child: const Text('Confirmar ausencia'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _runQueueAction(
        entry,
        action: () => _repository.markAbsent(entry.id),
        success: 'Ausencia registrada. Llama al siguiente manualmente.',
      );
    }
  }

  Future<void> _runQueueAction(
    QueueEntry entry, {
    required Future<void> Function() action,
    required String success,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
      await _loadQueue(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (error) {
      _showError('$error');
      await _loadQueue(silent: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _hasActiveTurn => _entries.any(
    (entry) => entry.status == 'CALLED' || entry.status == 'IN_ATTENTION',
  );
  bool get _hasWaiting => _entries.any((entry) => entry.status == 'WAITING');
  QueueEntry? get _currentTurn => _entries
      .where(
        (entry) => entry.status == 'CALLED' || entry.status == 'IN_ATTENTION',
      )
      .firstOrNull;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: SaludYaPalette.primary),
      );
    }
    if (_error != null && _blocks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se pudieron cargar los bloques de hoy.'),
              Text(
                '$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: SaludYaPalette.secondaryText),
              ),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: SaludYaPalette.primary,
      onRefresh: _showCancelled ? _loadCancelled : _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text(
            'Citas y atención',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: SaludYaPalette.text,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Cola presencial'),
                icon: Icon(Icons.people_alt_outlined),
              ),
              ButtonSegment(
                value: true,
                label: Text('Canceladas'),
                icon: Icon(Icons.event_busy_outlined),
              ),
            ],
            selected: {_showCancelled},
            onSelectionChanged: (values) {
              if (values.first) {
                _loadCancelled();
              } else {
                setState(() => _showCancelled = false);
                _loadQueue();
                _syncTimer();
              }
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(formatSpanishDate(_date)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SaludYaPalette.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showCancelled ? _loadCancelled : _load,
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar',
              ),
            ],
          ),
          if (!_showCancelled)
            ..._buildQueueContent()
          else
            ..._buildCancelledContent(),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _date = selected;
      _selectedBlock = null;
      _queue = null;
      _entries = [];
    });
    await _load();
  }

  List<Widget> _buildQueueContent() {
    final block = _selectedBlock;
    if (block == null) {
      return [
        DropdownButtonFormField<int>(
          initialValue: null,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Selecciona un bloque',
            border: OutlineInputBorder(),
          ),
          items: _blocks
              .map(
                (item) => DropdownMenuItem(
                  value: item.id,
                  child: Text(
                    '${item.startHour}–${item.endHour} · ${item.room}',
                  ),
                ),
              )
              .toList(),
          onChanged: (id) {
            final selected = _blocks.where((item) => item.id == id).firstOrNull;
            if (selected != null) _selectBlock(selected);
          },
        ),
        const SizedBox(height: 16),
        if (_blocks.isEmpty)
          const SaludYaCard(
            child: Text(
              'No hay bloques de atención para esta fecha. Selecciona otra fecha o crea el bloque desde Calendario.',
            ),
          ),
      ];
    }

    final current = _currentTurn;
    return [
      DropdownButtonFormField<int>(
        initialValue: block.id,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Bloque seleccionado',
          border: OutlineInputBorder(),
        ),
        items: _blocks
            .map(
              (item) => DropdownMenuItem(
                value: item.id,
                child: Text('${item.startHour}–${item.endHour} · ${item.room}'),
              ),
            )
            .toList(),
        onChanged: (id) {
          final selected = _blocks.where((item) => item.id == id).firstOrNull;
          if (selected != null) _selectBlock(selected);
        },
      ),
      const SizedBox(height: 12),
      SaludYaCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.medical_services_outlined,
              color: SaludYaPalette.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${block.room} · ${block.startHour}–${block.endHour}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: SaludYaPalette.text,
                ),
              ),
            ),
            _QueueStatusPill(status: _queue?.status ?? 'EMPTY'),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (_loadingQueue)
        const LinearProgressIndicator(color: SaludYaPalette.primary),
      if (_error != null)
        Text(
          'No se pudo actualizar la cola: $_error',
          style: const TextStyle(color: SaludYaPalette.absent),
        ),
      if (current != null) _currentTurnCard(current),
      if (_queue?.status == 'CLOSED')
        const SaludYaCard(
          child: Text(
            'La ventana de llegada terminó y la cola está cerrada. Las reservas pendientes quedaron marcadas como ausentes.',
          ),
        )
      else if (_queue == null || _entries.isEmpty)
        SaludYaCard(
          child: Column(
            children: [
              const Icon(
                Icons.people_outline,
                color: SaludYaPalette.primary,
                size: 34,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sin pacientes en espera',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _saving ? null : _showArrivalDialog,
                icon: const Icon(Icons.password),
                label: const Text('Registrar llegada por código'),
                style: FilledButton.styleFrom(
                  backgroundColor: SaludYaPalette.primary,
                ),
              ),
            ],
          ),
        )
      else ...[
        Row(
          children: [
            const Expanded(
              child: Text(
                'Cola de atención',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: SaludYaPalette.text,
                ),
              ),
            ),
            Text(
              '${_entries.where((e) => e.status == 'WAITING').length} en espera',
              style: const TextStyle(
                fontSize: 12,
                color: SaludYaPalette.secondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._entries.map(_queueEntryCard),
      ],
      if (_queue?.status != 'CLOSED') ...[
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _saving || _queue == null || _hasActiveTurn || !_hasWaiting
              ? null
              : _callNext,
          icon: const Icon(Icons.campaign_outlined),
          label: const Text('Llamar al siguiente'),
          style: FilledButton.styleFrom(
            backgroundColor: SaludYaPalette.primary,
            minimumSize: const Size.fromHeight(50),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _saving ? null : _showArrivalDialog,
          icon: const Icon(Icons.password),
          label: const Text('Registrar llegada por código'),
          style: OutlinedButton.styleFrom(
            foregroundColor: SaludYaPalette.primary,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'El siguiente turno no se llama automáticamente; confirma cada acción desde esta pantalla.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: SaludYaPalette.secondaryText),
        ),
      ],
    ];
  }

  Widget _currentTurnCard(QueueEntry entry) {
    final inAttention = entry.status == 'IN_ATTENTION';
    final timedOut =
        _postCallToleranceMinutes != null &&
        entry.calledAt != null &&
        DateTime.now().isAfter(
          entry.calledAt!.add(Duration(minutes: _postCallToleranceMinutes!)),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SaludYaPalette.primary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              inAttention
                  ? 'EN ATENCIÓN'
                  : timedOut
                  ? 'PLAZO AGOTADO · AUSENCIA AUTOMÁTICA PENDIENTE'
                  : 'PACIENTE LLAMADO',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'N.º ${entry.position} · ${entry.patientName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              entry.bookingCode,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            if (entry.status == 'CALLED') ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _saving ? null : () => _startAttention(entry),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar atención'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => _markAbsent(entry),
                      icon: const Icon(Icons.person_off_outlined),
                      label: const Text('Marcar ausente'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (entry.status == 'IN_ATTENTION')
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _saving ? null : () => _finishAttention(entry),
                  icon: const Icon(Icons.check),
                  label: const Text('Finalizar atención'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _queueEntryCard(QueueEntry entry) {
    final isCurrent =
        entry.status == 'CALLED' || entry.status == 'IN_ATTENTION';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SaludYaCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isCurrent
                  ? SaludYaPalette.selected
                  : const Color(0xFFF1F5F4),
              child: Text(
                '${entry.position}',
                style: const TextStyle(
                  color: SaludYaPalette.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.patientName} · ${entry.bookingCode}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: SaludYaPalette.text,
                    ),
                  ),
                  Text(
                    _entryStatus(entry.status),
                    style: TextStyle(
                      fontSize: 12,
                      color: entry.status == 'ABSENT'
                          ? SaludYaPalette.absent
                          : SaludYaPalette.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (entry.status == 'CALLED')
              IconButton(
                tooltip: 'Marcar ausente',
                onPressed: _saving ? null : () => _markAbsent(entry),
                icon: const Icon(
                  Icons.person_off_outlined,
                  color: SaludYaPalette.absent,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCancelledContent() {
    if (_loadingQueue) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: CircularProgressIndicator(color: SaludYaPalette.primary),
          ),
        ),
      ];
    }
    if (_error != null) {
      return [
        SaludYaCard(
          child: Text('No se pudieron cargar las cancelaciones: $_error'),
        ),
      ];
    }
    if (_cancelled.isEmpty) {
      return [
        const SaludYaCard(
          child: Text('No hay citas canceladas en esta fecha.'),
        ),
      ];
    }
    return [
      const Text(
        'Citas canceladas',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: SaludYaPalette.text,
        ),
      ),
      const SizedBox(height: 8),
      ..._cancelled.map(
        (appointment) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SaludYaCard(
            child: Row(
              children: [
                const Icon(
                  Icons.event_busy_outlined,
                  color: SaludYaPalette.secondaryText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (appointment.slotSummary != null)
                        Text(
                          appointment.slotSummary!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: SaludYaPalette.secondaryText,
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
                const Text(
                  'Cancelada',
                  style: TextStyle(
                    color: SaludYaPalette.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  String _entryStatus(String status) => switch (status) {
    'WAITING' => 'En espera',
    'CALLED' => 'Llamado',
    'IN_ATTENTION' => 'En atención',
    'ATTENDED' => 'Atendido',
    'ABSENT' => 'Ausente',
    _ => status,
  };
}

class _QueueStatusPill extends StatelessWidget {
  final String status;
  const _QueueStatusPill({required this.status});

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(
      status == 'OPEN'
          ? 'Abierta'
          : status == 'CLOSED'
          ? 'Cerrada'
          : 'Sin iniciar',
    ),
    backgroundColor: status == 'CLOSED'
        ? const Color(0xFFE9ECEB)
        : SaludYaPalette.selected,
    labelStyle: const TextStyle(
      fontSize: 11,
      color: SaludYaPalette.primaryDark,
    ),
    visualDensity: VisualDensity.compact,
  );
}

class _ManualArrivalDialog extends StatefulWidget {
  const _ManualArrivalDialog();

  @override
  State<_ManualArrivalDialog> createState() => _ManualArrivalDialogState();
}

class _ManualArrivalDialogState extends State<_ManualArrivalDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Registrar llegada'),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        maxLength: 14,
        decoration: const InputDecoration(
          labelText: 'Código de reserva',
          hintText: 'SAL-XXXXXXXXXX',
        ),
        validator: (value) => value == null || value.trim().length < 6
            ? 'Ingresa el código de la reserva.'
            : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            Navigator.pop(context, _controller.text.trim());
          }
        },
        child: const Text('Validar código'),
      ),
    ],
  );
}
