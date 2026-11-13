import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:saludya/core/design/saludya_palette.dart';
import 'package:saludya/features/operations/domain/operations_models.dart';
import 'package:saludya/features/operations/domain/operations_repository.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenAttendance;
  final VoidCallback onOpenCancelled;

  const HomePage({
    super.key,
    required this.onOpenCalendar,
    required this.onOpenAttendance,
    required this.onOpenCancelled,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final OperationsRepository _repository =
      GetIt.instance<OperationsRepository>();
  DashboardMetrics? _metrics;
  Object? _error;
  bool _loading = true;

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
      final metrics = await _repository.getDashboard(DateTime.now());
      if (mounted) setState(() => _metrics = metrics);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    color: SaludYaPalette.primary,
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text(
          'Hola, equipo de admisión',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: SaludYaPalette.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Resumen del ${formatSpanishDate(DateTime.now())}',
          style: const TextStyle(color: SaludYaPalette.secondaryText),
        ),
        const SizedBox(height: 20),
        if (_loading && _metrics == null)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(color: SaludYaPalette.primary),
            ),
          )
        else if (_error != null && _metrics == null)
          SaludYaCard(
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  color: SaludYaPalette.secondaryText,
                  size: 36,
                ),
                const SizedBox(height: 8),
                const Text(
                  'No se pudo cargar el resumen del día.',
                  style: TextStyle(color: SaludYaPalette.text),
                ),
                Text(
                  '$_error',
                  style: const TextStyle(color: SaludYaPalette.secondaryText),
                  textAlign: TextAlign.center,
                ),
                TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          )
        else if (_metrics != null) ...[
          SaludYaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Citas de hoy',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: SaludYaPalette.text,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricValue(
                        label: 'Programadas',
                        value: _metrics!.scheduled,
                        icon: Icons.event_available_outlined,
                      ),
                    ),
                    Expanded(
                      child: _MetricValue(
                        label: 'Pendientes',
                        value: _metrics!.pending,
                        icon: Icons.hourglass_bottom_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricValue(
                        label: 'Atendidas',
                        value: _metrics!.attended,
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                    Expanded(
                      child: _MetricValue(
                        label: 'Ausentes',
                        value: _metrics!.absent,
                        icon: Icons.person_off_outlined,
                      ),
                    ),
                  ],
                ),
                if (_metrics!.cancelled > 0) ...[
                  const Divider(height: 24),
                  TextButton.icon(
                    onPressed: widget.onOpenCancelled,
                    icon: const Icon(Icons.event_busy_outlined),
                    label: Text(
                      '${_metrics!.cancelled} citas canceladas · Ver detalle',
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              'No se pudo actualizar: $_error',
              style: const TextStyle(color: SaludYaPalette.warning),
            ),
          ],
        ],
        const SizedBox(height: 20),
        const Text(
          'Accesos rápidos',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: SaludYaPalette.text,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: widget.onOpenCalendar,
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Abrir calendario operativo'),
          style: FilledButton.styleFrom(
            backgroundColor: SaludYaPalette.primary,
            minimumSize: const Size.fromHeight(50),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: widget.onOpenAttendance,
          icon: const Icon(Icons.people_alt_outlined),
          label: const Text('Registrar llegada / abrir cola'),
          style: OutlinedButton.styleFrom(
            foregroundColor: SaludYaPalette.primary,
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ],
    ),
  );
}

class _MetricValue extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _MetricValue({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: SaludYaPalette.primary, size: 20),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: SaludYaPalette.primary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: SaludYaPalette.secondaryText,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
