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
          'Admisión · Centro de Salud',
          style: const TextStyle(color: SaludYaPalette.secondaryText),
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
          _SummaryCard(
            title: 'Citas pendientes',
            lines: [
              '${_metrics!.pending} ${_metrics!.pending == 1 ? 'reserva' : 'reservas'} para hoy',
              '${_metrics!.scheduled} citas programadas',
            ],
            action: 'Ver calendario →',
            onTap: widget.onOpenCalendar,
          ),
          _SummaryCard(
            title: 'Citas canceladas',
            lines: [
              '${_metrics!.cancelled} ${_metrics!.cancelled == 1 ? 'cancelación' : 'cancelaciones'} de hoy',
            ],
            action: 'Ver detalle →',
            onTap: widget.onOpenCancelled,
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
        FilledButton.icon(
          onPressed: widget.onOpenAttendance,
          icon: const Icon(Icons.qr_code_scanner_outlined),
          label: const Text('Registrar llegada'),
          style: FilledButton.styleFrom(
            backgroundColor: SaludYaPalette.primary,
            minimumSize: const Size.fromHeight(50),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: widget.onOpenAttendance,
          icon: const Icon(Icons.people_alt_outlined),
          label: const Text('Ver cola de atención'),
          style: OutlinedButton.styleFrom(
            foregroundColor: SaludYaPalette.primary,
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ],
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  final String action;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title,
    required this.lines,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: SaludYaPalette.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: SaludYaPalette.text,
                ),
              ),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    line,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: SaludYaPalette.secondaryText,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                action,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SaludYaPalette.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
