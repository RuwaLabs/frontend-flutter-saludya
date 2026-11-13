import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:saludya/core/design/saludya_palette.dart';
import 'package:saludya/core/utils/iterable_extensions.dart';
import 'package:saludya/features/calendar/presentation/block_details_page.dart';
import 'package:saludya/features/calendar/presentation/block_editor_page.dart';
import 'package:saludya/features/calendar/presentation/monthly_calendar.dart';
import 'package:saludya/features/operations/domain/operations_models.dart';
import 'package:saludya/features/operations/domain/operations_repository.dart';

class CalendarPage extends StatefulWidget {
  final ValueChanged<TimeBlock> onOpenQueue;

  const CalendarPage({super.key, required this.onOpenQueue});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final OperationsRepository _repository =
      GetIt.instance<OperationsRepository>();
  final TextEditingController _searchController = TextEditingController();
  List<Specialty> _specialties = [];
  List<Doctor> _doctors = [];
  List<TimeBlock> _blocks = [];
  List<TimeBlock>? _selectedDayBlocks;
  Specialty? _selectedSpecialty;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();
  int? _doctorFilter;
  bool _loading = true;
  bool _loadingBlocks = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialties() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final specialties = await _repository.getSpecialties();
      if (mounted) {
        setState(() {
          _specialties = specialties;
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

  Future<void> _chooseSpecialty(Specialty specialty) async {
    setState(() {
      _selectedSpecialty = specialty;
      _doctorFilter = null;
      _doctors = [];
      _blocks = [];
      _loadingBlocks = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.getDoctors(specialty.id),
        _repository.getCalendarBlocks(
          specialty.id,
          DateTime(_month.year, _month.month, 1),
          DateTime(_month.year, _month.month + 1, 0),
        ),
        _repository.getCalendarBlocks(
          specialty.id,
          _selectedDate,
          _selectedDate,
        ),
      ]);
      if (mounted) {
        setState(() {
          _doctors = results[0] as List<Doctor>;
          _blocks = results[1] as List<TimeBlock>;
          _selectedDayBlocks = results[2] as List<TimeBlock>;
          _loadingBlocks = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loadingBlocks = false;
        });
      }
    }
  }

  Future<void> _loadMonth() async {
    final specialty = _selectedSpecialty;
    if (specialty == null) return;
    setState(() {
      _loadingBlocks = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.getCalendarBlocks(
          specialty.id,
          DateTime(_month.year, _month.month, 1),
          DateTime(_month.year, _month.month + 1, 0),
        ),
        _repository.getCalendarBlocks(
          specialty.id,
          _selectedDate,
          _selectedDate,
        ),
      ]);
      if (mounted) {
        setState(() {
          _blocks = results[0];
          _selectedDayBlocks = results[1];
          _loadingBlocks = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loadingBlocks = false;
        });
      }
    }
  }

  Future<void> _selectDate(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _doctorFilter = null;
      _selectedDayBlocks = null;
      _loadingBlocks = true;
      _error = null;
    });
    final specialty = _selectedSpecialty;
    if (specialty == null) return;
    try {
      final blocks = await _repository.getCalendarBlocks(
        specialty.id,
        date,
        date,
      );
      if (mounted) {
        setState(() {
          _selectedDayBlocks = blocks;
          _loadingBlocks = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loadingBlocks = false;
        });
      }
    }
  }

  Future<void> _changeMonth(int offset) async {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
      _selectedDate = DateTime(_month.year, _month.month, 1);
      _doctorFilter = null;
    });
    await _loadMonth();
  }

  Future<void> _createBlock() async {
    final specialty = _selectedSpecialty;
    if (specialty == null) return;
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BlockEditorPage(date: _selectedDate, initialSpecialty: specialty),
      ),
    );
    if (created == true) await _loadMonth();
  }

  Future<void> _openDetails(TimeBlock block) async {
    final specialty = _selectedSpecialty;
    if (specialty == null) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BlockDetailsPage(
          block: block,
          specialty: specialty,
          onOpenQueue: widget.onOpenQueue,
        ),
      ),
    );
    await _loadMonth();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: SaludYaPalette.primary),
      );
    }
    if (_error != null && _specialties.isEmpty) {
      return _loadError('No se pudo cargar el catálogo de especialidades.');
    }
    if (_selectedSpecialty == null) return _specialtyChooser();

    final sourceBlocks = _selectedDayBlocks ?? _blocks;
    final dayBlocks =
        sourceBlocks
            .where(
              (block) =>
                  block.date.year == _selectedDate.year &&
                  block.date.month == _selectedDate.month &&
                  block.date.day == _selectedDate.day &&
                  (_doctorFilter == null || block.doctorId == _doctorFilter),
            )
            .toList()
          ..sort((a, b) => a.startHour.compareTo(b.startHour));
    final filteredDoctors = _doctors
        .where(
          (doctor) => doctor.fullName.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ),
        )
        .toList();

    return RefreshIndicator(
      color: SaludYaPalette.primary,
      onRefresh: _loadMonth,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedSpecialty!.name,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.3,
                        color: SaludYaPalette.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _selectedSpecialty = null),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Cambiar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MonthlyCalendar(
            month: _month,
            selectedDate: _selectedDate,
            blocks: _blocks,
            onSelectDate: _selectDate,
            onChangeMonth: _changeMonth,
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _LegendDot(color: SaludYaPalette.primary, label: 'Con bloques'),
              SizedBox(width: 16),
              _LegendDot(color: SaludYaPalette.absent, label: 'Cancelado'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bloques · ${formatSpanishDate(_selectedDate)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: SaludYaPalette.text,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loadMonth,
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar',
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar profesional...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () => setState(() {
                  _searchController.clear();
                  _doctorFilter = null;
                }),
                icon: const Icon(Icons.close),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: SaludYaPalette.border),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          if (_searchController.text.isNotEmpty)
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _doctorFilter == null,
                  onSelected: (_) => setState(() => _doctorFilter = null),
                ),
                ...filteredDoctors.map(
                  (doctor) => ChoiceChip(
                    label: Text(doctor.fullName),
                    selected: _doctorFilter == doctor.id,
                    onSelected: (_) =>
                        setState(() => _doctorFilter = doctor.id),
                  ),
                ),
              ],
            ),
          if (_loadingBlocks)
            const LinearProgressIndicator(color: SaludYaPalette.primary),
          if (_error != null)
            _inlineError(
              'No se pudieron cargar los bloques: $_error',
              _loadMonth,
            ),
          if (!_loadingBlocks && dayBlocks.isEmpty)
            SaludYaCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.event_busy_outlined,
                    color: SaludYaPalette.secondaryText,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No hay bloques para esta fecha y especialidad.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _createBlock,
                    icon: const Icon(Icons.add),
                    label: const Text('Crear bloque'),
                  ),
                ],
              ),
            ),
          ...dayBlocks.map(
            (block) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BlockCard(
                block: block,
                doctor: _doctors
                    .where((doctor) => doctor.id == block.doctorId)
                    .firstOrNull,
                onTap: () => _openDetails(block),
              ),
            ),
          ),
          if (dayBlocks.isNotEmpty)
            FilledButton.icon(
              onPressed: _createBlock,
              icon: const Icon(Icons.add),
              label: const Text('Crear bloque'),
              style: FilledButton.styleFrom(
                backgroundColor: SaludYaPalette.primary,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
        ],
      ),
    );
  }

  Widget _specialtyChooser() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    children: [
      const Text(
        'Selecciona una especialidad para consultar su disponibilidad.',
        style: TextStyle(color: SaludYaPalette.secondaryText),
      ),
      const SizedBox(height: 16),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _specialties.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.08,
        ),
        itemBuilder: (context, index) {
          final specialty = _specialties[index];
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _chooseSpecialty(specialty),
              child: SaludYaCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: SaludYaPalette.selected,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        size: 18,
                        color: SaludYaPalette.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      specialty.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: SaludYaPalette.text,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Ver disponibilidad',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SaludYaPalette.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ],
  );

  Widget _loadError(String title) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          const SizedBox(height: 8),
          Text('$_error'),
          TextButton.icon(
            onPressed: _loadSpecialties,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );

  Widget _inlineError(String text, VoidCallback retry) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: SaludYaPalette.absent),
          ),
        ),
        IconButton(onPressed: retry, icon: const Icon(Icons.refresh)),
      ],
    ),
  );
}

class _BlockCard extends StatelessWidget {
  final TimeBlock block;
  final Doctor? doctor;
  final VoidCallback onTap;

  const _BlockCard({
    required this.block,
    required this.doctor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: SaludYaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${block.startHour}–${block.endHour}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: SaludYaPalette.text,
                  ),
                ),
              ),
              _StatusPill(status: block.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${doctor?.fullName ?? 'Profesional #${block.doctorId}'} · ${block.room}',
            style: const TextStyle(color: SaludYaPalette.secondaryText),
          ),
          const SizedBox(height: 4),
          Text(
            '${block.currentBookings} reservas · Capacidad ${block.maxCapacity}',
            style: const TextStyle(
              fontSize: 12,
              color: SaludYaPalette.secondaryText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ver detalle →',
            style: TextStyle(
              color: SaludYaPalette.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'CANCELLED' => SaludYaPalette.absent,
      'FULL' => SaludYaPalette.warning,
      _ => SaludYaPalette.primary,
    };
    final label = switch (status) {
      'AVAILABLE' => 'Activo',
      'CANCELLED' => 'Cancelado',
      'FULL' => 'Completo',
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: SaludYaPalette.secondaryText,
        ),
      ),
    ],
  );
}
